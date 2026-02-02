package ninja_emit

import "core:mem"

Context :: struct {
    using _: Statement_Manager,
	cfg_svcache: Config_Shared_Virtual_Cache,
}

context_init :: proc(self: ^Context, allocator := context.allocator) -> mem.Allocator_Error {
    config_svcache_init(&self.cfg_svcache)
    statement_manager_init(self, allocator=allocator) or_return
    return nil
}

context_destroy :: proc(self: ^Context) -> mem.Allocator_Error {
    statement_manager_destroy(self) or_return
    return nil
}