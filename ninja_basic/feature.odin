package ninja_basic

Feature :: enum u8 {
	VERSION_COMPATIBILITY,
	DEPS,
	POOLS,
	CONSOLE_POOL,
	IMPLICIT_OUTPUTS,
	VALIDATIONS,
	DYNAMIC_DEP,
	RULE_SCOPING,
	RSP
}

Feature_Set :: bit_set[Feature]

feature_set_get_required_version :: proc(s: Feature_Set) -> (out: Version) {
	#unroll for feature in Feature {
		if feature in s {
			switch feature {
				case .VERSION_COMPATIBILITY:
					out = version_gt(VERSION_COMPATIBILITY_VERSION, out) ? VERSION_COMPATIBILITY_VERSION : out
				case .DEPS:
					out = version_gt(DEPS_VERSION, out) ? DEPS_VERSION : out
				case .POOLS:
					out = version_gt(POOLS_VERSION, out) ? POOLS_VERSION : out
				case .CONSOLE_POOL:
					out = version_gt(CONSOLE_POOL_VERSION, out) ? CONSOLE_POOL_VERSION : out
				case .IMPLICIT_OUTPUTS:
					out = version_gt(IMPLICIT_OUTPUTS_VERSION, out) ? IMPLICIT_OUTPUTS_VERSION : out
				case .VALIDATIONS:
					out = version_gt(VALIDATIONS_VERSION, out) ? VALIDATIONS_VERSION : out
				case .DYNAMIC_DEP:
					out = version_gt(DYNAMIC_DEP_VERSION, out) ? DYNAMIC_DEP_VERSION : out
				case .RULE_SCOPING:
					out = version_gt(RULE_SCOPING_VERSION, out) ? DYNAMIC_DEP_VERSION : out
				case .RSP:
					out = version_gt(RSP_VERSION, out) ? RSP_VERSION : out
			}
		}
	}
	return
}
features_get_required_version :: feature_set_get_required_version

version_get_feature_set :: proc(v: Version) -> (out: Feature_Set) {
	#unroll for feature in Feature {
		switch feature {
			case .VERSION_COMPATIBILITY:
				if version_lte(VERSION_COMPATIBILITY_VERSION, v) do out |= { feature }
			case .DEPS:
				if version_lte(DEPS_VERSION, v) do out |= { feature }
			case .POOLS:
				if version_lte(POOLS_VERSION, v) do out |= { feature }
			case .CONSOLE_POOL:
				if version_lte(CONSOLE_POOL_VERSION, v) do out |= { feature }
			case .IMPLICIT_OUTPUTS:
				if version_lte(IMPLICIT_OUTPUTS_VERSION, v) do out |= { feature }
			case .VALIDATIONS:
				if version_lte(VALIDATIONS_VERSION, v) do out |= { feature }
			case .DYNAMIC_DEP:
				if version_lte(DYNAMIC_DEP_VERSION, v) do out |= { feature }
			case .RULE_SCOPING:
				if version_lte(RULE_SCOPING_VERSION, v) do out |= { feature }
			case .RSP:
				if version_lte(RSP_VERSION, v) do out |= { feature }
		}
	}
	return
}
version_get_features :: version_get_feature_set