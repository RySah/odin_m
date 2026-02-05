package ninja_ir

Variable_Access :: distinct ID

Lazy_Leaf :: union {
    string,
    Special_Variable,
    Variable_Access
}
Lazy_Branch :: distinct [2]^Lazy_Tree
Lazy_Tree :: union {
    Lazy_Leaf,
    Lazy_Branch
}

lazy_tree_join :: proc(parent, child: ^Lazy_Tree) -> Lazy_Tree {
	return Lazy_Branch {
		parent,
		child
	}
}

Lazy_Path :: distinct Lazy_Tree
Lazy_Format :: distinct Lazy_Tree

lazy_path_join :: proc(parent, child: ^Lazy_Path) -> Lazy_Path {
    return transmute(Lazy_Path)lazy_tree_join(
        transmute(^Lazy_Tree)parent,
        transmute(^Lazy_Tree)child,
    )
}

lazy_format_join :: proc(parent, child: ^Lazy_Format) -> Lazy_Format {
    return transmute(Lazy_Format)lazy_tree_join(
        transmute(^Lazy_Tree)parent,
        transmute(^Lazy_Tree)child,
    )
}

Lazy_Command_Token :: union {
    string,
    Special_Variable,
    Variable_Access,
    Lazy_Path,
    Lazy_Format
}

Lazy_Command :: distinct [dynamic]Lazy_Command_Token
