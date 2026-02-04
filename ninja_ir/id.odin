package ninja_ir

import "core:mem"

ID :: distinct u32

Invalid_ID : ID : 0

ID_Handle :: struct {
    id: ID
}

ID_Generator :: struct {
    curr_id: ID,
    freed_ids: [dynamic]ID
}

id_generator_init :: proc(self: ^ID_Generator, allocator := context.allocator) -> mem.Allocator_Error {
    self.curr_id = Invalid_ID + 1 // Starting off with a valid ID
    self.freed_ids = make([dynamic]ID, allocator=allocator) or_return
    return nil
}

id_generator_destroy :: proc(self: ^ID_Generator) -> mem.Allocator_Error {
    delete(self.freed_ids) or_return
    return nil
}

next_id :: proc(self: ^ID_Generator) -> (out: ID) {
    if len(self.freed_ids) > 0 {
        out = pop(&self.freed_ids)
        return
    }
    out = self.curr_id
    self.curr_id += 1
    return
}

assign_id_object :: proc(self: ^ID_Generator, out: ^ID) {
    out^ = next_id(self)
}
assign_id_handle :: proc(self: ^ID_Generator, out: ^ID_Handle) {
    assign_id_object(self, &out.id)
}
assign_id :: proc{assign_id_object,assign_id_handle}

free_id_object :: proc(self: ^ID_Generator, id: ID, loc := #caller_location) {
    when !ODIN_NO_BOUNDS_CHECK do ensure(id != Invalid_ID, loc=loc)
    append(&self.freed_ids, id)
}
free_id_handle :: proc(self: ^ID_Generator, handle: ^ID_Handle, loc := #caller_location) {
    free_id_object(self, handle.id, loc=loc)
}
free_id :: proc{free_id_object,free_id_handle}
