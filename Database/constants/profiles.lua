local SCM = select(2, ...)

SCM.Constants.PROFILES = {
	PREFIX = "SCM",
	DATA_VERSION = 1,

	INCLUDE_OPTIONS = {
		{ key = "includeResourceBar", label = "Resource Bar Settings" },
		{ key = "includeCastBar", label = "Cast Bar Settings" },
		{ key = "includeGlobalSettings", label = "Global Settings" },
		{ key = "includeGlobalAnchors", label = "Global Icon Anchors" },
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

	OPTION_KEYS = {
		resourceBar = true,
		castBar = true,
	},
}
