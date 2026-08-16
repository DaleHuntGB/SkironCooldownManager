local SCM = select(2, ...)
local Constants = SCM.Constants

SCM.CooldownViewerNameToIndex = {
	["EssentialCooldownViewer"] = Enum.CooldownViewerCategory.Essential,
	--["UtilityCooldownViewer"] = Enum.CooldownViewerCategory.Utility,
	["UtilityCooldownViewer"] = Enum.CooldownViewerCategory.Essential,
	["BuffIconCooldownViewer"] = Enum.CooldownViewerCategory.TrackedBuff,
	["BuffBarCooldownViewer"] = Enum.CooldownViewerCategory.TrackedBar,
}

Constants.SourcePairs = {
	[Enum.CooldownViewerCategory.Essential] = Enum.CooldownViewerCategory.Utility,
	[Enum.CooldownViewerCategory.Utility] = Enum.CooldownViewerCategory.Essential,
	[Enum.CooldownViewerCategory.TrackedBuff] = Enum.CooldownViewerCategory.TrackedBar,
	[Enum.CooldownViewerCategory.TrackedBar] = Enum.CooldownViewerCategory.TrackedBuff,
}

Constants.BuffBarContent = {
	[Enum.CooldownViewerBarContent.IconAndName] = "Bar + Icon",
	[Enum.CooldownViewerBarContent.NameOnly] = "Bar Only",
}

Constants.FakeAuras = {
	-- WARLOCK
	[265187] = 15, -- Summon Tyrant 15
	[1288950] = 20, -- Grimoire: Fel Ravager
	[1288945] = 20, -- Grimoire: Imp Lord
	[104316] = 12, -- Call Dreadstalkers
	[1251781] = 15, -- Summon Vilefiend
	[1276672] = 12, -- Summon Doomguard (not even Blizzard shows that)
	[1122] = true, -- Summon Infernal
	[205180] = 25, -- Summon Darkglare

	-- PALADIN
	[26573] = true, -- Consecration 12

	-- PRIEST
	-- [373276] = 24, -- Idol of Yogg-Saron
	[451234] = true, -- Voidwrath 6
	[34433] = true, -- Shadowfiend 6
	[1280137] = true, -- Mindbender 12
	[450193] = true, -- Entropic Rift
	[449880] = true, -- Void Heart

	-- SHAMAN
	[5394] = true, -- Healing Stream Totem 15
	[108280] = true, -- Healing Tide Totem 10
	[98008] = true, -- Spirit Link Totem 6
	[192077] = true, -- Wind Rush Totem 7
	[355580] = true, -- Static Field Totem 6
	[192058] = true, -- Capacitor Totem 2
	[2484] = true, -- Earthbind Totem 20
	[8143] = true, -- Tremor Totem 10
	[383013] = true, -- Poison Cleansing Totem 6
	[204336] = true, -- Grounding Totem 3
	[204331] = true, -- Counterstrike Totem 15
	[460697] = true, -- Totem of Wrath 15
	[51485] = true, -- Earthgrab Totem 20
	[198103] = true, -- Earth Elemental 30
	--[444995] = 25, -- Surging Totem

	-- MONK
	[322118] = true, -- Invoke Yu'lon, the Jade Serpent 12
	[325197] = true, -- Invoke Chi-ji, the Red Crane 12
}

Constants.TargetAuras = {
	[1160] = true,
}

-- Blizzard randomly clears those cooldowns and I have to fix it. Fun :)
Constants.FixBlizzardSpells = {
	[202137] = true, -- Sigil of Silence
	[204596] = true, -- Sigil of Flame
	[207684] = true, -- Sigil or Misery
	[325153] = true, -- Exploding Keg
}

-- C_Spell.GetSpellCooldown returns a very short cooldown but Blizzard never sets the cooldown which breaks hideWhileNotReady
Constants.CheckCooldownFrameSpells = {
	[190925] = true, -- Harpoon
}

Constants.CheckActiveSpell = {
	[403631] = true, -- Breath of Eons (YEP, only Breath of Eons returns the wrong spellID from FindSpellOverrideByID)
	-- [357210] = true, -- Deep Breath
	-- [359816] = true, -- Dream Flight
}

Constants.Debuffs = {
	-- Druid
	[8921] = true, -- Moonfire (Balance)
	[209749] = true, -- Faerie Swarm
	[93402] = true, -- Sunfire
	[1822] = true, -- Rake
	[1079] = true, -- Rip
	[155625] = true, -- Moonfire (Feral)
	[1252871] = true, -- Moonfire (Guardian)
	[1243807] = true, -- Frantic Frenzy
	[77758] = true, -- Thrash

	-- Priest
	[34914] = true, -- Vampiric Touch
	[589] = true, -- Shadow Word: Pain (Shadow)
	[14914] = true, -- Shadow Word: Pain (Holy)
	[335467] = true, -- Shadow Word Madness
	-- [263165] = true, -- Void Torrent

	-- Warrior
	[772] = true, -- "Rend"

	-- Death Knight
	[77575] = true, -- Outbreak

	-- Warlock
	[348] = true, -- Immolate
	[80240] = true, -- Havoc
	[980] = true, -- Agony
	[172] = true, -- Corruption
	[1259790] = true, -- Unstable Affliction
	[48181] = true, -- Haunt

	-- Demon Hunter
	[204021] = true, -- Fiery Brand
	[204596] = true, -- Sigil of Flame
	-- [258920] = true, -- Immolation Aura
	[258860] = true, -- Essence Break

	-- Paladin
	[343527] = true, -- Execution Sentence
	-- [26573] = true, -- Consecration

	-- Shaman
	[470411] = true, -- Flame Shock

	-- Hunter
	[212431] = true, -- Explosive Shot

	-- Rogue
	[703] = true, -- Garrote
	[1943] = true, -- Rupture
	[32645] = true, -- Envenom
	[360194] = true, -- Deathmark
	[385627] = true, -- Kingsbane
	[315341] = true, -- Between the Eyes

	-- Evoker
	-- [382266] = true, -- Fire Breath

}

