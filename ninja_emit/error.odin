package ninja_emit

import "core:fmt"
import "core:strings"

import "base:runtime"

Error_Level :: enum u8 {
	Warning,
	Fatal
}

Error :: struct {
	level: Error_Level,
	message: string
}

as_warning :: proc(err: Error) -> (out: Error) {
	out = err
	out.level = .Warning
	return
}

base_error :: proc(format: string, args: ..any, source_loc: Maybe(runtime.Source_Code_Location) = nil, allocator := context.allocator) -> (out: Error) {
	if len(format) == 0 {
		if loc, exists := source_loc.?; exists {
			out.message = fmt.aprintf("%v", loc, allocator=allocator)
		} else {
			out.message = strings.clone("", allocator=allocator)
		}
	} else {
		if loc, exists := source_loc.?; exists {
			out.message = fmt.aprintf("%v %s", loc, fmt.tprintf(format, ..args), allocator=allocator)
		} else {
			out.message = fmt.aprintf(format, ..args, allocator=allocator)
		}
	}
	out.level = .Fatal
	return
}

error :: proc(format: string, args: ..any, source_loc: Maybe(runtime.Source_Code_Location) = nil, allocator := context.allocator) -> Error {
	if len(format) == 0 {
		return base_error("Error", source_loc=source_loc, allocator=allocator)
	} else {
		return base_error("Error: %s", fmt.tprintf(format, ..args), source_loc=source_loc, allocator=allocator)
	}
}

syntax_error :: proc(format: string, args: ..any, source_loc: Maybe(runtime.Source_Code_Location) = nil, allocator := context.allocator) -> Error {
	if len(format) == 0 {
		return base_error("Syntax Error", source_loc=source_loc, allocator=allocator)
	} else {
		return base_error("Syntax Error: %s", fmt.tprintf(format, ..args), source_loc=source_loc, allocator=allocator)
	}
}

logic_error :: proc(format: string, args: ..any, source_loc: Maybe(runtime.Source_Code_Location) = nil, allocator := context.allocator) -> Error {
	if len(format) == 0 {
		return base_error("Logic Error", source_loc=source_loc, allocator=allocator)
	} else {
		return base_error("Logic Error: %s", fmt.tprintf(format, ..args), source_loc=source_loc, allocator=allocator)
	}
}

variable_access_ident_syntax_error_in_lazy_path :: proc(p: Lazy_Path, ident: string, source_loc: Maybe(runtime.Source_Code_Location) = nil, allocator := context.allocator) -> Error {
	return syntax_error(
		"`%s` Variable access identifier (`%s`) is invalid. Expected format \'[A-Za-z_.-][A-Za-z0-9_.-]*\'.",
		lazy_path_resolve(p, allocator=context.temp_allocator),
		ident,
		source_loc=source_loc,
		allocator=allocator
	)
}

variable_access_ident_logic_error_in_lazy_path :: proc(p: Lazy_Path, ident: string, source_loc: Maybe(runtime.Source_Code_Location) = nil, allocator := context.allocator) -> Error {
	return logic_error(
		"`%s` Variable access identifier (`%s`) could not be found.",
		lazy_path_resolve(p, allocator=context.temp_allocator),
		ident,
		source_loc=source_loc,
		allocator=allocator
	)
}