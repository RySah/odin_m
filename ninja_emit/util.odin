package ninja_emit

rune_in_number_ascii_range :: proc(r: rune) -> bool {
	return (r >= 48 && r <= 57) /* 0..9 */
}

rune_in_ident_ascii_range :: proc(r: rune) -> bool {
	return r == 45 /* - */ || r == 46 /* . */ || rune_in_number_ascii_range(r) || (r >= 65 && r <= 90) /* A..Z */ || (r >= 97 && r <= 122) /* a..z */
}

u8_in_number_ascii_range :: proc(r: u8) -> bool {
	return (r >= 48 && r <= 57) /* 0..9 */
}

u8_in_ident_ascii_range :: proc(r: u8) -> bool {
	return r == 45 /* - */ || r == 46 /* . */ || u8_in_number_ascii_range(r) || (r >= 65 && r <= 90) /* A..Z */ || (r >= 97 && r <= 122) /* a..z */
}

in_number_ascii_range :: proc{rune_in_number_ascii_range,u8_in_number_ascii_range}
in_ident_ascii_range :: proc{rune_in_ident_ascii_range,u8_in_ident_ascii_range}

// Valid identifiers would be considered [A–Z], [a–z], [0–9], underscore (_), dot (.), hyphen (-)
// Where it cannot start with a [0-9] for safety.


is_ident :: proc(s: string) -> bool {
	when !ODIN_NO_BOUNDS_CHECK do ensure(len(s) > 0)
	if in_number_ascii_range(s[0]) do return false
	for r in s {
		if !in_ident_ascii_range(r) do return false
	}
	return true
}