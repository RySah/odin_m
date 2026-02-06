package ninja_ir

import "../ninja_emit"

import "core:mem"
import "core:strings"

Command_Token :: union {
    Special_Variable,
    string,
    ^File,
    ^Exec,
    Concat,
    Variable_Access
}

Concat :: struct {
    items: []Command_Token,
    sep: string
}

Command :: distinct [dynamic]Command_Token

//TODO(rysah): Make safe public impl of the `_command_token_to_string` and `_command_to_emit_expr`

//NOTE(rysah): Does not guarantee memory allocation, and where. Only safe to use in context of an arena.
@private _command_token_to_string :: proc(self: ^Command_Token, allocator := context.allocator) -> (out: string, err: mem.Allocator_Error) #optional_allocator_error {
    switch &internal in self^ {
        case Special_Variable: return special_variable_string(internal), nil
        case string: return internal, nil
        case ^File: return internal.name, nil //TODO(rysah): Ensure this is correct to do.
        case ^Exec: return internal.file.name, nil //TODO(rysah): Ensure this is correct to do.
        case Concat: 
            string_items := make([]string, len(internal.items), allocator=context.temp_allocator)
            for &item, i in internal.items {
                //TODO(rysah): Perhaps get rid of the recursion.
                string_items[i] = _command_token_to_string(&item, allocator=context.temp_allocator) or_return
            }
            return strings.join(string_items, internal.sep, allocator=allocator)
        case Variable_Access:
            return strings.concatenate({ "$", internal.name }, allocator=allocator)
    }
    unreachable()
}

//NOTE(rysah): Does not guarantee memory allocation, and where. Only safe to use in context of an arena.
@private _command_to_emit_expr :: proc(self: ^Command, allocator := context.allocator) -> (out: ninja_emit.Expr_Collection, err: mem.Allocator_Error) #optional_allocator_error {
    out = make(ninja_emit.Expr_Collection, len(self), allocator=allocator) or_return
    for &token, i in self {
        out[i] = new(ninja_emit.Expr, allocator=allocator) or_return
        out[i]^ = _command_token_to_string(&token, allocator=allocator) or_return
    }
    return
}