package ninja_ir

Command_Token :: union {
    Special_Variable,
    string,
    ^File
}

Command :: distinct [dynamic]Command_Token
