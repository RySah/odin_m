package ninja_emit

import "core:mem"

// variable_access_ident_syntax_error_in_lazy_tree

General_Error :: enum u8 {
	None,
	Invalid_Variable_Access_Ident
}

Error :: union #shared_nil {
	mem.Allocator_Error,
	General_Error
}