package ninja_ir

import "../ninja_emit"

import "core:mem"

Variable_Access :: struct { name: string }

Rule_Variable_Expr :: union {
    Rule_Command,
    Special_Variable,
    string,
    ^Exec,
    Rule_Command_Concat,
    Variable_Access
}

Build_Variable_Expr :: union {
    Build_Command,
    Special_Variable,
    string,
    ^Rule,
    Build_Command_Concat,
    Variable_Access
}

//NOTE(rysah): Does not guarantee memory allocation, and where. Only safe to use in context of an arena.
@private _rule_variable_expr_to_emit_expr :: proc(self: ^Rule_Variable_Expr, allocator := context.allocator) -> (out: ninja_emit.Expr, err: mem.Allocator_Error) #optional_allocator_error {
    switch &internal in self {
        case Rule_Command:
            return _rule_command_to_emit_expr(&internal, allocator=allocator)
        case Special_Variable: 
            token := Rule_Command_Token(internal)
            return _rule_command_token_to_string(&token, allocator=allocator)
        case string: 
            token := Rule_Command_Token(internal)
            return _rule_command_token_to_string(&token, allocator=allocator)
        case ^Exec: 
            token := Rule_Command_Token(internal)
            return _rule_command_token_to_string(&token, allocator=allocator)
        case Rule_Command_Concat: 
            token := Rule_Command_Token(internal)
            return _rule_command_token_to_string(&token, allocator=allocator)
        case Variable_Access: 
            token := Rule_Command_Token(internal)
            return _rule_command_token_to_string(&token, allocator=allocator)
    }
    unreachable()
}

