package ninja_ir

import "../ninja_emit"

import "core:mem"
import "core:strings"

Rule_Command_Token :: union {
    Special_Variable,
    string,
    ^Exec,
    Rule_Command_Concat,
    Variable_Access
}

Rule_Command_Concat :: struct {
    items: []Rule_Command_Token,
    sep: string
}

Rule_Command :: distinct []Rule_Command_Token

File :: union {
    string,
    ^Build
}

Generated_File :: struct {
    path: string,
    source: ^Build
}

Build_Command_Token :: union {
    Special_Variable,
    string,
    ^Rule,
    File,
    Generated_File,
    Build_Command_Concat,
    Variable_Access
}

Build_Command_Concat :: struct {
    items: []Build_Command_Token,
    sep: string
}

Build_Command :: distinct []Build_Command_Token

//TODO(rysah): Make safe public impl of the `_command_token_to_string` and `_command_to_emit_expr`

//NOTE(rysah): Does not guarantee memory allocation, and where. Only safe to use in context of an arena.
@private _rule_command_token_to_string :: proc(self: ^Rule_Command_Token, allocator := context.allocator) -> (out: string, err: mem.Allocator_Error) #optional_allocator_error {
    switch &internal in self^ {
        case Special_Variable: return special_variable_string(internal), nil
        case string: return internal, nil
        case ^Exec:
            switch &file_internal in internal.file {
                case string: return file_internal, nil
                case ^Build: return file_internal.output, nil
            }
        case Rule_Command_Concat: 
            string_items := make([]string, len(internal.items), allocator=context.temp_allocator)
            for &item, i in internal.items {
                //TODO(rysah): Perhaps get rid of the recursion.
                string_items[i] = _rule_command_token_to_string(&item, allocator=context.temp_allocator) or_return
            }
            return strings.join(string_items, internal.sep, allocator=allocator)
        case Variable_Access:
            return strings.concatenate({ "$", internal.name }, allocator=allocator)
    }
    unreachable()
}

//NOTE(rysah): Does not guarantee memory allocation, and where. Only safe to use in context of an arena.
@private _rule_command_to_emit_expr :: proc(self: ^Rule_Command, allocator := context.allocator) -> (out: ninja_emit.Expr_Collection, err: mem.Allocator_Error) #optional_allocator_error {
    out = make(ninja_emit.Expr_Collection, len(self), allocator=allocator) or_return
    for &token, i in self {
        out[i] = new(ninja_emit.Expr, allocator=allocator) or_return
        out[i]^ = _rule_command_token_to_string(&token, allocator=allocator) or_return
    }
    return
}

//NOTE(rysah): Does not guarantee memory allocation, and where. Only safe to use in context of an arena.
@private _build_command_token_to_string :: proc(self: ^Build_Command_Token, allocator := context.allocator) -> (out: string, err: mem.Allocator_Error) #optional_allocator_error {
    switch &internal in self^ {
        case Special_Variable: return special_variable_string(internal), nil
        case string: return internal, nil
        case ^Rule: return internal.name, nil
        case File: 
            switch &file_internal in internal {
                case string: return file_internal, nil
                case ^Build: return file_internal.output, nil
            }
        case Generated_File:
            return internal.path, nil
        case Build_Command_Concat: 
            string_items := make([]string, len(internal.items), allocator=context.temp_allocator)
            for &item, i in internal.items {
                //TODO(rysah): Perhaps get rid of the recursion.
                string_items[i] = _build_command_token_to_string(&item, allocator=context.temp_allocator) or_return
            }
            return strings.join(string_items, internal.sep, allocator=allocator)
        case Variable_Access:
            return strings.concatenate({ "$", internal.name }, allocator=allocator)
    }
    unreachable()
}

//NOTE(rysah): Does not guarantee memory allocation, and where. Only safe to use in context of an arena.
@private _build_command_to_emit_expr :: proc(self: ^Build_Command, allocator := context.allocator) -> (out: ninja_emit.Expr_Collection, err: mem.Allocator_Error) #optional_allocator_error {
    out = make(ninja_emit.Expr_Collection, len(self), allocator=allocator) or_return
    for &token, i in self {
        out[i] = new(ninja_emit.Expr, allocator=allocator) or_return
        out[i]^ = _build_command_token_to_string(&token, allocator=allocator) or_return
    }
    return
}