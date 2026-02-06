package ninja_ir

import "core:mem"
import "core:slice"

Rule :: struct {
    name: string,
    pool: Maybe(Pool),
    command: Command
}

@private rule_make :: proc(ctx: ^IR_Context) -> (out: ^Rule, err: mem.Allocator_Error) #optional_allocator_error {
    out = new(Rule, allocator=ctx.allocator) or_return
    out.command = make(Command, allocator=ctx.allocator) or_return
    append(&ctx.rules, out) or_return
    return
}

rule_destroy :: proc(self: ^Rule, ctx: ^IR_Context, unregister := true) -> mem.Allocator_Error {
    if unregister {
        if i, found := slice.linear_search(ctx.rules[:], self); found {
            unordered_remove(&ctx.rules, i)
        }
    }
    delete(self.command) or_return
    free(self, allocator=ctx.allocator) or_return
    return nil
}

rule :: proc(ctx: ^IR_Context, name: string, pool: Maybe(Pool) = nil) -> (out: ^Rule, err: mem.Allocator_Error) #optional_allocator_error {
    out = rule_make(ctx) or_return
    out.name = name
    out.pool = pool
    return
}