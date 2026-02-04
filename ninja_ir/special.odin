package ninja_ir

Special_Variable :: enum u8 {
    Command,
    Dep_File,
    Deps,
    Desc,
    Dynamic_Dep,
    In,
    In_Newline,
    Out
}

special_variable_len :: proc(v: Special_Variable) -> int {
    switch v {
        case .Command:     return len("command")
        case .Dep_File:    return len("depfile")
        case .Deps:        return len("deps")
        case .Desc:        return len("description")
        case .Dynamic_Dep: return len("dyndep")
        case .In:          return len("in")
        case .In_Newline:  return len("in_newline")
        case .Out:         return len("out")
    }
    unreachable()
}
