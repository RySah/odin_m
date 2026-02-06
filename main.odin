// odin build . -export-dependencies-file:dependencies.d -export-dependencies:json
package main

import "ninja_ir"

import "core:strings"
import "core:fmt"
import "core:mem"
import "core:os"

error_prop :: proc(err: $E, loc := #caller_location) {
    if err != nil {
        fmt.panicf("%v: %v", loc, err)
    }
}

/*
rule ar
  command = rm -f $out && $ar crs $out $in
  description = AR $out
*/

main :: proc() {
    ir: ninja_ir.IR_Context
    error_prop(ninja_ir.ir_context_init(&ir))
    defer ninja_ir.ir_context_destroy(&ir)

    ir.variables["ar"] = "ar"

    ar_rule: ^ninja_ir.Rule
    {
        err: mem.Allocator_Error
        ar_rule, err = ninja_ir.rule(&ir, "ar", pool=ninja_ir.Pool{
            name="some_pool",
            depth=3
        })
        error_prop(err)
    }

    append(&ar_rule.command,
        "rm", "-f", ninja_ir.Special_Variable.Out, "&&", 
        ninja_ir.Variable_Access{ name="ar" }, "crs", ninja_ir.Special_Variable.Out, ninja_ir.Special_Variable.In
    )
    append(&ar_rule.desc,
        "AR", ninja_ir.Special_Variable.Out
    )

    error_prop(ninja_ir.ir_context_emit(os.stdout, &ir, "test"))

}