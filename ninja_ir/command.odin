package ninja_ir

Lazy_Leaf :: union {
    string,
    ID, // Access ID
    Special_Variable
}
Lazy_Branch :: struct {
    components: [2]^Lazy_Tree,
    sep: string
}
Lazy_Tree :: union {
	Lazy_Leaf,
	Lazy_Branch
}
