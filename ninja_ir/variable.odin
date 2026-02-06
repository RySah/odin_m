package ninja_ir

import "../ninja_emit"

import "core:mem"

Variable_Access :: struct { name: string }

Variable_Expr :: union {
    Command,
    Command_Token
}

//NOTE(rysah): Does not guarantee memory allocation, and where. Only safe to use in context of an arena.
@private _variable_expr_to_emit_expr :: proc(self: ^Variable_Expr, allocator := context.allocator) -> (out: ninja_emit.Expr, err: mem.Allocator_Error) #optional_allocator_error {
    switch &internal in self^ {
        case Command: return _command_to_emit_expr(&internal, allocator=allocator)
        case Command_Token: return _command_token_to_string(&internal, allocator=allocator)
    }
    unreachable()
}