package ninja_ir

import "core:mem"
import "core:slice"

Rule :: struct {
    name: string,
    pool: ^Pool,
    command: Command,

    allows_response_file: bool,
    response_file_formatter: Response_File_Formatter_Proc
}

rule_init :: proc(ctx: ^IR_Context) -> (out: ^Rule, err: mem.Allocator_Error) #optional_allocator_error {
    out = new(Rule, allocator=ctx.allocator) or_return
    out.command = make(Command, allocator=ctx.allocator) or_return
    append(&ctx.rules, out) or_return
    return
}

rule_destroy :: proc(self: ^Rule, ctx: ^IR_Context) -> mem.Allocator_Error {
    if i, found := slice.linear_search(ctx.rules[:], self); found {
        unordered_remove(&ctx.rules, i)
    }
    delete(self.command) or_return
    free(self, allocator=ctx.allocator) or_return
    return nil
}
