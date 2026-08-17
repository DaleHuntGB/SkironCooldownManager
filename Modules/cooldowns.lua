local SCM = select(2, ...)

local Cooldowns = SCM.Cooldowns
local Icons = SCM.Icons
local Cache = SCM.Cache
local Constants = SCM.Constants
local States = SCM.States

local NumericRuleFormatter = C_StringUtil.CreateNumericRuleFormatter()
Cooldowns.NumericRuleFormatter = NumericRuleFormatter

function Cooldowns.ApplyNumericRuleFormatter(cooldownFrame)
	if cooldownFrame and cooldownFrame.SetCountdownFormatter then
		cooldownFrame:SetCountdownFormatter(NumericRuleFormatter)
	end
end

function Cooldowns:ApplyFormatterSettings()
	local options = SCM.db.profile.options

	NumericRuleFormatter:SetBreakpoints(options.cooldownBreakpoints)
end

local function SetBuffActive(parent)
	if parent.SCMUseFixedDuration then
		parent.SCMFixedDuration = parent.SCMFixedDuration or GetTime() + parent.SCMUseFixedDuration
	end

	parent.SCMActive = true
	States.SetActiveState(parent, true)
end

local function SetBuffInactive(parent, isActiveState)
	if parent.SCMFixedDuration and GetTime() < parent.SCMFixedDuration then
		return
	elseif parent:IsShown() and parent.Cooldown and parent.Cooldown:IsVisible() and not isActiveState then
		return
	end

	parent.SCMFixedDuration = nil
	parent.SCMActive = nil
	States.SetActiveState(parent, false)
end

local function OnBuffActiveStateChanged(self)
	if not self.SCMConfig then
		return
	elseif issecretvalue(self.isActive) then
		return
	end

	if self.isActive then
		SetBuffActive(self)
	else
		SetBuffInactive(self, true)
	end
end

local function OnBuffCooldownSet(self)
	local parent = (self.SCMConfig and self) or self.SCMParent or self:GetParent()
	if not parent or not parent.SCMConfig or not issecretvalue(parent.isActive) or (not parent.SCMCheckCooldownFrame and not parent.auraInstanceID) then
		return
	end

	SetBuffActive(parent)
end

local function OnBuffCooldownEnd(self)
	local parent = (self.SCMConfig and self) or self.SCMParent or self:GetParent()
	if not parent or not parent.SCMConfig or not issecretvalue(parent.isActive) then
		return
	end

	SetBuffInactive(parent)
end

local function OnBuffShowPandemicStateFrame(self)
	if not self.PandemicIcon or not self.PandemicIcon:IsVisible() then
		return
	end

	local options = self.SCMBuffOptions or self.SCMIconOptions or self.SCMBuffBarOptions
	if not options or options.pandemicGlowOption == "keepPandemicGlow" then
		return
	end

	self.PandemicIcon:SetAlpha(0)

	if self.SCMPandemicStop then
		self.SCMPandemicStop:Cancel()
		self.SCMPandemicStop = nil
	end

	if not self.SCMPandemic and options.pandemicGlowOption == "replacePandemicGlow" then
		self.SCMPandemic = true

		if options.pandemicReplaceWithBorder and self.pandemicBorder then
			self.pandemicBorder:Show()
		elseif not self.SCMGlow then
			if options.pandemicReplaceWithCustomGlow then
				SCM:StartCustomGlow(self, options.pandemicCustomGlowTypeOptions[options.pandemicGlowType], options.pandemicGlowType)
			else
				SCM:StartCustomGlow(self)
			end
		end
	end
end

local function OnBuffHidePandemicStateFrame(self)
	if not self.SCMPandemic or self.SCMPandemicStop then
		return
	end

	local options = self.SCMBuffOptions or self.SCMIconOptions or self.SCMBuffBarOptions
	if not options or options.pandemicGlowOption ~= "replacePandemicGlow" then
		return
	end

	self.SCMPandemicStop = C_Timer.NewTimer(0.1, function()
		if options.pandemicReplaceWithBorder and self.pandemicBorder then
			self.pandemicBorder:Hide()
		else
			SCM:StopCustomGlow(self)
		end
		self.SCMPandemic = nil
	end)
end

function Cooldowns.SetupPandemicHooks(child, options)
	local pandemicGlowOption = options and options.pandemicGlowOption
	if pandemicGlowOption and pandemicGlowOption ~= "keepPandemicGlow" and not child.SCMPandemicShowHooked then
		hooksecurefunc(child, "ShowPandemicStateFrame", OnBuffShowPandemicStateFrame)
		child.SCMPandemicShowHooked = true
	end

	if pandemicGlowOption == "replacePandemicGlow" and not child.SCMPandemicHideHooked then
		hooksecurefunc(child, "HidePandemicStateFrame", OnBuffHidePandemicStateFrame)
		child.SCMPandemicHideHooked = true
	end
end

local function OnCooldownSet(self, ...)
	local handler = self.SCMCooldownCallback
	if handler then
		handler(self, ...)
	end

	SCM.ApplyCooldownSkin(self)
end

function Cooldowns.SetupCooldownHook(cooldownFrame, callback)
	if callback then
		cooldownFrame.SCMCooldownCallback = callback
	end

	if cooldownFrame.SCMCooldownHook then
		return
	end

	hooksecurefunc(cooldownFrame, "SetCooldown", OnCooldownSet)
	cooldownFrame.SCMCooldownHook = true
end

function Cooldowns.SetupBuffIconHooks(child, options)
	local checkCooldownFrame = (child.SCMSpellID and (Constants.FakeAuras[child.SCMSpellID] or Constants.TargetAuras[child.SCMSpellID]))
	child.SCMBuffOptions = options
	Cooldowns.SetupPandemicHooks(child, options)

	if (checkCooldownFrame and child.SCMCooldownHooked) or (not checkCooldownFrame and child.SCMAuraHooked) then
		return
	end

	Icons.SetupIconHooks(child)

	-- Cooldowns

	if checkCooldownFrame then
		if not child.SCMCooldownHooked then
			Cooldowns.SetupCooldownHook(child.Cooldown, OnBuffCooldownSet)
			hooksecurefunc(child, "OnAuraInstanceInfoSet", OnBuffCooldownSet)
			hooksecurefunc(child.Cooldown, "Clear", OnBuffCooldownEnd)
			child.Cooldown:HookScript("OnCooldownDone", OnBuffCooldownEnd)
			hooksecurefunc(child, "OnActiveStateChanged", OnBuffActiveStateChanged)
			child.SCMCooldownHooked = true
		end

		child.SCMCheckCooldownFrame = true

		if child.SCMSpellID then
			child.SCMUseFixedDuration = type(Constants.FakeAuras[child.SCMSpellID]) == "number" and Constants.FakeAuras[child.SCMSpellID]
		end
	else
		if not child.SCMAuraHooked then
			hooksecurefunc(child, "OnAuraInstanceInfoSet", OnBuffCooldownSet)
			hooksecurefunc(child, "OnAuraInstanceInfoCleared", function(self)
				C_Timer.After(0, function()
					OnBuffCooldownEnd(self)
				end)
			end)

			hooksecurefunc(child, "OnActiveStateChanged", OnBuffActiveStateChanged)
			child.SCMAuraHooked = true
		end

		child.SCMCheckCooldownFrame = nil
		child.SCMUseFixedDuration = nil
	end
end

local function GetChildCooldownInfo(child, includeGCD)
	if child.SCMEquipSlot then
		local now = GetTime()
		local startTime, duration = GetInventoryItemCooldown("player", child.SCMEquipSlot)
		if startTime and startTime > 0 and (startTime + duration) - now >= 0.1 then
			local globalCooldown = C_Spell.GetSpellCooldown(61304)
			if duration ~= globalCooldown.duration then
				return "cooldown", nil, startTime, duration
			elseif includeGCD then
				return "ready", nil, startTime, duration
			end
		end

		return "ready"
	end

	if child.SCMSpellID or child.SCMSpellCategoryID then
		local cooldownData = SCM.defaultCooldownViewerConfig.cooldownIDs[child.SCMCooldownID]
		local spellID
		if child.SCMSpellCategoryID then
			spellID = C_Spell.GetLastCategoryCooldownSource(child.SCMSpellCategoryID)
		else
			spellID = FindSpellOverrideByID(child.SCMSpellID) or child.SCMSpellID
		end

		if spellID then
			if Constants.CheckActiveSpell[spellID] then
				local isActiveSpell = not issecretvalue(child.isActiveSpell) and child.isActiveSpell
				if isActiveSpell then
					spellID = isActiveSpell
				end
			end
			
			local wasSetFromCharges = not issecretvalue(child.wasSetFromCharges) and child.wasSetFromCharges
			local wasSetFromCooldown = not issecretvalue(child.wasSetFromCooldown) and child.wasSetFromCooldown
			if wasSetFromCharges and cooldownData and cooldownData.charges then
				local spellCharges = C_Spell.GetSpellCharges(spellID)
				if spellCharges and spellCharges.isActive then
					local durationObject = C_Spell.GetSpellChargeDuration(spellID, true)
					if durationObject then
						return "recharging", durationObject
					end
				end
			elseif wasSetFromCooldown then
				local spellCooldown = C_Spell.GetSpellCooldown(spellID)
				if spellCooldown and spellCooldown.isActive and (includeGCD or not spellCooldown.isOnGCD) then
					local durationObject = C_Spell.GetSpellCooldownDuration(spellID, true)
					if durationObject then
						return spellCooldown.isOnGCD and "ready" or "cooldown", durationObject
					end
				end
			else
				local spellCooldown = C_Spell.GetSpellCooldown(spellID)
				if spellCooldown and spellCooldown.isActive and not spellCooldown.isOnGCD then
					local durationObject = C_Spell.GetSpellCooldownDuration(spellID, true)
					if durationObject then
						return "cooldown", durationObject
					end
				end

				if cooldownData and cooldownData.charges then
					local spellCharges = C_Spell.GetSpellCharges(spellID)
					if spellCharges and spellCharges.isActive then
						local durationObject = C_Spell.GetSpellChargeDuration(spellID, true)
						if durationObject then
							return "recharging", durationObject
						end
					end
				end

				if includeGCD and spellCooldown and spellCooldown.isActive and spellCooldown.isOnGCD then
					local durationObject = C_Spell.GetSpellCooldownDuration(spellID, true)
					if durationObject then
						return "ready", durationObject
					end
				end
			end

			return "ready"
		else
			return
		end
	end
end

function Cooldowns.GetChildCooldown(child)
	if not (child.SCMEquipSlot or child.SCMSpellID or child.SCMSpellCategoryID) then
		return
	end

	local cooldownState, durationObject = GetChildCooldownInfo(child, false)
	cooldownState = cooldownState or "ready"

	if Constants.CheckCooldownFrameSpells[child.SCMSpellID] then
		return durationObject and child.Cooldown:IsVisible() and cooldownState or "ready", durationObject
	end

	return cooldownState, durationObject
end

function Cooldowns.SetNormalCooldown(self, parent)
	local options = SCM.db.profile.options
	local useAuraDisplayTime = self:GetUseAuraDisplayTime()
	local childConfig = parent.SCMConfig
	local shouldReplaceActiveSwipe = (childConfig.hideActiveSwipe or options.disableRegularIconActiveSwipe) and not childConfig.forceActiveSwipe

	if useAuraDisplayTime and not shouldReplaceActiveSwipe then
		return
	end

	self.SCMSettingRegularSpellCooldown = true

	local cooldownState, durationObject, startTime, duration = GetChildCooldownInfo(parent, not options.disableGCD)
	if cooldownState then
		self:Clear()

		if durationObject or startTime then
			if not (childConfig.effectRules and childConfig.effectRules.desaturate) then
				Icons.UpdateChildDesaturation(parent, cooldownState == "cooldown" and not useAuraDisplayTime, true)
			end

			if durationObject then
				self:SetCooldownFromDurationObject(durationObject)
			else
				self:SetCooldown(startTime, duration)
			end
		else
			if not (childConfig.effectRules and childConfig.effectRules.desaturate) then
				Icons.UpdateChildDesaturation(parent, false)
			end
		end

		States.SetCooldownState(parent, cooldownState, true)
	end

	self.SCMSettingRegularSpellCooldown = nil
end

function Cooldowns.OverrideRegularAuraCooldown(self, parent, options)
	local config = parent.SCMConfig
	if not self:GetUseAuraDisplayTime() or config.forceActiveSwipe or not (options.disableRegularIconActiveSwipe or config.hideActiveSwipe) then
		if not (config.effectRules and config.effectRules.desaturate) then
			parent.Icon.SCMDesaturated = nil
		end
		return
	end

	Cooldowns.SetNormalCooldown(self, parent)
end

local function SetRegularChildCooldown(child, cooldownInfo)
	local cooldownFrame = child.Cooldown
	if not (cooldownFrame and child.Icon) then
		return
	end

	local isActive = cooldownFrame:GetUseAuraDisplayTime()
	Cooldowns.SetNormalCooldown(cooldownFrame, child)
	States.SyncState(child, isActive, (Cooldowns.GetChildCooldown(child)))
end

local function UpdateViewerChildrenForSpellOverride(viewer, spellID, overrideSpellID, cooldownInfo)
	local children = Cache.cachedViewerChildren[viewer]
	if not children then
		children = { viewer:GetChildren() }
		Cache.cachedViewerChildren[viewer] = children
	end

	for i = 1, #children do
		local child = children[i]
		if child.SCMConfig and not child.SCMBuffBar and child.SCMSpellID == spellID then
			States.SetOverriddenState(child, overrideSpellID and true or false)
			if cooldownInfo and not child.SCMConfig.forceActiveSwipe then
				SetRegularChildCooldown(child, cooldownInfo)
			end
		end
	end
end

function Cooldowns.UpdateRegularChildrenForSpellOverride(spellID, overrideSpellID, cooldownInfo)
	UpdateViewerChildrenForSpellOverride(EssentialCooldownViewer, spellID, overrideSpellID, cooldownInfo)
	UpdateViewerChildrenForSpellOverride(UtilityCooldownViewer, spellID, overrideSpellID, cooldownInfo)
end

local function OnRegularCooldownChanged(self, changeType)
	local parent = self.SCMParent or self:GetParent()
	if not (parent and parent.SCMConfig) or self.SCMSettingRegularSpellCooldown or self.SCMClearingGCD then
		return
	end

	local options = SCM.db.profile.options
	local config = parent.SCMConfig
	local useAuraDisplayTime = self:GetUseAuraDisplayTime()

	if (options.disableRegularIconActiveSwipe or config.hideActiveSwipe) and not config.forceActiveSwipe and useAuraDisplayTime then
		Cooldowns.OverrideRegularAuraCooldown(self, parent, options)
	elseif options.disableGCD or (changeType == "CLEAR" and parent.SCMSpellID and Constants.FixBlizzardSpells[parent.SCMSpellID]) then
		Cooldowns.SetNormalCooldown(self, parent)
	elseif not (config.effectRules and config.effectRules.desaturate) and parent.Icon.SCMDesaturated and not useAuraDisplayTime then
		parent.Icon.SCMDesaturated = nil
		parent.Icon:SetDesaturated(false)
	end

	RunNextFrame(function()
		local isActive = useAuraDisplayTime
		if not issecretvalue(parent.wasSetFromAura) then
			isActive = parent.wasSetFromAura
		end

		States.SyncState(parent, isActive, (Cooldowns.GetChildCooldown(parent)))
	end)
end

function Cooldowns.SetupCooldownHooks(child, options)
	if not child.Cooldown then
		return
	end

	Cooldowns.SetupPandemicHooks(child, options)
	if child.SCMRegularCooldownHook then
		return
	end

	Cooldowns.SetupCooldownHook(child.Cooldown, function(self)
		OnRegularCooldownChanged(self, "SET")
	end)
	hooksecurefunc(child.Cooldown, "Clear", function(self)
		OnRegularCooldownChanged(self, "CLEAR")
	end)

	child.Cooldown.SCMParent = child
	child.Cooldown:HookScript("OnCooldownDone", function(self, ...)
		local parent = self.SCMParent or self:GetParent()
		local config = parent.SCMConfig
		if not (config and config.effectRules and config.effectRules.desaturate) then
			parent.Icon.SCMDesaturated = nil
		end
		OnRegularCooldownChanged(self, "DONE")
	end)
	child.SCMRegularCooldownHook = true
end
