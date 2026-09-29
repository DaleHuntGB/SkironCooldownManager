local SCM = select(2, ...)

local CustomIcons = SCM.CustomIcons
local Cache = SCM.Cache
local CustomSpellFrames = CustomIcons.SpellFrames

function CustomIcons.UpdateCustomIconCharges(frame, spellID)
	if not spellID then
		return
	end

	local chargeInfo = C_Spell.GetSpellCharges(spellID)
	if not chargeInfo and not frame.SCMConfig.forceShowCharges then
		frame.ChargeCount.Current:Hide()
		return
	end

	if chargeInfo then
		if chargeInfo.maxCharges > 1 or frame.SCMConfig.forceShowCharges then
			frame.ChargeCount.Current:SetText(chargeInfo.currentCharges)
			frame.ChargeCount.Current:Show()
		else
			frame.ChargeCount.Current:Hide()
		end
		return
	end

	local success, charges = pcall(C_StringUtil.TruncateWhenZero, C_Spell.GetSpellCastCount(spellID))
	if success then
		frame.ChargeCount.Current:SetText(charges)
		frame.ChargeCount.Current:Show()
	else
		frame.ChargeCount.Current:Hide()
	end
end

local function UpdateSpellUsesForEntries(entries)
	if not entries then
		return
	end

	for i = 1, #entries do
		local entry = entries[i]
		local frame = CustomSpellFrames[entry.id]
		local updateCharges = frame and not frame.SCMReleased and frame.UpdateCharges
		if updateCharges then
			updateCharges(frame, entry.config.spellID)
		end
	end
end

function CustomIcons.UpdateSpellUses(spellID, baseSpellID)
	local entriesBySpellID = Cache.cachedCustomSpellEntriesBySpellID

	UpdateSpellUsesForEntries(entriesBySpellID[spellID])

	if baseSpellID and baseSpellID ~= spellID then
		UpdateSpellUsesForEntries(entriesBySpellID[baseSpellID])
	end
end

function CustomIcons.UpdateSpellGlow(spellID, event)
	local entriesBySpellID = Cache.cachedCustomSpellEntriesBySpellID[spellID]

	if not entriesBySpellID then
		for baseSpellID, entries in pairs(Cache.cachedCustomSpellEntriesBySpellID) do
			if C_Spell.GetOverrideSpell(baseSpellID) == spellID then
				entriesBySpellID = entries
			end
		end

		if not entriesBySpellID then
			return
		end
	end

	for i = 1, #entriesBySpellID do
		local entry = entriesBySpellID[i]
		local frame = CustomSpellFrames[entry.id]
		if frame and not frame.SCMReleased then
			if event == "SHOW" then
				SCM:StartCustomGlow(frame)
			else
				SCM:StopCustomGlow(frame)
			end
		end
	end
end

local function UpdateSpellUsabilityForConfig(configTable)
	if not configTable then
		return
	end

	for id, config in pairs(configTable) do
		local spellID = config.spellID
		local frame = spellID and CustomSpellFrames[id]
		if frame and not frame.SCMReleased then
			if frame.spellOutOfRange then
				frame.Icon:SetVertexColor(CooldownViewerConstants.ITEM_NOT_IN_RANGE_COLOR:GetRGBA())
			elseif not config.showNotUsable or C_Spell.IsSpellUsable(spellID) then
				frame.Icon:SetVertexColor(1, 1, 1, 1)
			else
				frame.Icon:SetVertexColor(CooldownViewerConstants.ITEM_NOT_USABLE_COLOR:GetRGBA())
			end
		end
	end
end

function CustomIcons.UpdateSpellUsability()
	UpdateSpellUsabilityForConfig(SCM.customConfig.spellConfig)
	UpdateSpellUsabilityForConfig(SCM.globalCustomConfig.spellConfig)
end

function CustomIcons.UpdateSpellsKnown()
	CustomIcons.CreateIcons(SCM.customConfig.spellConfig)
	CustomIcons.CreateIcons(SCM.globalCustomConfig.spellConfig, true)
	CustomIcons.ProcessIcons(SCM.customConfig.spellConfig, Cache.cachedCooldownFrameTbl)
	CustomIcons.ProcessIcons(SCM.globalCustomConfig.spellConfig, Cache.cachedCooldownFrameTbl, true)
end

function CustomIcons.UpdateSpellRange(spellID, isInRange, checksRange)
	local entries = Cache.cachedCustomSpellEntriesBySpellID[spellID]
	if not entries then
		return
	end

	local showOutOfRange = checksRange and isInRange == false
	for _, entry in ipairs(entries) do
		local frame = CustomSpellFrames[entry.id]
		if frame and not frame.SCMReleased and not (frame.spellOutOfRange == showOutOfRange) then
			local config = entry.config
			if config and config.showOutOfRange then
				frame.spellOutOfRange = showOutOfRange
				frame.OutOfRange:SetShown(showOutOfRange)

				if showOutOfRange then
					frame.Icon:SetVertexColor(CooldownViewerConstants.ITEM_NOT_IN_RANGE_COLOR:GetRGBA())
				elseif not config.showNotUsable or C_Spell.IsSpellUsable(spellID) then
					frame.Icon:SetVertexColor(1, 1, 1, 1)
				else
					frame.Icon:SetVertexColor(CooldownViewerConstants.ITEM_NOT_USABLE_COLOR:GetRGBA())
				end
			else
				frame.spellOutOfRange = nil
			end
		end
	end
end
