package ninja_ir

Command_Token :: union {
    Special_Variable,
    string,
    ^File,
    Concat
}

// { items = { Special_Variable.Out, ".rsp" }, sep = "" }
Concat :: struct {
    items: [dynamic]Command_Token,
    sep: string
}

Command :: distinct Concat


