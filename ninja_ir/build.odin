package ninja_ir

import "core:mem"
import vmem "core:mem/virtual"
import "core:slice"

Build :: struct {
    name: string,
    pool: Maybe(Pool),
    variables: map[string]Build_Variable_Expr,
    parents: [dynamic]^Build
}

@private build_make :: proc(ctx: ^IR_Context) -> (out: ^Build, err: mem.Allocator_Error) #optional_allocator_error {
    out = new(Build, allocator=vmem.arena_allocator(&ctx.arena)) or_return
    out.variables = make(map[string]Build_Variable_Expr, allocator=ctx.container_allocator)
    out.parents = make([dynamic]^Build, allocator=ctx.container_allocator)
    append(&ctx.builds, out) or_return
    return
}

build_unregister :: proc(self: ^Build, ctx: ^IR_Context) {
    if i, found := slice.linear_search(ctx.builds[:], self); found {
        unordered_remove(&ctx.builds, i)
    }
}

build_destroy :: proc(self: ^Build) -> mem.Allocator_Error {
    delete(self.variables) or_return
    delete(self.parents) or_return
    return nil
}

build :: proc(ctx: ^IR_Context, name: string, pool: Maybe(Pool) = nil) -> (out: ^Build, err: mem.Allocator_Error) #optional_allocator_error {
    out = build_make(ctx) or_return
    out.name = name
    out.pool = pool
    return
}
