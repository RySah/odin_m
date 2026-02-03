package ninja_emit

import "../ninja_basic"

import "core:strings"
import "core:mem"

Feature :: ninja_basic.Feature
Feature_Set :: ninja_basic.Feature_Set

Version :: ninja_basic.Version
Statement_Kind :: ninja_basic.Statement_Kind

version_gt :: ninja_basic.version_gt
version_lt :: ninja_basic.version_lt
version_gte :: ninja_basic.version_gte
version_lte :: ninja_basic.version_lte

VERSION_COMPATIBILITY_VERSION :: ninja_basic.VERSION_COMPATIBILITY_VERSION
DEPS_VERSION :: ninja_basic.DEPS_VERSION
POOLS_VERSION :: ninja_basic.POOLS_VERSION
CONSOLE_POOL_VERSION :: ninja_basic.CONSOLE_POOL_VERSION
IMPLICIT_OUTPUTS_VERSION :: ninja_basic.IMPLICIT_OUTPUTS_VERSION
VALIDATIONS_VERSION :: ninja_basic.VALIDATIONS_VERSION
DYNAMIC_DEP_VERSION :: ninja_basic.DYNAMIC_DEP_VERSION
RULE_SCOPING_VERSION :: ninja_basic.RULE_SCOPING_VERSION

MAX_VERSION :: ninja_basic.MAX_VERSION

// Strings are allocated at `left`, `right` and `variables`(specifically at the value component)
statement_to_basic_statement :: proc(self: ^Statement, allocator := context.allocator) -> 
(out: ninja_basic.Statement, err: mem.Allocator_Error) #optional_allocator_error {
    out = ninja_basic.statement_make(allocator=allocator)

    builder := strings.builder_make(allocator=context.temp_allocator) or_return

    out.kind = self.kind
    out.left = strings.clone(sbprint_expr(&builder, self.left), allocator=allocator) or_return
    strings.builder_reset(&builder)
    out.right = strings.clone(sbprint_expr(&builder, self.right), allocator=allocator) or_return
    strings.builder_reset(&builder)
    
    for &var in self.variables {
        out.variables[var.name] = strings.clone(sbprint_expr(&builder, var.expr), allocator=allocator) or_return
        strings.builder_reset(&builder)
    }
    return
}

config_to_basic_config :: proc(self: ^Config, allocator := context.allocator) ->
(out: ninja_basic.Config, err: mem.Allocator_Error) #optional_allocator_error {
    out = ninja_basic.config_make(allocator=allocator) or_return

    builder := strings.builder_make(allocator=context.temp_allocator) or_return

    out.required_version = ninja_basic.features_get_required_version(self.required_features)
    for &var in self.variables {
        out.variables[var.name] = strings.clone(sbprint_expr(&builder, var.expr), allocator=allocator) or_return
        strings.builder_reset(&builder)
    }

    for &stmt in self.statements {
        append(&out.statements, statement_to_basic_statement(&stmt, allocator=allocator) or_return) or_return 
    }

    return
}