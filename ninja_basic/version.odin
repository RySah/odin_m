package ninja_basic

Version :: [2]u8

version_gt :: proc(a, b: Version) -> bool {
	if a.x > b.x do return true
	if a.x == b.x && a.y > b.y do return true
	return false
}
version_lt :: proc(a, b: Version) -> bool {
	return !version_gt(a, b)
}
version_gte :: proc(a, b: Version) -> bool {
	return (a.x == b.x && a.y == b.y) || version_gt(a, b)
}
version_lte :: proc(a, b: Version) -> bool {
	return (a.x == b.x && a.y == b.y) || version_lt(a, b)
}

VERSION_COMPATIBILITY_VERSION :: Version{ 1, 2 }
DEPS_VERSION :: Version{ 1, 3 }
POOLS_VERSION :: Version{ 1, 1 }
CONSOLE_POOL_VERSION :: Version{ 1, 5 }
IMPLICIT_OUTPUTS_VERSION :: Version{ 1, 7 }
VALIDATIONS_VERSION :: Version{ 1, 11 }
DYNAMIC_DEP_VERSION :: Version{ 1, 10 }
RULE_SCOPING_VERSION :: Version{ 1, 6 }

MAX_VERSION :: Version{ 255, 255 }