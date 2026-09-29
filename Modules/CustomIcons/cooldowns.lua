local SCM = select(2, ...)

local CustomIcons = SCM.CustomIcons
local Cooldowns = SCM.Cooldowns
local Icons = SCM.Icons
local States = SCM.States
local Utils = SCM.Utils
local ToGlobalGroup = Utils.ToGlobalGroup
local CustomItemFrames = CustomIcons.ItemFrames
local CustomSpellFrames = CustomIcons.SpellFrames

function Cooldowns.OnCustomIconCooldownDone(self)
	local parent = self.SCMParent or self:GetParent()
	if not parent or parent.SCMReleased or not parent.SCMConfig then
		return
	end

	if parent.Icon and not (parent.SCMConfig.effectRules and parent.SCMConfig.effectRules.desaturate) then
		parent.Icon.SCMDesaturated = nil
		parent.Icon:SetDesaturated(false)
	end

	if parent.UpdateCooldown then
		parent.isOnGCD = nil
		parent.UpdateCooldown(parent, parent.SCMIconType, parent.SCMConfig)
	end

	if parent.UpdateCharges then
		parent.UpdateCharges(parent, parent.spellID)
	end

	if parent and parent.SCMGroup then
		SCM:ApplyAnchorGroupCDManagerConfig(parent.SCMGroup, parent.SCMGlobal)
	end
end

local function UpdateCustomIconGCD(frame, config, isOnCooldown)
	if isOnCooldown or frame.Cooldown:IsShown() or not config.showGCD then
		frame.GCDCooldown:Hide()
		return
	end

	local globalCooldown = C_Spell.GetSpellCooldown(61304)
	if globalCooldown and globalCooldown.isActive then
		frame.GCDCooldown:Show()
		frame.GCDCooldown:SetReverse(false)
		frame.GCDCooldown:SetCooldown(globalCooldown.startTime, globalCooldown.duration)
	else
		frame.GCDCooldown:Hide()
	end
end

function Cooldowns.UpdateCustomIconCooldown(frame, iconType, config)
	local now = GetTime()
	local customTimerStart, customTimerDuration = CustomIcons.GetActiveCustomTimer(frame, iconType, config, now)
	if customTimerStart then
		frame.Cooldown:SetCooldown(customTimerStart, customTimerDuration)
		frame.Cooldown:SetReverse(true)
		if not (config.effectRules and config.effectRules.desaturate) then
			frame.Icon:SetDesaturated(false)
		end
		UpdateCustomIconGCD(frame, config, true)
		return true
	end

	if iconType == "spell" then
		local isOnCooldown = false
		local isChargeCooldown = false
		local spellCooldown = C_Spell.GetSpellCooldown(config.spellID)
		if spellCooldown.isActive and not spellCooldown.isOnGCD then
			local durationObject = C_Spell.GetSpellCooldownDuration(config.spellID, true)
			frame.Cooldown:Clear()
			frame.Cooldown:SetCooldownFromDurationObject(durationObject)
			if not (config.effectRules and config.effectRules.desaturate) then
				frame.Icon:SetDesaturated(true)
				frame.Icon:SetDesaturation(C_CurveUtil.EvaluateColorValueFromBoolean(durationObject:IsZero(), 0, 1))
			end
			isOnCooldown = true
		end

		spellCooldown = C_Spell.GetSpellCharges(config.spellID)

		if not isOnCooldown and spellCooldown and spellCooldown.isActive and not spellCooldown.isOnGCD then
			frame.Cooldown:Clear()
			frame.Cooldown:SetCooldownFromDurationObject(C_Spell.GetSpellChargeDuration(config.spellID, true))
			if not (config.effectRules and config.effectRules.desaturate) then
				frame.Icon:SetDesaturated(false)
			end
			isOnCooldown = true
			isChargeCooldown = true
		end

		if not isOnCooldown then
			frame.Cooldown:Clear()
			if not (config.effectRules and config.effectRules.desaturate) then
				frame.Icon.SCMDesaturated = nil
				frame.Icon:SetDesaturated(false)
			end
		end

		if not isOnCooldown and (not spellCooldown or not spellCooldown.isActive or spellCooldown.isOnGCD) and config.showGCD then
			local globalCooldown = C_Spell.GetSpellCooldown(61304)

			if globalCooldown.isActive then
				frame.GCDCooldown:Show()
				frame.GCDCooldown:SetReverse(false)
				frame.GCDCooldown:SetCooldown(globalCooldown.startTime, globalCooldown.duration)
			end
		else
			frame.GCDCooldown:Hide()
		end

		return isOnCooldown, isChargeCooldown
	end

	if iconType == "item" then
		local itemID = frame.SCMItemID
		--local count = C_Item.GetItemCount(itemID, false, true)
		local startTime, duration, _, modRate = C_Item.GetItemCooldown(itemID)

		if duration > 0 and (startTime + duration) - now >= 0 then
			if not frame.isOnCooldown or frame.SCMCooldownStartTime ~= startTime or frame.SCMCooldownDuration ~= duration then
				if duration < 0.1 then
					frame.Icon:SetVertexColor(CooldownViewerConstants.ITEM_NOT_USABLE_COLOR:GetRGBA())
					if not (config.effectRules and config.effectRules.desaturate) then
						frame.Icon:SetDesaturated(false)
					end
				else
					if modRate then
						frame.Cooldown:SetCooldown(startTime, duration, modRate)
					else
						frame.Cooldown:SetCooldown(startTime, duration)
					end

					frame.Icon:SetVertexColor(1, 1, 1)
					if not (config.effectRules and config.effectRules.desaturate) then
						frame.Icon:SetDesaturated(true)
					end
				end
				frame.isOnCooldown = true
				frame.SCMCooldownStartTime = startTime
				frame.SCMCooldownDuration = duration
				UpdateCustomIconGCD(frame, config, true)
			end

			return true
		elseif duration == 0 and frame.isOnCooldown then
			frame.isOnCooldown = false
			frame.SCMCooldownStartTime = nil
			frame.SCMCooldownDuration = nil
			frame.Cooldown:Clear()
			frame.Icon:SetVertexColor(1, 1, 1)
			if not (config.effectRules and config.effectRules.desaturate) then
				frame.Icon:SetDesaturated(false)
			end
			UpdateCustomIconGCD(frame, config, true)
		end
		return
	end

	if iconType == "slot" and config.slotID then
		local startTime, duration = GetInventoryItemCooldown("player", config.slotID)
		if startTime and startTime > 0 and (startTime + duration) - now >= 0.1 then
			local globalCooldown = C_Spell.GetSpellCooldown(61304)
			if duration ~= globalCooldown.duration or config.showGCD then
				frame.Cooldown:SetCooldown(startTime, duration)

				if not (config.effectRules and config.effectRules.desaturate) then
					frame.Icon:SetDesaturated(not (duration == globalCooldown.duration))
				end

				UpdateCustomIconGCD(frame, config, true)
				return true
			end
		end
	end

	frame.isOnCooldown = false
	frame.Cooldown:Clear()
	frame.Icon:SetVertexColor(1, 1, 1)
	if not (config.effectRules and config.effectRules.desaturate) then
		frame.Icon:SetDesaturated(false)
	end
	UpdateCustomIconGCD(frame, config, iconType == "timer")
end

function Cooldowns.GetCustomIconCooldownState(iconType, hasCount, isOnCooldown, isChargeCooldown)
	if iconType == "item" and not hasCount then
		return "noitem"
	end

	if isChargeCooldown then
		return "recharging"
	end

	return isOnCooldown and "cooldown" or "ready"
end

function CustomIcons.UpdateIcons(customConfig, key)
	for id, config in pairs(customConfig) do
		if config[key] then
			local customFrames = CustomIcons.GetCustomIconFrames(config)
			if customFrames then
				if customFrames[id] then
					local frame = customFrames[id]
					local iconType = frame.SCMIconType
					Cooldowns.UpdateCustomIconCooldown(frame, iconType, config)
				end
			end
		end
	end
end

function SCM:UpdateCustomIconsGCD()
	for _, config in pairs(self.customConfig) do
		CustomIcons.UpdateIcons(config, "showGCD")
	end

	for _, config in pairs(self.globalCustomConfig) do
		CustomIcons.UpdateIcons(config, "showGCD")
	end
end
