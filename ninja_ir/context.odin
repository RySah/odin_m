package ninja_ir

import "core:mem"
import vmem "core:mem/virtual"

IR_Context :: struct {
    //limits: Limits,
    rules: [dynamic]^Rule,
    execs: [dynamic]^Exec,
    builds: [dynamic]^Build,
    variables: map[string]Rule_Variable_Expr,
    arena: vmem.Arena,
    container_allocator: mem.Allocator
}

ir_context_init :: proc(self: ^IR_Context, allocator := context.allocator) -> mem.Allocator_Error {
    //self.limits = get_limits()
    vmem.arena_init_growing(&self.arena) or_return
    self.container_allocator = allocator
    self.rules = make([dynamic]^Rule, allocator=self.container_allocator) or_return
    self.execs = make([dynamic]^Exec, allocator=self.container_allocator) or_return
    self.variables = make(map[string]Rule_Variable_Expr, allocator=self.container_allocator)
    return nil
}

ir_context_destroy :: proc(self: ^IR_Context) -> mem.Allocator_Error {
    for &rule in self.rules {
        rule_destroy(rule) or_return
    }
    for &build in self.builds {
        build_destroy(build) or_return
    }

    delete(self.rules) or_return
    delete(self.execs) or_return
    delete(self.variables) or_return
    vmem.arena_destroy(&self.arena)
    return nil
}
