package ninja_emit

import "core:strings"
import "core:mem"
import "core:path/filepath"

Lazy_Path_Event_Callback :: struct {
	on_leaf: #type proc(leaf: ^Lazy_Path_Leaf, client_data: rawptr),
	on_branch: #type proc(branch: ^Lazy_Path_Branch, client_data: rawptr)
}

Lazy_Path_Leaf :: distinct string
Lazy_Path_Branch :: distinct [2]^Lazy_Path
Lazy_Path :: union {
	Lazy_Path_Leaf,
	Lazy_Path_Branch
}

lazy_path_resolve :: proc(p: Lazy_Path, allocator := context.allocator) -> 
(out: string, err: mem.Allocator_Error) #optional_allocator_error {
	switch &internal in p {
		case Lazy_Path_Leaf: 
			return strings.clone(transmute(string)internal, allocator=allocator)
		case Lazy_Path_Branch:
			parent := lazy_path_resolve(internal[0]^, allocator=context.temp_allocator) or_return
			child := lazy_path_resolve(internal[1]^, allocator=context.temp_allocator) or_return
			return filepath.join([]string{ parent, child }, allocator=allocator)
	}
	return
}

lazy_path_transform :: proc(p: Lazy_Path, ev: Lazy_Path_Event_Callback, client_data: rawptr) {
	switch &internal in p {
		case Lazy_Path_Leaf:
			if ev.on_leaf != nil do ev.on_leaf(&internal, client_data)

		case Lazy_Path_Branch:
			if ev.on_branch != nil do ev.on_branch(&internal, client_data)
			lazy_path_transform(internal[0]^, ev, client_data) // parent
			lazy_path_transform(internal[1]^, ev, client_data) // child
	}
}

lazy_path_join :: proc(parent, child: ^Lazy_Path) -> Lazy_Path {
	return Lazy_Path_Branch {
		parent,
		child
	}
}

sbprint_lazy_path :: proc(sb: ^strings.Builder, p: Lazy_Path) -> string {
	strings.write_string(sb, lazy_path_resolve(p, allocator=context.temp_allocator))
	return strings.to_string(sb^)
}