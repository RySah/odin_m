package ninja_emit

import "core:strings"
import "core:fmt"

Variable :: struct {
	name: string,
	expr: Expr
}

sbprint_variable :: proc(sb: ^strings.Builder, v: Variable) -> string {
	fmt.sbprintf(sb, "%s = ", v.name)
	return sbprint_expr(sb, v.expr)
}