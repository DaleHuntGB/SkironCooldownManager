local SCM = select(2, ...)

SCM.Constants.PROFILES = {
	PREFIX = "SCM",
	DATA_VERSION = 1,
	PAYLOAD_VERSION = 2,

	ANCHOR_KEYS = {
		anchorConfig = true,
		buffBarsAnchorConfig = true,
	},

	INCLUDE_OPTIONS = {
		{ key = "includeIcons", label = "Include Icons/Bars" },
		{ key = "includeGlobalAnchors", label = "Global Icon Anchors" },
		{ key = "includeGlobalSettings", label = "Global Settings" },
		{ key = "includeResourceBar", label = "Resource Bar Settings" },
		{ key = "includeCastBar", label = "Cast Bar Settings" },
	},

	EXPORT_TYPE = {
		ALL = 0,
		CLASS = 1,
		GLOBAL_SETTINGS = 2,
		GLOBAL_ANCHORS = 3,
		EVERYTHING = 4,
	},

	CUSTOM_CONFIG_KEYS = {
		"spellConfig",
		"itemConfig",
		"slotConfig",
		"timerConfig",
		"bloodlustConfig",
	},

	SPEC_CONFIG_KEYS = {
		"spellConfig",
		"itemConfig",
		"customConfig",
		"resourceBarConfig",
		"castBarConfig",
		"anchorConfig",
		"buffBarsAnchorConfig",
		"aurasAnchorConfig",
	},

	OPTION_KEYS = {
		resourceBar = true,
		castBar = true,
	},
}
