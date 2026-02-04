package ninja_emit

import "core:mem"

import "base:runtime"

Final :: struct($T: typeid) {
    _: [size_of(T)]u8
}

@(private="file") _LTEC_Client_Data :: struct {
	error: Error
}
@(private="file") _LTEC :: Lazy_Tree_Event_Callback {
	on_leaf = proc(leaf: ^Lazy_Leaf, client_data: rawptr) {
		client_data := transmute(^_LTEC_Client_Data)client_data
		error_output := &client_data.error
		seg := leaf^
		// Enforcing the `${...}` syntax rather than the less descriptive `$...`
		if len(seg) > len("${}") && seg[0] == '$' && seg[1] == '{' && seg[len(seg)-1] == '}' {
			ident_seg := seg[2:len(seg)-1]
			ident := transmute(string)ident_seg
			if !is_ident(ident) {
				error_output^ = General_Error.Invalid_Variable_Access_Ident
				return
			}
		}
	},
	on_branch = nil // proc(branch: ^Lazy_Path_Branch, client_data: rawptr)
}

// Mainly identifies syntax errors in lazy paths, and flags variables that are builtin based-off the minimum_version.
@(private="file") _resolve_expr :: proc(
	expr: ^Expr, client_data: ^_LTEC_Client_Data
) -> Error {
	switch &internal in expr^ {
		case Lazy_Path_Expr:
			ltec := _LTEC
			lazy_tree_transform(internal.base, ltec, client_data)
			if client_data.error != nil do return client_data.error
		case Lazy_Command_Expr:
			ltec := _LTEC
			lazy_tree_transform(internal.base, ltec, client_data)
			if client_data.error != nil do return client_data.error
		case Expr_Collection:
			for other_e in internal.arr {
				_resolve_expr(other_e, client_data) or_return
			}
		case Bin_Expr:
			_resolve_expr(internal.left, client_data) or_return
			_resolve_expr(internal.right, client_data) or_return
		case Int_Expr:
		case String_Expr:
	}
	return nil
}

@(private="file") _is_builtin_build_and_rule_name :: proc(name: string, minimum_version: Version) -> bool {
	return (
		(name == "ninja_required_version" && version_gte(VERSION_COMPATIBILITY_VERSION, minimum_version)) ||

		name == "command" ||
		( name == "depfile" && version_gte(DEPS_VERSION, minimum_version)) ||
		(name == "deps" && version_gte(DEPS_VERSION, minimum_version)) ||
		(name == "msvc_deps_prefix" && version_gte(Version{ 1, 5 }, minimum_version)) ||
		name == "description" ||
		(name == "dyndep" && version_gte(DYNAMIC_DEP_VERSION, minimum_version)) ||
		name == "generator" ||
		name == "in" ||
		name == "in_newline" ||
		name == "out" ||
		name == "restat" ||
		name == "rspfile" ||
		name == "rspfile_content" ||
		(name == "pool" && version_gte(POOLS_VERSION, minimum_version))
	)
}
@(private="file") _is_builtin_pool_name :: proc(name: string, minimum_version: Version) -> bool {
	return (
		(name == "ninja_required_version" && version_gte(VERSION_COMPATIBILITY_VERSION, minimum_version)) ||

		name == "depth"
	)
}

statement_final :: proc(
    self: ^Statement, minimum_version: Version
) -> (out: Final(Statement), err: Error) {
	for &var in self.variables {
        if !var.is_builtin {
            switch self.kind {
		    	case .Rule, .Build:
		    		var.is_builtin = _is_builtin_build_and_rule_name(var.name, minimum_version)
		    	case .Pool:
		    		var.is_builtin = _is_builtin_pool_name(var.name, minimum_version)
                case .Phony: // Nothing is builtin
                case .Default: // Nothing is builtin
		    }
        }
	}

    lpec_client_data := _LTEC_Client_Data {}

	_resolve_expr(&self.left, &lpec_client_data) or_return
	_resolve_expr(&self.right, &lpec_client_data) or_return
    for &var in self.variables {
		_resolve_expr(&var.expr, &lpec_client_data) or_return
    }

	return transmute(Final(Statement))(self^), nil
}

config_final :: proc(
	self: ^Config, minimum_version: Version
) -> (out: Final(Config), err: Error) {
    variables := self.variables[:]
	
	lpec_client_data := _LTEC_Client_Data {}
	
	for &statement in self.statements {
		statement_final(&statement, minimum_version) or_return
	}
	return transmute(Final(Config))(self^), nil
}