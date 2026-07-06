local SCM = select(2, ...)
local States = SCM.States
local Icons = SCM.Icons

function States.GetState(child)
	if not child.SCMState then
		child.SCMState = {
			Visibility = true,
			Desaturate = false,
		}
	end

	return child.SCMState
end

function States.SetCooldownState(child, isOnCooldown)
	local state = States.GetState(child)

	local config = child.SCMConfig
	local stateOptions = config.stateOptions

	state.Changed = state.Changed or state.Cooldown ~= isOnCooldown
	state.UpdateRequired = false
	state.Cooldown = isOnCooldown

	if not state.Changed then
		return
	end

	print(child.SCMSpellID, isOnCooldown)
	DevTool:AddData(stateOptions, child.SCMSpellID)
	local options

	if isOnCooldown and stateOptions.cooldown then
		options = stateOptions.cooldown
	elseif not isOnCooldown and stateOptions.ready then
		options = stateOptions.ready
	end

	if options then
		if options.visibility then
			local shouldShow = options.visibility.value == "show"
			print(1, child.SCMShouldBeVisible, shouldShow)
			if child.SCMShouldBeVisible ~= shouldShow then
				state.Visibility = shouldShow
				Icons.SetChildVisibilityState(child, shouldShow, true)
				state.UpdateRequired = true
			end
		end

		if options.desaturate ~= nil then
			state.Desaturate = options.desaturate.enabled
			print("DESATURATE", options.desaturate.enabled)
			Icons.UpdateChildDesaturation(child, options.desaturate.enabled, true)
		end

		if options.glow then
			local subregionOptions = config.subregionOptions
			if subregionOptions and subregionOptions.glow and subregionOptions.glow[options.glow.subregion] then
				local glowOptions = subregionOptions.glow[options.glow.subregion]
				local key = "SCMSubregion" .. glowOptions.typeIndex

				SCM:StartCustomGlow(child, glowOptions.glowTypeOptions[glowOptions.glowType], glowOptions.glowType, key, true)
				state.Glow = key
			end
		elseif state.Glow then
			SCM:StopCustomGlow(child)
		end
	else
		if state.Visibility ~= nil then
			print(2, child.SCMShouldBeVisible, state.Visibility)
			state.Visibility = true
			if child.SCMShouldBeVisible ~= state.Visibility then
				Icons.SetChildVisibilityState(child, state.Visibility, true)
				state.UpdateRequired = true
			end
		end

		if state.Desaturate ~= nil then
			state.Desaturate = nil
			Icons.UpdateChildDesaturation(child, state.Desaturate)
		end

		if state.Glow then
			SCM:StopCustomGlow(child)
		end
	end

	if state.UpdateRequired then
		SCM:ApplyAnchorGroupCDManagerConfig(child.SCMGroup, nil, child.viewerFrame and child.viewerFrame.SCMUpdateScope)
	end
end

function States.SetActiveState(child, isActive)
	local state = States.GetState(child)

	state.Active = state.Changed or state.Cooldown ~= isActive
	state.Active = isActive
end
