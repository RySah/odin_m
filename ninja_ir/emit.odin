package ninja_ir

import "../ninja_emit"
import "../async"

import "core:mem"
import "core:slice"
import "core:io"
import vmem "core:mem/virtual"
import "core:strings"
import "core:os"
import "core:bufio"

import "base:runtime"

ir_context_to_emit_config :: proc(self: ^IR_Context, project_name: string) -> (out: ninja_emit.Config, err: mem.Allocator_Error) #optional_allocator_error {
    out = ninja_emit.config_make(allocator=vmem.arena_allocator(&self.arena)) or_return

    out.project_name = project_name

    pools: []Non_Interactive_Pool
    requires_interactive_pool: bool
    when async.IS_SUPPORTED {{
        async_dispatcher: async.Dispatcher
        async.init(&async_dispatcher, 2) or_return
        defer async.destroy(&async_dispatcher)

        pools_promise := async.run(&async_dispatcher,
            proc(params: ..any) -> (out: struct{ items: []Non_Interactive_Pool, requires_interactive: bool,  err: mem.Allocator_Error }) {
                self: ^IR_Context
                allocator: runtime.Allocator
                #type_assert {
                    self = params[0].(^IR_Context)
                    allocator = params[1].(runtime.Allocator)
                }

                pool_map := make(map[string]Non_Interactive_Pool, allocator=context.temp_allocator)

                for rule in self.rules {
                    if pool_impl, assigned_pool := rule.pool.?; assigned_pool {
                        switch internal_pool_impl in pool_impl {
                            case Non_Interactive_Pool:
                                if internal_pool_impl.name in pool_map do continue
                                pool_map[internal_pool_impl.name] = internal_pool_impl
                            case Interactive_Pool:
                                out.requires_interactive = true
                        }
                    }
                }

                out.items, out.err = slice.map_values(pool_map, allocator=allocator)
                return
            },
            self, context.temp_allocator,
            allocator=context.temp_allocator
        ) or_return

        variables_assign_promise := async.run(&async_dispatcher,
            proc(params: ..any) {
                self: ^IR_Context
                out: ^ninja_emit.Config
                #type_assert {
                    self = params[0].(^IR_Context)
                    out = params[1].(^ninja_emit.Config)
                }

                for k, &v in self.variables {
                    append(&out.variables, ninja_emit.Variable{
                        name = k,
                        expr = _variable_expr_to_emit_expr(&v, allocator=vmem.arena_allocator(&self.arena))
                    })
                }
            },
            self, &out,
            allocator=context.temp_allocator
        ) or_return

        pools_result := async.await(pools_promise)
        if pools_result.err != nil do return out, pools_result.err

        async.await(variables_assign_promise)

        pools = pools_result.items
        requires_interactive_pool = pools_result.requires_interactive
    }} else {{
        pool_map := make(map[string]Pool, allocator=context.temp_allocator)

        for rule in self.rules {
            if pool_impl, assigned_pool := rule.pool.?; assigned_pool {
                switch internal_pool_impl in pool_impl {
                    case Non_Interactive_Pool:
                        if internal_pool_impl.name in pool_map do continue
                        pool_map[internal_pool_impl.name] = internal_pool_impl
                    case Interactive_Pool:
                        requires_interactive_pool = true
                }
            }
        }

        pools = slice.map_values(pool_map, allocator=context.temp_allocator) or_return

        for k, &v in self.variables {
            append(&out.variables, ninja_emit.Variable{
                name = k,
                expr = _variable_expr_to_emit_expr(&v, allocator=vmem.arena_allocator(&self.arena))
            })
        }
    }}

    if requires_interactive_pool {
        out.required_features |= { .CONSOLE_POOL }
    }

    for &pool in pools {
        stmt := ninja_emit.create_statement(&out) or_return
        stmt.kind = .Pool
        stmt.left = pool.name
        append(&stmt.variables, ninja_emit.Variable{
            name="depth",
            expr=ninja_emit.to_int_expr(pool.depth)
        }) or_return
        ninja_emit.register_statement(&out, stmt) or_return
    }

    for &rule in self.rules {
        stmt := ninja_emit.create_statement(&out) or_return
        stmt.kind = .Rule
        stmt.left = rule.name
        command_expr := _command_to_emit_expr(&rule.command, allocator=vmem.arena_allocator(&self.arena)) or_return
        append(&stmt.variables, ninja_emit.Variable{
            name="command",
            expr=command_expr
        }) or_return
        if len(rule.desc) > 0 {
            description_expr := _command_to_emit_expr(transmute(^Command)(&rule.desc), allocator=vmem.arena_allocator(&self.arena)) or_return
            append(&stmt.variables, ninja_emit.Variable{
                name="description",
                expr=description_expr
            }) or_return
        }
        if pool_impl, has_pool := rule.pool.?; has_pool {
            switch internal_pool_impl in pool_impl {
                case Non_Interactive_Pool:
                    append(&stmt.variables, ninja_emit.Variable{
                        name="pool",
                        expr=internal_pool_impl.name
                    }) or_return
                case Interactive_Pool:
                    append(&stmt.variables, ninja_emit.Variable{
                        name="pool",
                        expr="console"
                    }) or_return
            }
        }
        for k, &v in rule.variables {
            append(&stmt.variables, ninja_emit.Variable{
                name = k,
                expr = _variable_expr_to_emit_expr(&v, allocator=vmem.arena_allocator(&self.arena))
            })
        }
        ninja_emit.register_statement(&out, stmt) or_return
    }

    return
}

ir_context_wprint :: proc(writer: io.Writer, self: ^IR_Context, project_name: string) -> mem.Allocator_Error {
    emit_config := ir_context_to_emit_config(self, project_name) or_return
    
    ninja_emit.config_resolve_required_features(&emit_config, skip=emit_config.required_features) or_return
    ninja_emit.wprint_config(writer, &emit_config) or_return
    return nil
}
ir_context_sbprint :: proc(sb: ^strings.Builder, self: ^IR_Context, project_name: string) -> mem.Allocator_Error {
    emit_config := ir_context_to_emit_config(self, project_name) or_return
    
    ninja_emit.config_resolve_required_features(&emit_config, skip=emit_config.required_features) or_return
    ninja_emit.sbprint_config(sb, &emit_config) or_return
    return nil
}
ir_context_fprint :: proc(fd: os.Handle, self: ^IR_Context, project_name: string) -> mem.Allocator_Error {
    emit_config := ir_context_to_emit_config(self, project_name) or_return
    buf: [1024]byte
	b: bufio.Writer
	defer bufio.writer_flush(&b)

	bufio.writer_init_with_buf(&b, os.stream_from_handle(fd), buf[:])

	w := bufio.writer_to_writer(&b)

    ninja_emit.config_resolve_required_features(&emit_config, skip=emit_config.required_features) or_return
    ninja_emit.wprint_config(w, &emit_config) or_return
    return nil
}
ir_context_emit :: proc{
    ir_context_wprint,
    ir_context_sbprint,
    ir_context_fprint
}