local SCM = select(2, ...)
local RESOURCE_BAR = SCM.Constants.RESOURCE_BAR

RESOURCE_BAR.CLASS_SECONDARY_POWER["DEATHKNIGHT"] = {
	resourceKind = "runes",
	powerToken = "RUNES",
}

RESOURCE_BAR.CLASS_SECONDARY_POWER["EVOKER"] = {
	powerType = Enum.PowerType.Essence,
	powerToken = "ESSENCE",
}
RESOURCE_BAR.CLASS_SECONDARY_POWER["PALADIN"] = {
	powerType = Enum.PowerType.HolyPower,
	powerToken = "HOLY_POWER",
	client = WOW_PROJECT_MAINLINE,
}
RESOURCE_BAR.CLASS_SECONDARY_POWER["WARLOCK"] = {
	powerType = Enum.PowerType.SoulShards,
	powerToken = "SOUL_SHARDS",
	client = WOW_PROJECT_MAINLINE,
}

RESOURCE_BAR.SPEC_SECONDARY_POWER = {
	[62] = {
		powerType = Enum.PowerType.ArcaneCharges,
		powerToken = "ARCANE_CHARGES",
	},
	[63] = {
		resourceKind = "spellCharges",
		spellID = 108853,
		powerToken = "SPELL_CHARGES_FIRE_BLAST",
		segmentCount = 2,
		segmentCountTalentSpellID = 205029,
		talentSegmentCount = 3,
	},
	[64] = {
		resourceKind = "icicles",
		powerToken = "ICICLES",
		segmentCount = 5,
		registerUnitAura = true,
	},
	[255] = {
		resourceKind = "tipOfTheSpear",
		powerToken = "TIP_OF_THE_SPEAR",
		segmentCount = 3,
		registerUnitAura = true,
	},
	[257] = {
		resourceKind = "spellCharges",
		spellID = 2050,
		powerToken = "SPELL_CHARGES_SERENITY",
		segmentCount = 2,
	},
	[263] = {
		resourceKind = "maelstromWeapon",
		powerToken = "MAELSTROM_WEAPON",
		segmentCount = 5,
		registerUnitAura = true,
	},
	[267] = {
		resourceKind = "destructionSoulShards",
		powerType = Enum.PowerType.SoulShards,
		powerToken = "SOUL_SHARDS",
		segmentCount = 5,
	},
	[268] = {
		resourceKind = "stagger",
		powerToken = "STAGGER",
	},
	[269] = {
		powerType = Enum.PowerType.Chi,
		powerToken = "CHI",
	},
	[581] = {
		resourceKind = "vengeanceSoulFragments",
		powerToken = "SOUL_FRAGMENTS_VENGEANCE",
		spellID = 228477,
		segmentCount = 6,
	},
	[1480] = {
		resourceKind = "soulFragments",
		powerToken = "SOUL_FRAGMENTS",
		registerUnitAura = true,
	},
}

RESOURCE_BAR.CLASS_MANA_SECONDARY_POWER = {
	["PRIEST"] = {
		[Enum.PowerType.Insanity] = {
			powerType = Enum.PowerType.Mana,
			powerToken = "MANA",
		},
	},
	["SHAMAN"] = {
		[Enum.PowerType.Maelstrom] = {
			powerType = Enum.PowerType.Mana,
			powerToken = "MANA",
		},
	},
}

RESOURCE_BAR.CHARGED_COMBO_POINT_COLOR = {
	r = 0.25,
	g = 0.70,
	b = 1.00,
	filledAlpha = 0.45,
	emptyAlpha = 0.22,
}

RESOURCE_BAR.FALLBACK_POWER_COLOR_BY_TOKEN = {
	ESSENCE = { r = 0.32, g = 0.84, b = 0.90 },
	MAELSTROM_WEAPON = { r = 0.00, g = 0.50, b = 1.00 },
	SOUL_FRAGMENTS = { r = 0.35, g = 0.25, b = 0.73 },
	SOUL_FRAGMENTS_VENGEANCE = { r = 0.35, g = 0.25, b = 0.73 },
	SPELL_CHARGES_FIRE_BLAST = { r = 1.00, g = 0.34, b = 0.12 },
	STAGGER = { r = 0.52, g = 1.00, b = 0.52 },
}

RESOURCE_BAR.DRUID_PRIMARY_POWER_TYPES[Enum.PowerType.LunarPower] = "Lunar"

RESOURCE_BAR.SEGMENT_TICKS_BY_POWER_TOKEN = {
	ARCANE_CHARGES = true,
	CHI = true,
	COMBO_POINTS = true,
	ESSENCE = true,
	HOLY_POWER = true,
	MAELSTROM_WEAPON = true,
	RUNES = true,
	SOUL_SHARDS = true,
	SOUL_FRAGMENTS_VENGEANCE = true,
	SPELL_CHARGES_FIRE_BLAST = true,
	SPELL_CHARGES_SERENITY = true,
	TIP_OF_THE_SPEAR = true,
}
