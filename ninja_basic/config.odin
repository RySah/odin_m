package ninja_basic

import "core:strings"
import "core:fmt"
import "core:mem"
import "core:io"

Config :: struct {
	required_version: Version,
	variables: map[string]string,
	statements: [dynamic]Statement
}

wprint_config :: proc(writer: io.Writer, self: ^Config) {
	if version_gte(self.required_version, VERSION_COMPATIBILITY_VERSION) {
		fmt.wprintfln(writer, "ninja_required_version = %d.%d", self.required_version.x, self.required_version.y)
	}
	for k, v in self.variables {
		fmt.wprintfln(writer, "%s = %s", k, v)
	}
	for &statement in self.statements {
		wprint_statement(writer, &statement)
	}
}

sbprint_config :: proc(sb: ^strings.Builder, self: ^Config) -> string {
	wprint_config(strings.to_writer(sb), self)
	return strings.to_string(sb^)
}

config_init :: proc(self: ^Config, allocator := context.allocator) -> mem.Allocator_Error {
	self.variables = make(map[string]string, allocator=allocator)
	self.statements = make([dynamic]Statement, allocator=allocator) or_return
	return nil
}

config_destroy :: proc(self: ^Config) -> mem.Allocator_Error {
	delete(self.variables) or_return
	for &statement in self.statements {
		statement_destroy(&statement) or_return
	}
	delete(self.statements) or_return
	return nil
}

config_make :: proc(allocator := context.allocator) -> (out: Config, err: mem.Allocator_Error) #optional_allocator_error {
	config_init(&out, allocator=allocator) or_return
	return
}

config_set_features :: proc(self: ^Config, features: Feature_Set) {
	self.required_version = features_get_required_version(features)
}

config_add_statement :: proc(self: ^Config, statements: ..Statement) {
	append(&self.statements, ..statements)
}