package ninja_ir

import "core:mem"
import "core:slice"
import vmem "core:mem/virtual"

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

@private file_make :: proc(ctx: ^IR_Context) -> (out: ^File, err: mem.Allocator_Error) #optional_allocator_error {
    out = new(File, allocator=vmem.arena_allocator(&ctx.arena)) or_return
    append(&ctx.files, out) or_return
    return
}

file_unregister :: proc(self: ^File, ctx: ^IR_Context) {
    if i, found := slice.linear_search(ctx.files[:], self); found {
        unordered_remove(&ctx.files, i)
    }
}

file :: proc(ctx: ^IR_Context, name: string, locations: File_Location_Set) -> (out: ^File, err: mem.Allocator_Error) #optional_allocator_error {
    out = file_make(ctx) or_return
    out.name = name
    out.locations = locations
    return
}
