package ninja_ir

import "core:mem"
import "core:fmt"

Response_File_Formatter_Proc :: #type proc(path: string, allocator: mem.Allocator) -> string

default_win32_response_file_formatter_proc : Response_File_Formatter_Proc : proc(
    path: string, allocator := context.allocator
) -> string {
    return fmt.aprintf("@%s", path, allocator=allocator)
}

// NOTE(rysah): Format doesnt only apply to windows systems, and will may work for other systems.
default_response_file_formatter_proc :: default_win32_response_file_formatter_proc