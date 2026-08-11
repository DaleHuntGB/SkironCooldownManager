local SCM = select(2, ...)
SCM.Constants = {}

local Constants = SCM.Constants

BACKDROP_SCM_PIXEL = {
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	edgeSize = 2,
}

Constants.AnchorPoints = {
	TOPLEFT = "TOPLEFT",
	TOP = "TOP",
	TOPRIGHT = "TOPRIGHT",
	LEFT = "LEFT",
	CENTER = "CENTER",
	RIGHT = "RIGHT",
	BOTTOMLEFT = "BOTTOMLEFT",
	BOTTOM = "BOTTOM",
	BOTTOMRIGHT = "BOTTOMRIGHT",
}

Constants.GrowthDirections = {
	CENTERED = "Centered Horizontal",
	LEFT = "Left",
	RIGHT = "Right",
	FIXED = "Fixed",
}

Constants.SecondaryGrowthDirections = {
	DOWN = "Down",
	UP = "Up",
}

Constants.FrameStrata = {
	BACKGROUND = "Background",
	LOW = "Low",
	MEDIUM = "Medium",
	HIGH = "High",
	DIALOG = "Dialog",
	FULLSCREEN = "Fullscreen",
	FULLSCREEN_DIALOG = "Fullscreen Dialog",
	-- TOOLTIP = "Tooltip",
}

Constants.FrameStrataSorted = {
	"BACKGROUND",
	"LOW",
	"MEDIUM",
	"HIGH",
	"DIALOG",
	"FULLSCREEN",
	"FULLSCREEN_DIALOG",
	-- "TOOLTIP",
}

Constants.TextOutline = {
	[""] = "None",
	OUTLINE = "Outline",
	THICKOUTLINE = "Thick Outline",
	MONOCHROME = "Monochrome",
	["OUTLINE,MONOCHROME"] = "Monochrome Outline",
	SLUG = "Slug",
	["OUTLINE SLUG"] = "Outline Slug",
}

Constants.TextOutlineSorted = {
	"",
	"OUTLINE",
	"SLUG",
	"MONOCHROME",
	"OUTLINE,MONOCHROME",
	"OUTLINE SLUG",
	"THICKOUTLINE",
}

Constants.BlendMode = {
	["DISABLE"] = "DISABLE",
	["BLEND"] = "BLEND",
	["ADD"] = "ADD",
	["MOD"] = "MOD",
}

Constants.BlendModeSorted = {
	"DISABLE",
	"BLEND",
	"ADD",
	"MOD",
}

Constants.States = {
	["always"] = "Always",
	["active"] = "Active",
	["inactive"] = "Inactive",
	["overridden"] = "Overridden",
	["ready"] = "Ready",
	["cooldown"] = "On Cooldown",
	["noitem"] = "No Item",
	["recharging"] = "Recharging",
}

Constants.StatesSorted = {
	["buffBar"] = {
		"always",
		"active",
		"inactive",
	},
	["spell"] = {
		"always",
		"ready",
		"cooldown",
		"active",
		"inactive",
		"overridden",
		"recharging",
	},
	["buffIcon"] = {
		"always",
		"ready",
		"cooldown",
		"active",
		"inactive",
		"recharging",
	},
	["timer"] = {
		"always",
		"active",
		"inactive",
	},
	["item"] = {
		"always",
		"ready",
		"cooldown",
		"noitem",
	},
	["slot"] = {
		"always",
		"ready",
		"cooldown",
	},
	["custom"] = {
		"always",
		"ready",
		"cooldown",
	},
	-- "nocharges",
	-- "maxcharges",
	-- "recharging",
	-- "ongcd",
	-- "mounted",
}

Constants.Visibility = {
	["show"] = "Show",
	["hide"] = "Hide",
}

Constants.VisibilitySorted = {
	"show",
	"hide",
}

Constants.GlobalGlowSubregion = "global"

Constants.Subregions = {
	["glow"] = "Glow",
	["border"] = "Border",
	--["text"] = "Text"
}

Constants.SubregionsSorted = {
	"glow",
	"border",
}

Constants.SubregionTargets = {
	["self"] = "Self",
	["custom"] = "Custom"
}

Constants.SubregionTargetsSorted = {
	"self",
	"custom"
}

Constants.GlowTypes = {
	["Pixel"] = "Pixel",
	["Autocast"] = "Autocast",
	["Proc"] = "Proc",
	["Button"] = "Button",
}

Constants.GlowTypesSorted = {
	"Pixel",
	"Proc",
	"Autocast",
	"Button",
	"Button",
}

Constants.ResourceBarGrowthDirection = {
	UP = "Up",
	DOWN = "Down",
}

Constants.SatedDebuffs = {
	[57723] = true,
	[57724] = true,
	[80354] = true,
	[95809] = true,
	[160455] = true,
	[264689] = true,
	[390435] = true,
}

Constants.SCMAnchors = {
	["SkironCooldownManager"] = {
		["Cast Bar"] = "SCM_CastBar",
		["Primary Resource Bar"] = "SCM_PrimaryResourceBar",
		["Secondary Resource Bar"] = "SCM_SecondaryResourceBar",
		["Anchor"] = "ANCHOR:#",
		["Global Anchor"] = "ANCHOR:G:#",
		["Buff Bar Anchor"] = "ANCHOR:BB:#"
	},
}

