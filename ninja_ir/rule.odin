package ninja_ir

import "core:mem"
import "core:slice"
import vmem "core:mem/virtual"

Rule :: struct {
    name: string,
    pool: Maybe(Pool),
    command: Command,
    desc: Description,
    //variables: map[string]Variable_Expr
}

@private rule_make :: proc(ctx: ^IR_Context) -> (out: ^Rule, err: mem.Allocator_Error) #optional_allocator_error {
    out = new(Rule, allocator=vmem.arena_allocator(&ctx.arena)) or_return
    out.command = make(Command, allocator=vmem.arena_allocator(&ctx.arena)) or_return
    out.desc = make(Description, allocator=vmem.arena_allocator(&ctx.arena)) or_return
    //out.variables = make(map[string]Variable_Expr, allocator=vmem.arena_allocator(&ctx.arena))
    append(&ctx.rules, out) or_return
    return
}

rule_unregister :: proc(self: ^Rule, ctx: ^IR_Context) {
    if i, found := slice.linear_search(ctx.rules[:], self); found {
        unordered_remove(&ctx.rules, i)
    }
}

rule :: proc(ctx: ^IR_Context, name: string, pool: Maybe(Pool) = nil) -> (out: ^Rule, err: mem.Allocator_Error) #optional_allocator_error {
    out = rule_make(ctx) or_return
    out.name = name
    out.pool = pool
    return
}