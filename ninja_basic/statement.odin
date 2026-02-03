package ninja_basic

import "core:strings"
import "core:fmt"
import "core:mem"

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

sbprint_statement :: proc(b: ^strings.Builder, s: Statement) -> string {
	switch s.kind {
		case .Build:
			fmt.sbprintfln(b, "build %s : %s", s.left, s.right)
			for k, v in s.variables {
				fmt.sbprintfln(b, "  %s = %s", k, v)
			}
			return strings.to_string(b^)
		case .Rule:
			fmt.sbprintfln(b, "rule %s", s.left)
			for k, v in s.variables {
				fmt.sbprintfln(b, "  %s = %s", k, v)
			}
			return strings.to_string(b^)
		case .Pool:
			fmt.sbprintfln(b, "pool %s", s.left)
			for k, v in s.variables {
				fmt.sbprintfln(b, "  %s = %s", k, v)
			}
			return strings.to_string(b^)
		case .Phony:
			return fmt.sbprintfln(b, "build %s: phony %s", s.left, s.right)
		case .Default:
			return fmt.sbprintfln(b, "default %s", s.left)
	}
	return strings.to_string(b^)
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