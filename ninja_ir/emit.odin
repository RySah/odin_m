package ninja_ir

import "../ninja_emit"
import "../async"

import "core:mem"
import "core:slice"
import "core:sync"

import "base:runtime"

to_emit_config :: proc(ctx: ^IR_Context, project_name: string, allocator := context.allocator) -> (out: ninja_emit.Config, err: mem.Allocator_Error) #optional_allocator_error {
    out = ninja_emit.config_make(allocator=allocator) or_return

    out.project_name = project_name

    pools: []Pool

    when async.IS_SUPPORTED {{
        async_dispatcher: async.Dispatcher
        async.init(&async_dispatcher, 4) or_return
        defer async.destroy(&async_dispatcher)

        pools_promise := async.run(&async_dispatcher,
            proc(params: ..any) -> (out: struct{ items: []Pool, err: mem.Allocator_Error }) {
                ctx: ^IR_Context
                allocator: runtime.Allocator
                #type_assert {
                    ctx = params[0].(^IR_Context)
                    allocator = params[1].(runtime.Allocator)
                }

                pool_map := make(map[string]Pool, allocator=context.temp_allocator)

                for rule in ctx.rules {
                    if pool_impl, assigned_pool := rule.pool.?; assigned_pool {
                        if pool_impl.name in pool_map do continue
                        pool_map[pool_impl.name] = pool_impl
                    }
                }

                out.items, out.err = slice.map_values(pool_map, allocator=allocator)
                return
            },
            ctx, context.temp_allocator,
            allocator = context.temp_allocator
        ) or_return

        pools_result := async.await(pools_promise)
        if pools_result.err != nil do return out, pools_result.err

        pools = pools_result.items
    }} else {{
        pool_map := make(map[string]Pool, allocator=context.temp_allocator)

        for rule in ctx.rules {
            if pool_impl, assigned_pool := rule.pool.?; assigned_pool {
                if pool_impl.name in pool_map do continue
                pool_map[pool_impl.name] = pool_impl
            }
        }

        pools = slice.map_values(pool_map, allocator=context.temp_allocator) or_return
    }}

    for &pool in pools {
        stmt := ninja_emit.create_statement(&out) or_return
        stmt.kind = .Pool
        stmt.left = pool.name
        ninja_emit.statement_add_variable(&stmt, ninja_emit.Variable{
            name="depth",
            expr=ninja_emit.to_int_expr(pool.depth)
        }) or_return
    }

    for rule in ctx.rules {
        stmt := ninja_emit.create_statement(&out) or_return
        stmt.kind = .Rule
        stmt.left = rule.name
        
    }

    return
}
