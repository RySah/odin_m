package ninja_ir

import "core:mem"

IR_Context :: struct {
    limits: Limits,
    files: [dynamic]^File,
    rules: [dynamic]^Rule,
    execs: [dynamic]^Exec,
    allocator: mem.Allocator
}

ir_context_init :: proc(self: ^IR_Context, allocator := context.allocator) -> mem.Allocator_Error {
    self.limits = get_limits()
    self.allocator = allocator
    self.files = make([dynamic]^File, allocator=self.allocator) or_return
    self.rules = make([dynamic]^Rule, allocator=self.allocator) or_return
    self.execs = make([dynamic]^Exec, allocator=self.allocator) or_return
    return nil
}

ir_context_destroy :: proc(self: ^IR_Context) -> mem.Allocator_Error {
    for p in self.files {
        file_destroy(p, self, unregister=false) or_return
    }
    delete(self.files) or_return

    for p in self.rules {
        rule_destroy(p, self, unregister=false) or_return
    }
    delete(self.rules) or_return

    for p in self.execs {
        exec_destroy(p, self, unregister=false) or_return
    }
    delete(self.rules) or_return
    return nil
}
