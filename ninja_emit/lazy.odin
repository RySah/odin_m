package ninja_emit

import "core:strings"
import "core:mem"
import "core:path/filepath"

Lazy_Tree_Event_Callback :: struct {
	on_leaf: #type proc(leaf: ^Lazy_Leaf, client_data: rawptr),
	on_branch: #type proc(branch: ^Lazy_Branch, client_data: rawptr)
}

Lazy_Leaf :: distinct string
Lazy_Branch :: distinct [2]^Lazy_Tree
Lazy_Tree :: union {
	Lazy_Leaf,
	Lazy_Branch
}

Lazy_Tree_Resolve_Proc :: #type proc(Lazy_Tree, mem.Allocator) -> (string, mem.Allocator_Error)
Lazy_Tree_Join_Proc :: #type proc([]string, mem.Allocator) -> (string, mem.Allocator_Error)

lazy_tree_resolve :: proc(tree: Lazy_Tree, join_proc: Lazy_Tree_Join_Proc, allocator := context.allocator) -> 
(out: string, err: mem.Allocator_Error) #optional_allocator_error {
	switch &internal in tree {
		case Lazy_Leaf: 
			return strings.clone(transmute(string)internal, allocator=allocator)
		case Lazy_Branch:
			parent := lazy_tree_resolve(internal[0]^, join_proc, allocator=context.temp_allocator) or_return
			child := lazy_tree_resolve(internal[1]^, join_proc, allocator=context.temp_allocator) or_return
			return join_proc([]string{ parent, child }, allocator)
	}
	return
}

lazy_tree_transform :: proc(tree: Lazy_Tree, ev: Lazy_Tree_Event_Callback, client_data: rawptr) {
	switch &internal in tree {
		case Lazy_Leaf:
			if ev.on_leaf != nil do ev.on_leaf(&internal, client_data)

		case Lazy_Branch:
			if ev.on_branch != nil do ev.on_branch(&internal, client_data)
			lazy_tree_transform(internal[0]^, ev, client_data) // parent
			lazy_tree_transform(internal[1]^, ev, client_data) // child
	}
}

lazy_tree_join :: proc(parent, child: ^Lazy_Tree) -> Lazy_Tree {
	return Lazy_Branch {
		parent,
		child
	}
}

lazy_path_resolve :: proc(tree: Lazy_Tree, allocator: mem.Allocator) -> 
(out: string, err: mem.Allocator_Error) #optional_allocator_error {
	_join : Lazy_Tree_Join_Proc : proc(elems: []string, allocator: mem.Allocator) -> (output: string, err: mem.Allocator_Error) {
		return filepath.join(elems, allocator=allocator)
	}
	return lazy_tree_resolve(
		tree,
		_join,
		allocator=allocator
	)
}

lazy_command_resolve :: proc(tree: Lazy_Tree, allocator := context.allocator) ->
(out: string, err: mem.Allocator_Error) #optional_allocator_error {
	_join : Lazy_Tree_Join_Proc : proc(elems: []string, allocator: mem.Allocator) -> (output: string, err: mem.Allocator_Error) {
		return strings.join(elems, " ", allocator=allocator)
	}
	return lazy_tree_resolve(
		tree,
		_join,
		allocator=allocator
	)
}	

sbprint_lazy_path :: proc(sb: ^strings.Builder, tree: Lazy_Tree) -> string {
	strings.write_string(sb, lazy_path_resolve(tree, allocator=context.temp_allocator))
	return strings.to_string(sb^)
}

sbprint_lazy_command :: proc(sb: ^strings.Builder, tree: Lazy_Tree) -> string {
	strings.write_string(sb, lazy_command_resolve(tree, allocator=context.temp_allocator))
	return strings.to_string(sb^)
}