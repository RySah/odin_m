package ninja_ir

Command_Component :: union {
    string,
    ^Target,
    Special_Variable
}

Command :: distinct [dynamic]Command_Component
