package ninja_ir

Rule :: struct {
    using handle: ID_Handle,
    name: string,
    pool: ID,
    allows_response_file: bool,
    response_file_formatter: Response_File_Formatter_Proc
}

rule_init :: proc(ctx: ^IR_Context, self: ^Rule) {
    if self.id == Invalid_ID {
        assign_id(ctx, self)
    }
    self.response_file_formatter = default_response_file_formatter_proc
}

rule_destroy :: proc(ctx: ^IR_Context, self: ^Rule) {
    free_id(ctx, self)
}