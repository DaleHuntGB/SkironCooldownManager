local SCM = select(2, ...)
local States = SCM.States
local Icons = SCM.Icons
local SetChildVisibilityState = Icons.SetChildVisibilityState
local UpdateChildDesaturation = Icons.UpdateChildDesaturation

function States.GetState(child)
	if not child.SCMState then
		child.SCMState = {
			Visibility = true,
		}
	end

	return child.SCMState
end

local function GetNextMatchedRule(rules, index, cooldownRuleState, activeRuleState)
	local ruleCount = #rules

	while index <= ruleCount do
		local rule = rules[index]
		while rule do
			local ruleState = rule.state
			if ruleState and (ruleState == cooldownRuleState or ruleState == activeRuleState) then
				index = index + 1
				while index <= ruleCount and rules[index].elseIf do
					index = index + 1
				end
				return rule, index
			end

			index = index + 1
			if index > ruleCount or not rules[index].elseIf then
				break
			end
			rule = rules[index]
		end
	end
end

function States.StopStateGlows(child)
	local state = child and child.SCMState
	local activeStateGlows = state and state.ActiveStateGlows
	if not activeStateGlows then
		return
	end

	for key, activeStateGlow in pairs(activeStateGlows) do
		SCM:StopCustomGlow(child, key, activeStateGlow.glowType)
		activeStateGlows[key] = nil
	end
	state.ActiveStateGlows = nil
end

local function ApplyGlowRules(child, state, config, effectConfig, cooldownRuleState, activeRuleState)
	local rules = effectConfig.rules
	local activeStateGlows = state.ActiveStateGlows
	if not rules or not rules[1] then
		if activeStateGlows then
			States.StopStateGlows(child)
		end
		return
	end

	local subregionOptions = config.subregionOptions and config.subregionOptions.glow
	if not subregionOptions or not subregionOptions[1] then
		if activeStateGlows then
			States.StopStateGlows(child)
		end
		return
	end

	state.GlowRefreshID = (state.GlowRefreshID or 0) + 1
	local refreshID = state.GlowRefreshID

	local rule, index = GetNextMatchedRule(rules, 1, cooldownRuleState, activeRuleState)
	while rule do
		local glowOptions = subregionOptions[rule.subregion]
		local glowType = glowOptions and glowOptions.glowType
		local glowTypeOptions = glowType and glowOptions.glowTypeOptions and glowOptions.glowTypeOptions[glowType]
		if glowTypeOptions then
			local key = "SCMStateGlow_" .. tostring(rule.state) .. "_" .. tostring(rule.subregion)
			activeStateGlows = activeStateGlows or {}
			state.ActiveStateGlows = activeStateGlows

			local activeStateGlow = activeStateGlows[key]
			if not activeStateGlow or activeStateGlow.glowType ~= glowType or activeStateGlow.glowTypeOptions ~= glowTypeOptions then
				if activeStateGlow then
					SCM:StopCustomGlow(child, key, activeStateGlow.glowType)
				end

				if glowType == "Button" then
					for activeKey, currentStateGlow in pairs(activeStateGlows) do
						if activeKey ~= key and currentStateGlow.glowType == "Button" then
							SCM:StopCustomGlow(child, activeKey, currentStateGlow.glowType)
							activeStateGlows[activeKey] = nil
						end
					end
				end

				SCM:StartCustomGlow(child, glowTypeOptions, glowType, key, true, true)
				activeStateGlow = {
					glowType = glowType,
					glowTypeOptions = glowTypeOptions,
				}
				activeStateGlows[key] = activeStateGlow
			end

			activeStateGlow.RefreshID = refreshID
		end
		rule, index = GetNextMatchedRule(rules, index, cooldownRuleState, activeRuleState)
	end

	if not activeStateGlows then
		return
	end

	for key, activeStateGlow in pairs(activeStateGlows) do
		if activeStateGlow.RefreshID ~= refreshID then
			SCM:StopCustomGlow(child, key, activeStateGlow.glowType)
			activeStateGlows[key] = nil
		end
	end
end

local function HideAllStateBorders(child)
	local activeBorders = child.SCMActiveStateBorders
	if not activeBorders then
		return
	end

	local borders = child.SCMStateBorders
	for key in pairs(activeBorders) do
		local border = borders and borders[key]
		if border then
			border:Hide()
			border.SCMStateBorderShown = false
		end
		activeBorders[key] = nil
	end
	child.SCMActiveStateBorders = nil
end
States.HideAllStateBorders = HideAllStateBorders

local function ShowStateBorder(child, key, borderOptions, refreshID)
	local borders = child.SCMStateBorders
	if not borders then
		borders = {}
		child.SCMStateBorders = borders
	end

	local border = borders[key]
	if not border then
		border = CreateFrame("Frame", nil, child, "BackdropTemplate")
		border:SetFrameLevel(child:GetFrameLevel() + 3)
		border:SetAllPoints(child)
		borders[key] = border
	end

	local options = SCM.db.profile.options
	local borderSize = borderOptions.borderSize or options.borderSize or 1
	local borderColor = borderOptions.borderColor or options.borderColor or { r = 1, g = 1, b = 1, a = 1 }
	local r, g, b, a = borderColor.r or 1, borderColor.g or 1, borderColor.b or 1, borderColor.a or 1

	if border.SCMStateBorderSize ~= borderSize then
		border:SetBackdrop({
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = borderSize,
		})
		border.SCMStateBorderSize = borderSize

		local regions = { border:GetRegions() }
		for index = 1, #regions do
			local region = regions[index]
			region:SetTexelSnappingBias(0)
			region:SetSnapToPixelGrid(false)
		end
	end

	border:SetBackdropBorderColor(r, g, b, a)


	local shouldShow = borderSize ~= 0
	if not shouldShow and border.SCMStateBorderShown ~= false then
		border:Hide()
		border.SCMStateBorderShown = false
	elseif shouldShow and border.SCMStateBorderShown ~= true then
		border:Show()
		border.SCMStateBorderShown = true
	end

	local activeBorders = child.SCMActiveStateBorders
	if not activeBorders then
		activeBorders = {}
		child.SCMActiveStateBorders = activeBorders
	end
	activeBorders[key] = refreshID
end

local function ApplyBorderRules(child, state, config, effectConfig, cooldownRuleState, activeRuleState)
	local rules = effectConfig.rules
	local activeBorders = child.SCMActiveStateBorders
	if not rules or not rules[1] then
		if activeBorders then
			HideAllStateBorders(child)
		end
		return
	end

	local subregionOptions = config.subregionOptions and config.subregionOptions.border
	if not subregionOptions or not subregionOptions[1] then
		if activeBorders then
			HideAllStateBorders(child)
		end
		return
	end

	state.BorderRefreshID = (state.BorderRefreshID or 0) + 1
	local refreshID = state.BorderRefreshID

	local rule, index = GetNextMatchedRule(rules, 1, cooldownRuleState, activeRuleState)
	while rule do
		local borderOptions = subregionOptions[rule.subregion]
		if borderOptions then
			local key = "SCMStateBorder_" .. tostring(rule.state) .. "_" .. tostring(rule.subregion)
			ShowStateBorder(child, key, borderOptions, refreshID)
		end
		rule, index = GetNextMatchedRule(rules, index, cooldownRuleState, activeRuleState)
	end

	activeBorders = child.SCMActiveStateBorders
	if not activeBorders then
		return
	end

	local borders = child.SCMStateBorders
	for key in pairs(activeBorders) do
		if activeBorders[key] ~= refreshID then
			local border = borders and borders[key]
			if border then
				border:Hide()
				border.SCMStateBorderShown = false
			end
			activeBorders[key] = nil
		end
	end
end

local function ApplyStateOptions(child, skipLayoutRefresh, state)
	state = state or States.GetState(child)
	local config = child.SCMConfig
	local effectRules = config.effectRules

	state.UpdateRequired = false

	if not effectRules then
		if state.Visibility == false then
			state.Visibility = true
			if child.SCMShouldBeVisible ~= true then
				SetChildVisibilityState(child, true, true)
				state.UpdateRequired = true
			end
		else
			state.Visibility = true
		end

		if state.Desaturate ~= nil then
			state.Desaturate = nil
			UpdateChildDesaturation(child, false)
		end
		if state.ActiveStateGlows then
			States.StopStateGlows(child)
		end
		if child.SCMActiveStateBorders then
			HideAllStateBorders(child)
		end

		if state.UpdateRequired and not skipLayoutRefresh then
			SCM:ApplyAnchorGroupCDManagerConfig(child.SCMGroup, nil, child.viewerFrame and child.viewerFrame.SCMUpdateScope)
		end
		return
	end

	local cooldownRuleState = state.Cooldown and "cooldown" or state.Cooldown == false and "ready" or nil
	local activeRuleState = state.Active and "active" or state.Active == false and "inactive" or nil
	local hasRuleState = cooldownRuleState or activeRuleState

	local visibilityRules = effectRules.visibility and effectRules.visibility.rules
	if hasRuleState and visibilityRules and visibilityRules[1] then
		local shouldShow = true
		local rule = GetNextMatchedRule(visibilityRules, 1, cooldownRuleState, activeRuleState)
		if rule then
			shouldShow = rule.value ~= "hide"
		end

		state.Visibility = shouldShow
		if child.SCMShouldBeVisible ~= shouldShow then
			SetChildVisibilityState(child, shouldShow, true)
			state.UpdateRequired = true
		end
	elseif state.Visibility == false then
		state.Visibility = true
		if child.SCMShouldBeVisible ~= true then
			SetChildVisibilityState(child, true, true)
			state.UpdateRequired = true
		end
	else
		state.Visibility = true
	end

	local desaturateRules = effectRules.desaturate and effectRules.desaturate.rules
	local shouldDesaturate
	if hasRuleState and desaturateRules and desaturateRules[1] then
		local rule = GetNextMatchedRule(desaturateRules, 1, cooldownRuleState, activeRuleState)
		if rule and rule.enabled ~= nil then
			shouldDesaturate = rule.enabled and true or false
		end
	end

	if shouldDesaturate ~= nil then
		if state.Desaturate ~= shouldDesaturate then
			state.Desaturate = shouldDesaturate
			UpdateChildDesaturation(child, shouldDesaturate, true)
		end
	elseif state.Desaturate ~= nil then
		state.Desaturate = nil
		UpdateChildDesaturation(child, false)
	end

	if effectRules.glow then
		ApplyGlowRules(child, state, config, effectRules.glow, cooldownRuleState, activeRuleState)
	elseif state.ActiveStateGlows then
		States.StopStateGlows(child)
	end
	if effectRules.border then
		ApplyBorderRules(child, state, config, effectRules.border, cooldownRuleState, activeRuleState)
	elseif child.SCMActiveStateBorders then
		HideAllStateBorders(child)
	end

	if not state.UpdateRequired or skipLayoutRefresh then
		return
	end

	SCM:ApplyAnchorGroupCDManagerConfig(child.SCMGroup, nil, child.viewerFrame and child.viewerFrame.SCMUpdateScope)
end

function States.RefreshStateOptions(child)
	if child and child.SCMConfig then
		ApplyStateOptions(child, true)
	end
end

local function UpdateState(child, updateActive, isActive, updateCooldown, isOnCooldown, skipLayoutRefresh, forceRefresh)
	local config = child and child.SCMConfig
	if not config then
		return false
	end

	local effectRules = config.effectRules
	local state = child.SCMState
	if not effectRules and not (state and (state.Visibility == false or state.Desaturate ~= nil or state.ActiveStateGlows or child.SCMActiveStateBorders)) then
		return false
	end

	state = state or States.GetState(child)
	local changed = (forceRefresh or not effectRules) and true or false

	if updateActive then
		local active
		if isActive ~= nil then
			active = isActive and true or false
		end
		if state.Active ~= active then
			state.Active = active
			changed = true
		end
	end
	if updateCooldown then
		local cooldown
		if isOnCooldown ~= nil then
			cooldown = isOnCooldown and true or false
		end
		if state.Cooldown ~= cooldown then
			state.Cooldown = cooldown
			changed = true
		end
	end

	if not changed then
		return false
	end

	ApplyStateOptions(child, skipLayoutRefresh, state)
	return true
end

function States.SyncState(child, isActive, isOnCooldown, skipLayoutRefresh, forceRefresh)
	return UpdateState(child, isActive ~= nil, isActive, isOnCooldown ~= nil, isOnCooldown, skipLayoutRefresh, forceRefresh)
end

function States.SetCooldownState(child, isOnCooldown)
	return UpdateState(child, false, nil, true, isOnCooldown)
end

function States.SetActiveState(child, isActive)
	return UpdateState(child, true, isActive, false, nil)
end
