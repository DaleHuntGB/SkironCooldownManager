local SCM = select(2, ...)

local Cooldowns = SCM.Cooldowns

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
