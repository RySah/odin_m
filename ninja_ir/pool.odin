package ninja_ir

Non_Interactive_Pool :: struct {
    name: string,
    depth: u8
}

Interactive_Pool :: struct {}

Pool :: union {
    Non_Interactive_Pool,
    Interactive_Pool
}
