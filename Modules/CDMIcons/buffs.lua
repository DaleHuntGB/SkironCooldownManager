local SCM = select(2, ...)

local Cooldowns = SCM.Cooldowns
local Icons = SCM.Icons
local States = SCM.States
local Constants = SCM.Constants

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
	if self.SCMHidden or not self.PandemicIcon or not self.PandemicIcon:IsVisible() then
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
