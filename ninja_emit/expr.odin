package ninja_emit

import "core:strings"
import "core:fmt"

import "base:runtime"

Bin_Expr_Kind :: enum u8 {
	Unknown,
	Implicit,   // left |  right
	Order_Only, // left || right
	Validation, // left |@ right
}

Bin_Expr :: struct {
	kind: Bin_Expr_Kind,
	left, right: ^Expr
}

Expr_Collection :: struct {
	arr: []^Expr,
}

@(private="file") _Lazy_Tree_Expr :: struct {
	base: Lazy_Tree,
}
Lazy_Path_Expr :: distinct _Lazy_Tree_Expr
Lazy_Command_Expr :: distinct _Lazy_Tree_Expr

Int_Expr :: struct {
	base: union { i64, u64 },
}

String_Expr :: struct {
	base: string,
}

Expr :: union {
	Lazy_Path_Expr,
	Lazy_Command_Expr,
	Expr_Collection,
	Bin_Expr,
	Int_Expr,
	String_Expr,
}

sbprint_bin_expr :: proc(sb: ^strings.Builder, e: Bin_Expr) -> string {
	when !ODIN_NO_BOUNDS_CHECK do ensure(e.kind != .Unknown)
	sbprint_expr(sb, e.left^)
	switch e.kind {
		case .Unknown:    // Should be ignored
		case .Implicit:   strings.write_string(sb, " | ")
		case .Order_Only: strings.write_string(sb, " || ")
		case .Validation: strings.write_string(sb, " |@ ")
	}
	sbprint_expr(sb, e.right^)
	return strings.to_string(sb^)
}

sbprint_expr_collection :: proc(sb: ^strings.Builder, e: Expr_Collection) -> string {
	for expr, i in e.arr {
		fmt.sbprintf(sb, "%s%s", sbprint_expr(sb, expr^), i + 1 < len(e.arr) ? " " : "")
	}
	return strings.to_string(sb^)
}

sbprint_int_expr :: proc(sb: ^strings.Builder, e: Int_Expr) -> string {
	switch i in e.base {
		case i64: fmt.sbprintf(sb, "%d", i)
		case u64: fmt.sbprintf(sb, "%d", i)
	}
	return strings.to_string(sb^)
}

sbprint_string_expr :: proc(sb: ^strings.Builder, e: String_Expr) -> string {
	strings.write_string(sb, e.base)
	return strings.to_string(sb^)
}

sbprint_expr :: proc(sb: ^strings.Builder, e: Expr) -> string {
	switch internal in e {
		case Lazy_Path_Expr:     return sbprint_lazy_path(sb, internal.base)
		case Lazy_Command_Expr:  return sbprint_lazy_command(sb, internal.base)
		case Expr_Collection:    return sbprint_expr_collection(sb, internal)
		case String_Expr:        return sbprint_string_expr(sb, internal)
		case Bin_Expr:           return sbprint_bin_expr(sb, internal)
		case Int_Expr:           return sbprint_int_expr(sb, internal)
	}
	return strings.to_string(sb^)
}