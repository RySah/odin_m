package ninja_ir

import "core:mem"

Command_Token :: union {
    Special_Variable,
    string,
    ^File,
    Concat
}

// { items = { Special_Variable.Out, ".rsp" }, sep = "" }
Concat :: struct {
    items: []Command_Token,
    sep: string
}

Command :: distinct [dynamic]Command_Token
