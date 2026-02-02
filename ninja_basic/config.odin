package ninja_basic

import "core:strings"
import "core:fmt"
import "core:mem"

Config :: struct {
	required_version: Version,
	variables: map[string]string,
	statements: [dynamic]Statement,
	allocator: mem.Allocator
}

sbprint_config :: proc(b: ^strings.Builder, cnf: Config) -> string {
	if version_gte(cnf.required_version, VERSION_COMPATIBILITY_VERSION) {
		fmt.sbprintfln(b, "ninja_required_version = %d.%d", cnf.required_version.x, cnf.required_version.y)
	}
	for k, v in cnf.variables {
		fmt.sbprintfln(b, "%s = %s", k, v)
	}
	for &statement in cnf.statements {
		sbprint_statement(b, statement)
	}
	return strings.to_string(b^)
}

config_init :: proc(cnf: ^Config, allocator := context.allocator) -> mem.Allocator_Error {
	cnf.variables = make(map[string]string, allocator=allocator)
	cnf.statements = make([dynamic]Statement, allocator=allocator) or_return
	cnf.allocator = allocator
	return nil
}

config_destroy :: proc(cnf: ^Config) -> mem.Allocator_Error {
	delete(cnf.variables) or_return
	for &statement in cnf.statements {
		statement_destroy(&statement) or_return
	}
	delete(cnf.statements) or_return
	return nil
}

config_make :: proc(allocator := context.allocator) -> (out: Config, err: mem.Allocator_Error) #optional_allocator_error {
	config_init(&out, allocator=allocator) or_return
	return
}

config_new_statement :: proc(cnf: ^Config) -> Statement {
	return statement_make(allocator=cnf.allocator)
}

config_set_features :: proc(cnf: ^Config, features: Feature_Set) {
	cnf.required_version = features_get_required_version(features)
}