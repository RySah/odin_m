package ninja_basic

import "core:strings"
import "core:fmt"
import "core:mem"
import "core:io"

Statement_Kind :: enum u8 {
	Build,
	Rule,
	Pool,
	Phony,
	Default
}

Statement :: struct {
	kind: Statement_Kind,
	left, right: string,
	variables: map[string]string
}

wprint_statement :: proc(writer: io.Writer, self: ^Statement) {
	switch self.kind {
		case .Build:
			fmt.wprintfln(writer, "build %s : %s", self.left, self.right)
			for k, v in self.variables {
				fmt.wprintfln(writer, "  %s = %s", k, v)
			}
		case .Rule:
			fmt.wprintfln(writer, "rule %s", self.left)
			for k, v in self.variables {
				fmt.wprintfln(writer, "  %s = %s", k, v)
			}
		case .Pool:
			fmt.wprintfln(writer, "pool %s", self.left)
			for k, v in self.variables {
				fmt.wprintfln(writer, "  %s = %s", k, v)
			}
		case .Phony:
			fmt.wprintfln(writer, "build %s: phony %s", self.left, self.right)
		case .Default:
			fmt.wprintfln(writer, "default %s", self.left)
	}
}

sbprint_statement :: proc(sb: ^strings.Builder, self: ^Statement) -> string {
	wprint_statement(strings.to_writer(sb), self)
	return strings.to_string(sb^)
}

statement_init :: proc(s: ^Statement, allocator := context.allocator) {
	s.variables = make(map[string]string, allocator=allocator)
}

statement_destroy :: proc(s: ^Statement) -> mem.Allocator_Error {
	delete(s.variables) or_return
	return nil
}

statement_make :: proc(allocator := context.allocator) -> (out: Statement) {
	statement_init(&out, allocator=allocator)
	return
}