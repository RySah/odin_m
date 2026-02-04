package ninja_emit

import "../ninja_basic"

import "core:hash"
import "core:mem"
import "core:slice"
import "core:fmt"

import "base:intrinsics"

Config :: struct {
	project_name: string,
	required_features: Feature_Set,
	using _: Statement_Manager,
	variables: [dynamic]Statement_Variable
}

config_init :: proc(self: ^Config, allocator := context.allocator) -> mem.Allocator_Error {
	statement_manager_init(self, allocator=self.allocator) or_return
	self.variables = make([dynamic]Statement_Variable) or_return
	return nil
}

config_destroy :: proc(self: ^Config) -> mem.Allocator_Error {
	statement_manager_destroy(self) or_return
	delete(self.variables) or_return
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

// config_name_clashes :: proc(a, b: ^Config) -> bool {
// 	if a == b do return false // Prevents incorrect "clashes"
// 	return config_hash64(a) == config_hash64(b)
// }

// config_name_clashes_deps :: proc(self: ^Config) -> (bool, ^Config, ^Config) {
// 	for &dep_config in self.deps {
// 		if dep_config == nil do continue
// 		if fl, a, b := config_name_clashes_deps(self); fl do return true, a, b
// 	}
// 	return false, nil, nil
// }

// config_name_clashes_cyclical :: proc(self: ^Config) -> (bool, ^Config, ^Config) {
// 	if fl, a, b := config_name_clashes_deps(self); fl { return true, a, b }
// 	for &dep_config, i in self.deps {
// 		if dep_config == nil do continue
// 		for &other_dep_config, j in self.deps {
// 			if i == j do continue
// 			if config_name_clashes(dep_config, other_dep_config) do return true, dep_config, other_dep_config
// 		}
// 	}
// 	return false, nil, nil
// }

// config_name_dep_tree_clashes :: proc(self: ^Config, possibly_cyclical := true) -> (bool, ^Config, ^Config) {
// 	clash_proc: #type proc(^Config) -> (bool, ^Config, ^Config) = possibly_cyclical ? config_name_clashes_cyclical : config_name_clashes_deps
// 	if fl, a, b := clash_proc(self); fl { return true, a, b }
// 	for &dep_config in self.deps {
// 		if fl, a, b := clash_proc(dep_config); fl { return true, a, b }
// 	}
// 	return false, nil, nil
// }

// config_try_remove_required_feature :: proc(self: ^Config, feature: Feature) {
// 	if feature == .RULE_SCOPING {
// 		if len(self.deps) > 0 {
// 			name_clashes, config_a, config_b := vca_config_name_dep_tree_clashes(self, possibly_cyclical=true /* TODO(rysah): Maybe could make this more deterministic. */)
// 			if name_clashes {
// 				return // Cannot remove
// 			}
// 		}
// 	}
// 	self.required_features -= { feature }
// }

// config_try_add_required_feature :: proc(self: ^Config, feature: Feature) {
// 	self.required_features += { feature }
// }

// config_try_remove_required_feature_set :: proc(self: ^Config, features: Feature_Set) {
// 	#unroll for feature in Feature {
// 		if feature in features {
// 			config_try_remove_required_feature(self, feature)
// 		}
// 	}
// }

// config_try_add_required_feature_set :: proc(self: ^Config, features: Feature_Set) {
// 	#unroll for feature in Feature {
// 		if feature in features {
// 			config_try_add_required_feature(self, feature)
// 		}
// 	}
// }

// config_set_name :: proc(self: ^Config, name: string) {
// 	self.project_name = name
// }

// config_set_naming_conv :: proc(self: ^Config, naming_conv: Naming_Conv) {
// 	switch naming_conv {
// 		case .Original:
// 			// Given the condition that more projects will be used, to stop the possibility of clashing between
// 			// names, .RULE_SCOPING will try to be enabled.
// 			// config_try_add_required_feature(self, .RULE_SCOPING)
// 			self.required_features += { .RULE_SCOPING }
// 		case .Project_Prefix:
// 			// The possibility of clashing between names is far less likely in this case, therefore,
// 			// .RULE_SCOPING will try to be disabled.
// 			// NOTE(rysah): config_try_remove_required_feature(self, .RULE_SCOPING) - Will be done during the final stage
// 	}
// 	self.naming_conv = naming_conv
// }

config_add_variable :: proc(self: ^Config, var: Statement_Variable) -> mem.Allocator_Error {
	append(&self.variables, var) or_return
	return nil
}

config_resolve_required_features :: proc(self: ^Config, skip := Feature_Set{}) -> mem.Allocator_Error {
	_get_required_features_for_expr :: proc(expr: ^Expr, features: ^Feature_Set, skip: Feature_Set, is_output: bool) {
		#partial switch &internal in expr^ {
			case Expr_Collection:
				for expr_item in internal.arr {
					_get_required_features_for_expr(expr_item, features, skip, is_output)
				}
			case Bin_Expr:
				#partial switch internal.kind {
					case .Implicit:
						if .IMPLICIT_OUTPUTS not_in skip && is_output {
							features^ += { .IMPLICIT_OUTPUTS }
						}
					case .Validation:
						features^ += { .VALIDATIONS } if .VALIDATIONS not_in skip else {} 
				}
				_get_required_features_for_expr(internal.left, features, skip, is_output)
				_get_required_features_for_expr(internal.right, features, skip, is_output)
		}
	}
	
	console_pool_is_user_defined := false
	
	for &stmt in self.statements {
		if stmt.kind == .Pool {
			#type_assert {
				if str_expr, is_str_expr := stmt.left.(String_Expr); is_str_expr {
					if str_expr.base == "console" {
						console_pool_is_user_defined = true
					} 
				}
			}
			self.required_features += { .POOLS } if .POOLS not_in skip else {}
		} else if stmt.kind == .Build {
			if .CONSOLE_POOL not_in skip && .CONSOLE_POOL not_in self.required_features {
				for &var in stmt.variables {
					if var.name == "pool" {
						#type_assert {
							if str_expr, is_str_expr := stmt.left.(String_Expr); is_str_expr {
								if str_expr.base == "console" && !console_pool_is_user_defined {
									self.required_features += { .CONSOLE_POOL }
									break
								}
							}
						}
					}
				}
			}
		} else if stmt.kind == .Rule {
			if .CONSOLE_POOL not_in skip && .CONSOLE_POOL not_in self.required_features {
				for &var in stmt.variables {
					if var.name == "pool" {
						#type_assert {
							if str_expr, is_str_expr := stmt.left.(String_Expr); is_str_expr {
								if str_expr.base == "console" && !console_pool_is_user_defined {
									self.required_features += { .CONSOLE_POOL }
									break
								}
							}
						}
					}
				}
			}
		}

		if stmt.kind == .Build || stmt.kind == .Rule {
			_get_required_features_for_expr(&stmt.left, &self.required_features, skip, false)
			_get_required_features_for_expr(&stmt.right, &self.required_features, skip, true)
		}
	}

	return nil
}

config_resolve_all_features :: proc(self: ^Config, skip := Feature_Set{}) -> mem.Allocator_Error {
	config_resolve_required_features(self, skip=skip) or_return
	self.required_features = ninja_basic.version_get_features(ninja_basic.features_get_required_version(self.required_features))
	return nil
}