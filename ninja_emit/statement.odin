package ninja_emit

import "../ninja_basic"

import "core:mem"
import "base:runtime"

Statement_Manager :: struct {
	statements: [dynamic]Statement,
	allocator: mem.Allocator
}

Statement :: struct {
	kind: Statement_Kind,
	left, right: Expr,
	variables: [dynamic]Variable
}

statement_manager_init :: proc(self: ^Statement_Manager, allocator := context.allocator) -> mem.Allocator_Error {
	self.statements = make([dynamic]Statement, allocator=allocator) or_return
	self.allocator = allocator
	return nil
}

statement_manager_destroy :: proc(self: ^Statement_Manager) -> mem.Allocator_Error {
	for &stmt in self.statements {
		statement_destroy(&stmt) or_return
	}
	delete(self.statements) or_return
	return nil
}

statement_manager_register_statement :: proc(self: ^Statement_Manager, s: Statement) -> mem.Allocator_Error {
	append(&self.statements, s) or_return
	return nil
}

statement_manager_create_statement :: proc(self: ^Statement_Manager) -> (out: Statement, err: mem.Allocator_Error) #optional_allocator_error {
	out.variables = make([dynamic]Variable, allocator=self.allocator) or_return
	return
}

// For those that has `Statement_Manager` as a sub-type
register_statement :: statement_manager_register_statement

// For those that has `Statement_Manager` as a sub-type
create_statement :: statement_manager_create_statement

statement_destroy :: proc(self: ^Statement) -> mem.Allocator_Error {
	delete(self.variables) or_return
	return nil
}

// statement_add_variable :: proc(self: ^Statement, var: Variable) -> mem.Allocator_Error {
// 	append(&self.variables, var) or_return
// 	return nil
// }