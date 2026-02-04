package ninja_ir

import "core:mem"

IR_Context :: struct {
    limits: Limits,
    using id_gen: ID_Generator
}

ir_context_init :: proc(self: ^IR_Context, allocator := context.allocator) -> mem.Allocator_Error {
    self.limits = get_limits()
    id_generator_init(self, allocator=allocator) or_return
    return nil
}

ir_context_destroy :: proc(self: ^IR_Context) -> mem.Allocator_Error {
    id_generator_destroy(self) or_return
    return nil
}

