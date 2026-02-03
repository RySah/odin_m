package ninja_emit

import "core:mem"

import "base:runtime"

Final :: struct($T: typeid) {
    _: [size_of(T)]u8
}

statement_final :: proc(
    self: ^Statement, minimum_version: Version, 
    errors: ^[dynamic]Error,
    extra_vars: ..Statement_Variable,
    allocator := context.allocator) -> 
(out: Final(Statement), err: mem.Allocator_Error) #optional_allocator_error {
	LPEC_Client_Data :: struct {
		errors: ^[dynamic]Error,
		error_allocator: mem.Allocator,
		source_loc: Maybe(runtime.Source_Code_Location),
		original: ^Lazy_Path,
        variables: ^[]Statement_Variable,
        kind: Statement_Kind,
        minimum_version: Version
	}
	LPEC :: Lazy_Path_Event_Callback {
		on_leaf = proc(leaf: ^Lazy_Path_Leaf, client_data: rawptr) {
			client_data := transmute(^LPEC_Client_Data)client_data
			errors := client_data.errors
			error_allocator := client_data.error_allocator
			source_loc := client_data.source_loc
			original := client_data.original
            variables := client_data.variables
            kind := client_data.kind
            minimum_version := client_data.minimum_version
			seg := leaf^
			// Enforcing the `${...}` syntax rather than the less descriptive `$...`
			if len(seg) > len("${}") && seg[0] == '$' && seg[1] == '{' && seg[len(seg)-1] == '}' {
				ident_seg := seg[2:len(seg)-1]
				ident := transmute(string)ident_seg
				if !is_ident(ident) {
					append(errors,
						variable_access_ident_syntax_error_in_lazy_path(
							original^, ident, source_loc=source_loc, allocator=error_allocator
						)
					)
				} else { // is_ident
                    switch kind {
		            	case .Rule, .Build:
		            		if !_is_builtin_build_and_rule_name(ident, minimum_version) {
                                found := false
                                for &var in variables^ {
                                    if var.is_builtin do continue
                                    if ident == var.name {
                                        found = true
                                        break
                                    }
                                }
                                if !found {
                                    append(errors,
					                	variable_access_ident_logic_error_in_lazy_path(
					                		original^, ident, source_loc=source_loc, allocator=error_allocator
					                	)
					                )
                                }
                            }
		            	case .Pool:
		            		if !_is_builtin_pool_name(ident, minimum_version) {
                                found := false
                                for &var in variables^ {
                                    if var.is_builtin do continue
                                    if ident == var.name {
                                        found = true
                                        break
                                    }
                                }
                                if !found {
                                    append(errors,
					                	variable_access_ident_logic_error_in_lazy_path(
					                		original^, ident, source_loc=source_loc, allocator=error_allocator
					                	)
					                )
                                }
                            }
                        case .Phony: // Nothing to do.
                        case .Default:
                            
		            }
				}
			}
		},
		on_branch = nil // proc(branch: ^Lazy_Path_Branch, client_data: rawptr)
	}
	
	// Mainly identifies syntax errors in lazy paths, and flags variables that are builtin based-off the minimum_version.
	_resolve_expr :: proc(e: ^Expr, client_data: LPEC_Client_Data) {
		client_data := client_data
		switch &internal in e {
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
			case String_Expr:
			case Ident_Expr:
		}
	}

    _is_builtin_build_and_rule_name :: proc(name: string, minimum_version: Version) -> bool {
        return (
			(name == "ninja_required_version" && version_gte(VERSION_COMPATIBILITY_VERSION, minimum_version)) ||

			name == "command" ||
			name == "depfile" ||
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
			name == "rspfile_content"
		)
    }
    _is_builtin_pool_name :: proc(name: string, minimum_version: Version) -> bool {
        return (
			(name == "ninja_required_version" && version_gte(VERSION_COMPATIBILITY_VERSION, minimum_version)) ||

            name == "depth"
        )
    }

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

    variables := make([]Statement_Variable, len(extra_vars)+len(self.variables), allocator=context.temp_allocator) or_return
    copy(variables, extra_vars)
    copy(variables[len(extra_vars):], self.variables[:])

    lpec_client_data := LPEC_Client_Data {
		errors = errors,
		error_allocator = allocator,
        variables = &variables,
        kind = self.kind,
        minimum_version = minimum_version
	}

	_resolve_expr(&self.left, lpec_client_data)
	_resolve_expr(&self.right, lpec_client_data)
    for &var in self.variables {
		_resolve_expr(&var.expr, lpec_client_data)
    }

	return transmute(Final(Statement))(self^), nil
}

config_final :: proc(self: ^Config, minimum_version: Version, errors: ^[dynamic]Error, allocator := context.allocator) -> (out: Final(Config), err: mem.Allocator_Error) #optional_allocator_error {
    for &statement in self.statements {
		statement_final(&statement, minimum_version, errors, ..self.variables[:], allocator=allocator) or_return
	}
	return transmute(Final(Config))(self^), nil
}