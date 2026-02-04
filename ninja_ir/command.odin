package ninja_ir

Command_Component :: union {
    string,
    ^Target,
    Special_Variable_Accessor
}

Command :: distinct [dynamic]Command_Component
