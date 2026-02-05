package ninja_ir

import "core:mem"
import "core:slice"

File_Location :: enum u8 {
    Local,
    Env
}

File_Location_Set :: bit_set[File_Location]

File :: struct {
    // For cross compatibility, ensure this is NOT absolute
    name: string,
    locations: File_Location_Set
}

file_init :: proc(ctx: ^IR_Context) -> (out: ^File, err: mem.Allocator_Error) #optional_allocator_error {
    out = new(File, allocator=ctx.allocator) or_return
    append(&ctx.files, out) or_return
    return
}

file_destroy :: proc(self: ^File, ctx: ^IR_Context) -> mem.Allocator_Error {
    if i, found := slice.linear_search(ctx.files[:], self); found {
        unordered_remove(&ctx.files, i)
    }
    free(self, allocator=ctx.allocator) or_return
    return nil
}
