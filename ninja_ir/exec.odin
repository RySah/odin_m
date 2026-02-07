package ninja_ir

import "core:mem"
import "core:slice"
import vmem "core:mem/virtual"

Exec_Response_File_Info :: struct {
    file: Response_File,
    content: Response_File_Content
}

Exec :: struct {
    file: File,
    rsp_info: Maybe(Exec_Response_File_Info)
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
    file: File, 
    rsp_info: Maybe(Exec_Response_File_Info) = nil,
    loc := #caller_location
) -> (out: ^Exec, err: mem.Allocator_Error) #optional_allocator_error {
    out = exec_make(ctx) or_return
    out.file = file
    out.rsp_info = rsp_info
    return
}