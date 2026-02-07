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
        ar_rule, err = ninja_ir.rule(&ir, "ar", pool=ninja_ir.Interactive_Pool{})
        error_prop(err)
    }

    ar_rule.variables["command"] = ninja_ir.Rule_Command{
        "rm", "-f", ninja_ir.Special_Variable.Out, "&&", 
        ninja_ir.Variable_Access{ Rule_Command_Token="ar" }, "crs", ninja_ir.Special_Variable.Out, ninja_ir.Special_Variable.In
    }
    ar_rule.variables["description"] = ninja_ir.Rule_Command{ "AR", ninja_ir.Special_Variable.Out }

    error_prop(ninja_ir.ir_context_emit(os.stdout, &ir, "test"))

}