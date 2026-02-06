package ninja_emit

import "core:strings"
import "core:fmt"

import "base:intrinsics"

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

Expr_Collection :: []^Expr

Int_Expr :: union { i64, u64 }

String_Expr :: string

Expr :: union {
	Expr_Collection,
	Bin_Expr,
	Int_Expr,
	String_Expr,
}

to_int_expr :: proc(v: $T) -> Int_Expr where intrinsics.type_is_integer(T) {
	#assert(size_of(T) <= size_of(u64))
	when intrinsics.type_is_unsigned(T) {
		return u64(v)
	} else {
		return i64(v)
	}
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
	for expr, i in e {
		sbprint_expr(sb, expr^)
		if i + 1 < len(e) {
			strings.write_byte(sb, ' ')
		}
	}
	return strings.to_string(sb^)
}

sbprint_int_expr :: proc(sb: ^strings.Builder, e: Int_Expr) -> string {
	switch i in e {
		case i64: fmt.sbprintf(sb, "%d", i)
		case u64: fmt.sbprintf(sb, "%d", i)
	}
	return strings.to_string(sb^)
}

sbprint_string_expr :: proc(sb: ^strings.Builder, e: String_Expr) -> string {
	strings.write_string(sb, e)
	return strings.to_string(sb^)
}

sbprint_expr :: proc(sb: ^strings.Builder, e: Expr) -> string {
	#partial switch &internal in e {
		case Expr_Collection:    return sbprint_expr_collection(sb, internal)
		case Bin_Expr:           return sbprint_bin_expr(sb, internal)
		case Int_Expr:           return sbprint_int_expr(sb, internal)
		case String_Expr:        return sbprint_string_expr(sb, internal)
	}
	unreachable()
	//return strings.to_string(sb^)
}