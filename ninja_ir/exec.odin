package ninja_ir

import "core:mem"
import "core:slice"
import vmem "core:mem/virtual"

Exec :: struct {
    file: ^File,
    allows_response_file: bool,
    response_file_formatter: Response_File_Formatter_Proc
}

@private exec_make :: proc(ctx: ^IR_Context) -> (out: ^Exec, err: mem.Allocator_Error) #optional_allocator_error {
    out = new(Exec, allocator=vmem.arena_allocator(&ctx.arena)) or_return
    append(&ctx.execs, out) or_return
    return
}

exec_unregister :: proc(self: ^Exec, ctx: ^IR_Context) {
    if i, found := slice.linear_search(ctx.execs[:], self); found {
        unordered_remove(&ctx.execs, i)
    }
}

exec :: proc(
    ctx: ^IR_Context, 
    file: ^File, 
    response_file_formatter: Maybe(Response_File_Formatter_Proc) = nil,
    loc := #caller_location
) -> (out: ^Exec, err: mem.Allocator_Error) #optional_allocator_error {
    out = exec_make(ctx) or_return
    out.file = file
    if response_file_formatter_v, provided := response_file_formatter.?; provided {
        assert(response_file_formatter_v != nil, loc=loc)
        out.allows_response_file = true
        out.response_file_formatter = response_file_formatter_v
    } else {
        out.allows_response_file = false
        out.response_file_formatter = default_response_file_formatter_proc
    }
    return
}