package ninja_emit

import "../ninja_basic"

import "core:hash"
import "core:mem"
import "core:slice"

Naming_Conv :: enum u8 {
	Original,
	Mangled
}

Config_Virtual_Cache :: struct {
	name_dep_tree_clashes: bool,
	name_dep_tree_clash_a, name_dep_tree_clash_b: ^Config,
	dep_tree_is_dirty: bool
}

Config :: struct {
	//basic: ninja_basic.Config,
	project_name: string,
	naming_conv: Naming_Conv, // For proper usage, use `config_set_naming_conv` etc. to update this.
	required_features: Feature_Set, // For proper usage, use `config_try_add_required_feature` etc. to update this.
	deps: [dynamic]^Config,
	vcache: Config_Virtual_Cache
}

config_init :: proc(self: ^Config, allocator := context.allocator) -> mem.Allocator_Error {
	self.vcache.dep_tree_is_dirty = true
	self.deps = make([dynamic]^Config, allocator=allocator) or_return
	return nil
}

config_destroy :: proc(self: ^Config) -> mem.Allocator_Error {
	// NOTE(rysah): Recursive
	_remove_ref :: proc(target: ^Config, target_container: ^[dynamic]^Config) {
		{
			target_ptr := transmute(uintptr)target
			target_ptr_container := transmute(^[dynamic]uintptr)target_container

			if i, found := slice.linear_search(target_ptr_container[:], target_ptr); found {
				unordered_remove(target_ptr_container, target_ptr)
			}
		}
		for config in target_container {
			_remove_ref(target, &config.deps)
		}
	}

	_remove_ref(self, &self.deps)

	delete(self.deps) or_return
	return nil
}

config_make :: proc(allocator := context.allocator) -> (out: Config, err: mem.Allocator_Error) #optional_allocator_error {
	config_init(&out, allocator=allocator) or_return
	return
}

config_hash32 :: proc(self: ^Config) -> u32 {
	return hash.fnv32a(transmute([]u8)self.project_name)
}

config_hash64 :: proc(self: ^Config) -> u64 {
	return hash.fnv64a(transmute([]u8)self.project_name)
}

config_name_clashes :: proc(a, b: ^Config) -> bool {
	if a == b do return false // Prevents incorrect "clashes"
	return config_hash64(a) == config_hash64(b) && a.naming_conv == b.naming_conv && a.naming_conv == .Original
}

config_name_clashes_deps :: proc(self: ^Config) -> (bool, ^Config, ^Config) {
	for &dep_config in self.deps {
		if dep_config == nil do continue
		if fl, a, b := config_name_clashes_deps(self); fl do return true, a, b
	}
	return false, nil, nil
}

config_name_clashes_cyclical :: proc(self: ^Config) -> (bool, ^Config, ^Config) {
	if fl, a, b := config_name_clashes_deps(self); fl { return true, a, b }
	for &dep_config, i in self.deps {
		if dep_config == nil do continue
		for &other_dep_config, j in self.deps {
			if i == j do continue
			if config_name_clashes(dep_config, other_dep_config) do return true, dep_config, other_dep_config
		}
	}
	return false, nil, nil
}

config_name_dep_tree_clashes :: proc(self: ^Config, possibly_cyclical := true) -> (bool, ^Config, ^Config) {
	clash_proc: #type proc(^Config) -> (bool, ^Config, ^Config) = possibly_cyclical ? config_name_clashes_cyclical : config_name_clashes_deps
	if fl, a, b := clash_proc(self); fl { return true, a, b }
	for &dep_config in self.deps {
		if fl, a, b := clash_proc(dep_config); fl { return true, a, b }
	}
	return false, nil, nil
}

// Virtual cache aware
vca_config_name_dep_tree_clashes :: proc(self: ^Config, possibly_cyclical := true) -> (bool, ^Config, ^Config) {
	if self.vcache.dep_tree_is_dirty {
		self.vcache.dep_tree_is_dirty = false
		self.vcache.name_dep_tree_clashes, self.vcache.name_dep_tree_clash_a, self.vcache.name_dep_tree_clash_b = config_name_dep_tree_clashes(self, possibly_cyclical=possibly_cyclical)
	}
	return self.vcache.name_dep_tree_clashes, self.vcache.name_dep_tree_clash_a, self.vcache.name_dep_tree_clash_b
}

config_try_remove_required_feature :: proc(self: ^Config, feature: Feature) {
	if feature == .RULE_SCOPING {
		if len(self.deps) > 0 {
			hash_clashes, hash_a, hash_b := vca_config_name_dep_tree_clashes(self, possibly_cyclical=true /* TODO(rysah): Maybe could make this more deterministic. */)
			if hash_clashes && hash_a.naming_conv == hash_b.naming_conv && hash_a.naming_conv == .Original {
				return // Cannot remove
			}
		}
	}
	self.required_features -= { feature }
}

config_try_add_required_feature :: proc(self: ^Config, feature: Feature) {
	self.required_features += { feature }
}

config_try_remove_required_feature_set :: proc(self: ^Config, features: Feature_Set) {
	#unroll for feature in Feature {
		if feature in features {
			config_try_remove_required_feature(self, feature)
		}
	}
}

config_try_add_required_feature_set :: proc(self: ^Config, features: Feature_Set) {
	#unroll for feature in Feature {
		if feature in features {
			config_try_add_required_feature(self, feature)
		}
	}
}

config_set_naming_conv :: proc(self: ^Config, naming_conv: Naming_Conv) {
	switch naming_conv {
		case .Original:
			// Given the condition that more projects will be used, to stop the possibility of clashing between
			// names, .RULE_SCOPING will try to be enabled.
			config_try_add_required_feature(self, .RULE_SCOPING)
		case .Mangled:
			// The possibility of clashing between names is far less likely in this case, therefore,
			// .RULE_SCOPING will try to be disabled.
			// NOTE(rysah): config_try_remove_required_feature(self, .RULE_SCOPING) - Will be done during the final stage
	}
	self.naming_conv = naming_conv
}
