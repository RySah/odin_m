package ninja_ir

import "../ninja_emit"

import "core:mem"

Variable_Access :: struct { name: string }

Variable_Expr :: union {
    Command_Slice,
    Special_Variable,
    string,
    ^File,
    ^Exec,
    Concat,
    Variable_Access
}

//NOTE(rysah): Does not guarantee memory allocation, and where. Only safe to use in context of an arena.
@private _variable_expr_to_emit_expr :: proc(self: ^Variable_Expr, allocator := context.allocator) -> (out: ninja_emit.Expr, err: mem.Allocator_Error) #optional_allocator_error {
    switch &internal in self {
        case Command_Slice:
            return _command_to_emit_expr(&internal, allocator=allocator)
        case Special_Variable: 
            token := Command_Token(internal)
            return _command_token_to_string(&token, allocator=allocator)
        case string: 
            token := Command_Token(internal)
            return _command_token_to_string(&token, allocator=allocator)
        case ^File: 
            token := Command_Token(internal)
            return _command_token_to_string(&token, allocator=allocator)
        case ^Exec: 
            token := Command_Token(internal)
            return _command_token_to_string(&token, allocator=allocator)
        case Concat: 
            token := Command_Token(internal)
            return _command_token_to_string(&token, allocator=allocator)
        case Variable_Access: 
            token := Command_Token(internal)
            return _command_token_to_string(&token, allocator=allocator)
    }
    unreachable()
}