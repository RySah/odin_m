package ninja_emit

import "../ninja_basic"

import "core:mem"
import "base:runtime"

Statement_Variable :: struct {
	using _: Variable,
	is_builtin: bool
}

Statement :: struct {
	kind: Statement_Kind,
	expr: Expr,
	variables: [dynamic]Statement_Variable,
	source_loc: Maybe(runtime.Source_Code_Location)
}

// More "semantically immutable" transmutation of Statement
Immut_Statement :: [size_of(Statement)]u8

Final_Statement :: struct {
	data: Immut_Statement,
	// Errors will not be immediately logged until registered
	errors: [dynamic]Error
}

statement_final :: proc(s: ^Statement, minimum_version: Version, allocator := context.allocator) -> 
(out: Final_Statement, err: mem.Allocator_Error) {
	LPEC_Client_Data :: struct {
		errors: ^[dynamic]Error,
		error_allocator: mem.Allocator,
		source_loc: Maybe(runtime.Source_Code_Location),
		original: ^Lazy_Path
	}
	LPEC :: Lazy_Path_Event_Callback {
		on_leaf = proc(leaf: ^Lazy_Path_Leaf, client_data: rawptr) {
			client_data := transmute(^LPEC_Client_Data)client_data
			errors := client_data.errors
			error_allocator := client_data.error_allocator
			source_loc := client_data.source_loc
			original := client_data.original
			seg := leaf^
			// Enforcing the ${...} syntax rather than the less descriptive $...
			if len(seg) > len("${}") && seg[0] == '$' && seg[1] == '{' && seg[len(seg)-1] == '}' {
				ident_seg := seg[2:len(seg)-1]
				ident := transmute(string)ident_seg
				if !is_ident(ident) {
					append(errors, 
						variable_access_ident_syntax_error_in_lazy_path(original^, ident, source_loc=source_loc, allocator=error_allocator)
					)
				}
			}
		},
		on_branch = nil // proc(branch: ^Lazy_Path_Branch, client_data: rawptr)
	}
	
	// Mainly identifies syntax errors in lazy paths, and flags variables that are builtin based-off the minimum_version.
	_resolve_expr :: proc(e: ^Expr, client_data: LPEC_Client_Data) {
		client_data := client_data
		switch &internal in e {
			case String_Expr:
			case Lazy_Path_Expr:
				lazy_path := &internal.base

				client_data.source_loc = internal.source_loc
				client_data.original = lazy_path

				lpec := LPEC
				lazy_path_transform(lazy_path^, lpec, &client_data)
			case Expr_Collection:
				for other_e in internal.arr {
					_resolve_expr(other_e, client_data)
				}
			case Bin_Expr:
				_resolve_expr(internal.left, client_data)
				_resolve_expr(internal.right, client_data)
			case Int_Expr:
		}
	}

	out.errors = make([dynamic]Error, allocator=allocator) or_return

	lpec_client_data := LPEC_Client_Data {
		errors = &out.errors,
		error_allocator = allocator
	}

	_resolve_expr(&s.expr, lpec_client_data)
	for &var in s.variables {
		_resolve_expr(&var.expr, lpec_client_data)
		switch s.kind {
			case .Build:
			case .Rule:
				var.is_builtin = 
					var.name == "command" ||
					var.name == "depfile" ||
					(var.name == "deps" && version_gte(DEPS_VERSION, minimum_version)) ||
					(var.name == "msvc_deps_prefix" && version_gte(Version{ 1, 5 }, minimum_version)) ||
					var.name == "description" ||
					(var.name == "dyndep" && version_gte(DYNAMIC_DEP_VERSION, minimum_version)) ||
					var.name == "generator" ||
					var.name == "in" ||
					var.name == "in_newline" ||
					var.name == "out" ||
					var.name == "restat" ||
					var.name == "rspfile" ||
					var.name == "rspfile_content"
			case .Pool:
				var.is_builtin =
					var.name == "depth"
		}
	}

	out.data = transmute(Immut_Statement)(s^)
	return
}
