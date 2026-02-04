package ninja_emit

import "../ninja_basic"

import "core:strings"
import "core:io"
import "core:mem"

wprint_config :: proc(writer: io.Writer, self: ^Config) -> mem.Allocator_Error {
    basic := config_to_basic_config(self, allocator=context.temp_allocator) or_return
    ninja_basic.wprint_config(writer, &basic)
    return nil
}

sbprint_config :: proc(sb: ^strings.Builder, self: ^Config) -> (output: string, err: mem.Allocator_Error) #optional_allocator_error {
    wprint_config(strings.to_writer(sb), self) or_return
    return strings.to_string(sb^), nil
}
