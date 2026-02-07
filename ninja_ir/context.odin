package ninja_ir

import "core:mem"
import vmem "core:mem/virtual"

IR_Context :: struct {
    //limits: Limits,
    files: [dynamic]^File,
    rules: [dynamic]^Rule,
    execs: [dynamic]^Exec,
    variables: map[string]Variable_Expr,
    arena: vmem.Arena
}

ir_context_init :: proc(self: ^IR_Context) -> mem.Allocator_Error {
    //self.limits = get_limits()
    vmem.arena_init_growing(&self.arena) or_return
    allocator := vmem.arena_allocator(&self.arena)
    self.files = make([dynamic]^File, allocator=allocator) or_return
    self.rules = make([dynamic]^Rule, allocator=allocator) or_return
    self.execs = make([dynamic]^Exec, allocator=allocator) or_return
    self.variables = make(map[string]Variable_Expr, allocator=allocator)
    return nil
}

ir_context_destroy :: proc(self: ^IR_Context) {
    vmem.arena_destroy(&self.arena)
}
