package ninja_ir

import "core:mem"

Rule :: struct {
    using _: ID_Handle,
    name: string,
    pool: ID,
    command: Lazy_Command,
    allows_response_file: bool,
    response_file_formatter: Response_File_Formatter_Proc
}

rule_init :: proc(ctx: ^IR_Context, self: ^Rule) -> mem.Allocator_Error {
    if self.id == Invalid_ID {
        assign_id(ctx, self)
    }
    self.command = make(Lazy_Command, allocator=ctx.allocator) or_return
    self.response_file_formatter = default_response_file_formatter_proc
    return nil
}

rule_destroy :: proc(ctx: ^IR_Context, self: ^Rule) -> mem.Allocator_Error {
    free_id(ctx, self)
    delete(self.command) or_return
    return nil
}
