package ninja_ir

import "core:sys/posix"
import "core:c"

Cmd_Line_Limits :: struct {
    max_shell_char_count: u32
}

Limits :: struct {
    cmd_line: Cmd_Line_Limits
}

get_cmd_line_limits :: proc() -> (out: Cmd_Line_Limits) {
    WINDOWS_CMDLINE_SHELL_LIMIT :: 8192     // cmd.exe safe
when ODIN_OS == .Windows {
    
    //WINDOWS_CMDLINE_PROCESS_LIMIT :: 32767  // CreateProcessW

    out.max_shell_char_count = WINDOWS_CMDLINE_SHELL_LIMIT - 1
    //out.max_process_char_count = WINDOWS_CMDLINE_PROCESS_LIMIT - 1
} else when ODIN_OS == .Linux || ODIN_OS == .Darwin || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD || ODIN_OS == .FreeBSD || ODIN_OS == .Haiku {
    @static arg_max: c.long = 0
    @static arg_max_init := false
    if !arg_max_init {
        arg_max_init = true
        arg_max = posix.sysconf(._ARG_MAX)
    }
    out.max_shell_char_count = arg_max == -1 ? WINDOWS_CMDLINE_SHELL_LIMIT - 1 : u32(arg_max)
} else {
    out.max_shell_char_count = WINDOWS_CMDLINE_SHELL_LIMIT - 1
}
    return
}

get_limits :: proc() -> (out: Limits) {
    out.cmd_line = get_cmd_line_limits()
    return
}