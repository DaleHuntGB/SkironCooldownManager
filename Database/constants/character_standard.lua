local SCM = select(2, ...)
local Constants = SCM.Constants

Constants.CHARACTER.SPEC_IDS = {
	-- DK
	250,
	251,
	252,
	-- DH
	577,
	581,
	1480,
	-- Druid
	102,
	103,
	104,
	105,
	-- Evoker
	1467,
	1468,
	1473,
	-- Hunter
	253,
	254,
	255,
	-- Mage
	62,
	63,
	64,
	-- Monk
	268,
	269,
	270,
	-- Paladin
	65,
	66,
	70,
	-- Priest
	256,
	257,
	258,
	-- Rogue
	259,
	260,
	261,
	-- Shaman
	262,
	263,
	264,
	-- Warlock
	265,
	266,
	267,
	-- Warrior
	71,
	72,
	73,
}

Constants.CHARACTER.ROLES = {
	HEALER = "Healer",
	DAMAGER = "DPS",
	TANK = "Tank",
}

local races = {
	[9] = true, -- Goblin
	[10] = true, -- Blood Elf
	[11] = true, -- Draenei
	[22] = true, -- Worgen
	[25] = { -- Pandaren (Alliance)
		pair = 26,
		faction = "Alliance",
	},
	[26] = { -- Pandaren (Horde)
		pair = 25,
		faction = "Horde",
	},
	[27] = true, -- Nightborne
	[28] = true, -- Highmountain Tauren
	[29] = true, -- Void Elf
	[30] = true, -- Lightforged Draenei
	[31] = true, -- Zandalari Troll
	[32] = true, -- Kul Tiran
	[34] = true, -- Dark Iron Dwarf
	[35] = true, -- Vulpera
	[36] = true, -- Mag'har Orc
	[37] = true, -- Mechagnome
	[52] = { -- Dracthyr (Alliance)
		pair = 70,
		faction = "Alliance",
	},
	[70] = { -- Dracthyr (Horde)
		pair = 52,
		faction = "Horde",
	},
	[84] = { -- Earthen (Horde)
		pair = 85,
		faction = "Horde",
	},
	[85] = { -- Earthen (Alliance)
		pair = 84,
		faction = "Alliance",
	},
	[86] = { -- Haranir
		pair = 91,
		faction = "Alliance",
	},
	[91] = { -- Haranir
		pair = 86,
		faction = "Horde",
	},
}

for raceID, raceData in pairs(races) do
	Constants.CHARACTER.RACES[raceID] = raceData
end
