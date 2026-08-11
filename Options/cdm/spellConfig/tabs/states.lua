local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local Constants = SCM.Constants
local AceGUI = LibStub("AceGUI-3.0")

local effectOptions = {
	visibility = {
		name = "Visibility",
		defaultValue = "show",
	},
	desaturate = {
		name = "Desaturate",
		defaultEnabled = true,
	},
	glow = {
		name = "Glow Settings",
		allowsMultiple = true,
		subregionType = "glow",
	},
	border = {
		name = "Border Settings",
		allowsMultiple = true,
		subregionType = "border",
	},
	cooldown = {
		name = "Cooldown Swipe",
	},
}

local function SetDefaultRuleValues(rule, effectKey, iconConfig)
	local option = effectOptions[effectKey]

	if effectKey == "visibility" then
		rule.value = rule.value or option.defaultValue
	elseif effectKey == "desaturate" then
		if rule.enabled == nil then
			rule.enabled = option.defaultEnabled
		end
	elseif effectKey == "cooldown" then
		if rule.drawEdge == nil then
			rule.drawEdge = false
		end
		if rule.drawSwipe == nil then
			rule.drawSwipe = true
		end
		if rule.reverse == nil then
			rule.reverse = false
		end
		rule.edgeColor = rule.edgeColor or { r = 1, g = 0.7, b = 0, a = 1 }
		rule.swipeColor = rule.swipeColor or { r = 0, g = 0, b = 0, a = 0.7 }
	elseif effectKey == "glow" and not rule.subregion then
		rule.subregion = Constants.GlobalGlowSubregion
	elseif option.subregionType and not rule.subregion then
		local subregions = iconConfig.subregionOptions and iconConfig.subregionOptions[option.subregionType]
		if subregions and subregions[1] then
			rule.subregion = 1
		end
	end
end

local function GetUsedRuleStates(rules, currentRule)
	local usedStates = {}
	if not rules then
		return usedStates
	end

	for _, rule in ipairs(rules) do
		if rule ~= currentRule and rule.state then
			usedStates[rule.state] = true
		end
	end

	return usedStates
end

local function GetRuleStateList(rules, currentRule, buttonData, isBuffBar)
	local usedStates = GetUsedRuleStates(rules, currentRule)
	local states, statesSorted = {}, {}

	local iconType = buttonData.iconType
	local constantStatesSorted = isBuffBar and Constants.StatesSorted.buffBar or Constants.StatesSorted[iconType] or Constants.StatesSorted.spell
	if buttonData.isBuffIcon then
		constantStatesSorted = Constants.StatesSorted.buffIcon
	elseif not isBuffBar and buttonData.isCustom and iconType == "spell" then
		constantStatesSorted = Constants.StatesSorted.custom
	end

	for _, stateKey in ipairs(constantStatesSorted) do
		if stateKey == currentRule.state or not usedStates[stateKey] then
			states[stateKey] = Constants.States[stateKey]
			tinsert(statesSorted, stateKey)
		end
	end

	return states, statesSorted
end

local function GetAvailableRuleState(rules, buttonData, isBuffBar)
	local iconType = buttonData.iconType
	local constantStatesSorted = isBuffBar and Constants.StatesSorted.buffBar or Constants.StatesSorted[iconType] or Constants.StatesSorted.spell
	if buttonData.isBuffIcon then
		constantStatesSorted = Constants.StatesSorted.buffIcon
	elseif not isBuffBar and buttonData.isCustom and iconType == "spell" then
		constantStatesSorted = Constants.StatesSorted.custom
	end

	local usedStates = GetUsedRuleStates(rules)
	for _, stateKey in ipairs(constantStatesSorted) do
		if not usedStates[stateKey] then
			return stateKey
		end
	end
end

local function GetSubregionList(iconConfig, subregionType)
	local subregionOptions = iconConfig.subregionOptions and iconConfig.subregionOptions[subregionType]
	local subregions, subregionsSorted = {}, {}

	if subregionType == "glow" then
		subregions[Constants.GlobalGlowSubregion] = "Global Glow"
		tinsert(subregionsSorted, Constants.GlobalGlowSubregion)
	end

	if subregionOptions then
		for index, subregionData in ipairs(subregionOptions) do
			local name = (Constants.Subregions[subregionData.type] or "Subregion") .. " " .. index
			if subregionData.type == "glow" and subregionData.glowType then
				name = (Constants.GlowTypes[subregionData.glowType] or subregionData.glowType) .. " " .. name
			end

			subregions[index] = name
			tinsert(subregionsSorted, index)
		end
	end

	return subregions, subregionsSorted
end

local function AddRuleValueControl(effectTabGroup, effectKey, iconConfig, rule, applyConfigUpdate)
	local option = effectOptions[effectKey]
	SetDefaultRuleValues(rule, effectKey, iconConfig)

	if effectKey == "visibility" then
		local valueDropdown = AceGUI:Create("Dropdown")
		valueDropdown:SetLabel("Value")
		valueDropdown:SetRelativeWidth(0.33)
		valueDropdown:SetList(Constants.Visibility, Constants.VisibilitySorted)
		valueDropdown:SetValue(rule.value)
		valueDropdown:SetCallback("OnValueChanged", function(_, _, value)
			rule.value = value
			applyConfigUpdate()
		end)
		effectTabGroup:AddChild(valueDropdown)
	elseif effectKey == "desaturate" then
		local enabled = AceGUI:Create("CheckBox")
		enabled:SetLabel("Enabled")
		enabled:SetRelativeWidth(0.33)
		enabled:SetValue(rule.enabled)
		enabled:SetCallback("OnValueChanged", function(_, _, value)
			rule.enabled = value and true or false
			applyConfigUpdate()
		end)
		effectTabGroup:AddChild(enabled)
	elseif effectKey == "cooldown" then
		local drawSwipe = AceGUI:Create("CheckBox")
		drawSwipe:SetLabel("Draw Swipe")
		drawSwipe:SetRelativeWidth(0.25)
		drawSwipe:SetValue(rule.drawSwipe)
		drawSwipe:SetCallback("OnValueChanged", function(_, _, value)
			rule.drawSwipe = value and true or false
			applyConfigUpdate()
		end)
		effectTabGroup:AddChild(drawSwipe)

		local swipeColor = AceGUI:Create("ColorPicker")
		swipeColor:SetLabel("Swipe Color")
		swipeColor:SetRelativeWidth(0.33)
		swipeColor:SetHasAlpha(true)
		swipeColor:SetColor(rule.swipeColor.r, rule.swipeColor.g, rule.swipeColor.b, rule.swipeColor.a)
		swipeColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
			rule.swipeColor = { r = r, g = g, b = b, a = a }
			applyConfigUpdate()
		end)
		effectTabGroup:AddChild(swipeColor)

		local drawEdge = AceGUI:Create("CheckBox")
		drawEdge:SetLabel("Draw Edge")
		drawEdge:SetRelativeWidth(0.25)
		drawEdge:SetValue(rule.drawEdge)
		drawEdge:SetCallback("OnValueChanged", function(_, _, value)
			rule.drawEdge = value and true or false
			applyConfigUpdate()
		end)
		effectTabGroup:AddChild(drawEdge)

		local reverse = AceGUI:Create("CheckBox")
		reverse:SetLabel("Reverse")
		reverse:SetRelativeWidth(0.25)
		reverse:SetValue(rule.reverse)
		reverse:SetCallback("OnValueChanged", function(_, _, value)
			rule.reverse = value and true or false
			applyConfigUpdate()
		end)
		effectTabGroup:AddChild(reverse)

		local edgeColor = AceGUI:Create("ColorPicker")
		edgeColor:SetLabel("Edge Color")
		edgeColor:SetRelativeWidth(0.25)
		edgeColor:SetHasAlpha(true)
		edgeColor:SetColor(rule.edgeColor.r, rule.edgeColor.g, rule.edgeColor.b, rule.edgeColor.a)
		edgeColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
			rule.edgeColor = { r = r, g = g, b = b, a = a }
			applyConfigUpdate()
		end)
		effectTabGroup:AddChild(edgeColor)
	elseif option.subregionType then
		local subregionDropdown = AceGUI:Create("Dropdown")
		subregionDropdown:SetLabel(option.name)
		subregionDropdown:SetRelativeWidth(0.33)
		subregionDropdown:SetList(GetSubregionList(iconConfig, option.subregionType))
		subregionDropdown:SetValue(rule.subregion)
		subregionDropdown:SetCallback("OnValueChanged", function(_, _, value)
			rule.subregion = value
			applyConfigUpdate()
		end)
		effectTabGroup:AddChild(subregionDropdown)

		local subregionTargetDropdown = AceGUI:Create("Dropdown")
		subregionTargetDropdown:SetLabel("Target")
		subregionTargetDropdown:SetRelativeWidth(0.33)
		subregionTargetDropdown:SetList(Constants.SubregionTargets, Constants.SubregionTargetsSorted)
		subregionTargetDropdown:SetValue(rule.subregionTargetType or "self")
		effectTabGroup:AddChild(subregionTargetDropdown)

		local targetEditBox = AceGUI:Create("EditBox")
		targetEditBox:SetLabel("Frame")
		targetEditBox:SetRelativeWidth(0.66)
		targetEditBox:SetText(rule.subregionTargetCustom or "")
		targetEditBox:SetCallback("OnEnterPressed", function(_, _, value)
			rule.subregionTargetCustom = value
			applyConfigUpdate()
		end)
		targetEditBox:SetDisabled(not ((rule.subregionTargetType or "self") == "custom"))
		effectTabGroup:AddChild(targetEditBox)
		Options.AddAnchorParentAutocomplete(effectTabGroup, targetEditBox, function(value)
			rule.subregionTargetCustom = value
			applyConfigUpdate()
		end)

		subregionTargetDropdown:SetCallback("OnValueChanged", function(_, _, value)
			rule.subregionTargetType = value

			targetEditBox:SetDisabled(not (value == "custom"))
			applyConfigUpdate()
		end)
	end
end

local function AddEffectRule(iconSettingsTabs, stateType, container, rules, buttonData, iconConfig, rule, ruleIndex, applyConfigUpdate, isBuffBar)
	local stateDropdown = AceGUI:Create("Dropdown")
	stateDropdown:SetLabel("State")
	stateDropdown:SetRelativeWidth(0.33)
	stateDropdown:SetList(GetRuleStateList(rules, rule, buttonData, isBuffBar))
	stateDropdown:SetValue(rule.state)
	stateDropdown:SetCallback("OnValueChanged", function(_, _, value)
		rule.state = value
		applyConfigUpdate()
		iconSettingsTabs:SelectByPath("state", stateType)
	end)
	container:AddChild(stateDropdown)

	AddRuleValueControl(container, stateType, iconConfig, rule, applyConfigUpdate)

	local elseIf = AceGUI:Create("CheckBox")
	elseIf:SetLabel("Else If")
	elseIf:SetRelativeWidth(stateType == "cooldown" and 0.25 or 0.33)
	elseIf:SetValue(rule.elseIf)
	elseIf:SetDisabled(ruleIndex == 1)
	elseIf:SetCallback("OnValueChanged", function(_, _, value)
		rule.elseIf = value or nil
		applyConfigUpdate()
	end)
	container:AddChild(elseIf)

	local moveUp = AceGUI:Create("Button")
	moveUp:SetText("Move Up")
	moveUp:SetRelativeWidth(0.33)
	moveUp:SetDisabled(ruleIndex == 1)
	moveUp:SetCallback("OnClick", function()
		local previousRule = rules[ruleIndex - 1]
		rules[ruleIndex - 1] = rule
		rules[ruleIndex] = previousRule
		applyConfigUpdate()
		iconSettingsTabs:SelectByPath("state", stateType)
	end)
	container:AddChild(moveUp)

	local moveDown = AceGUI:Create("Button")
	moveDown:SetText("Move Down")
	moveDown:SetRelativeWidth(0.33)
	moveDown:SetDisabled(ruleIndex == #rules)
	moveDown:SetCallback("OnClick", function()
		local nextRule = rules[ruleIndex + 1]
		rules[ruleIndex + 1] = rule
		rules[ruleIndex] = nextRule
		applyConfigUpdate()
		iconSettingsTabs:SelectByPath("state", stateType)
	end)
	container:AddChild(moveDown)

	local remove = AceGUI:Create("Button")
	remove:SetText("Remove")
	remove:SetRelativeWidth(0.33)
	remove:SetCallback("OnClick", function()
		tremove(rules, ruleIndex)
		applyConfigUpdate()
		iconSettingsTabs:SelectByPath("state", stateType)
	end)
	container:AddChild(remove)
end

local function AddEffectOptions(iconSettingsTabs, stateType, container, buttonData, iconConfig, ApplyConfigUpdate, isBuffBar)
	local effectConfig = iconConfig.effectRules and iconConfig.effectRules[stateType]
	local rules = effectConfig and effectConfig.rules

	if rules and #rules > 0 then
		for ruleIndex, rule in ipairs(rules) do
			if ruleIndex > 1 then
				local separator = AceGUI:Create("Heading")
				separator:SetText("")
				separator:SetRelativeWidth(1)
				container:AddChild(separator)
			end
			AddEffectRule(iconSettingsTabs, stateType, container, rules, buttonData, iconConfig, rule, ruleIndex, ApplyConfigUpdate, isBuffBar)
		end

		local separator = AceGUI:Create("Heading")
		separator:SetText("")
		separator:SetRelativeWidth(1)
		container:AddChild(separator)
	end

	local ruleState = GetAvailableRuleState(rules, buttonData, isBuffBar)
	local addRule = AceGUI:Create("Button")
	addRule:SetText("Add Rule")
	addRule:SetRelativeWidth(0.33)
	addRule:SetDisabled(ruleState == nil)
	addRule:SetCallback("OnClick", function()
		if not ruleState then
			return
		end

		iconConfig.effectRules = iconConfig.effectRules or {}

		effectConfig = iconConfig.effectRules[stateType]
		if not effectConfig then
			effectConfig = {
				rules = {},
			}
			iconConfig.effectRules[stateType] = effectConfig
		end

		rules = effectConfig.rules
		if not rules then
			rules = {}
			effectConfig.rules = rules
		end

		local rule = {
			state = ruleState,
		}

		SetDefaultRuleValues(rule, stateType, iconConfig)
		tinsert(rules, rule)
		ApplyConfigUpdate()
		iconSettingsTabs:SelectByPath("state", stateType)
	end)
	container:AddChild(addRule)
end

function CDMOptions.CreateStateTabSettings(iconSettingsTabs, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar, stateType)
	if not effectOptions[stateType] then
		return
	end

	local function ApplyConfigUpdate()
		CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar, true)
	end

	local rootGroup = AceGUI:Create("SimpleGroup")
	rootGroup:SetLayout("fill")
	rootGroup:SetFullWidth(true)
	rootGroup:SetFullHeight(true)
	iconSettingsTabs:AddChild(rootGroup)

	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("flow")
	scrollFrame:SetFullWidth(true)
	scrollFrame:SetFullHeight(true)
	rootGroup:AddChild(scrollFrame)

	AddEffectOptions(iconSettingsTabs, stateType, scrollFrame, buttonData, iconConfig, ApplyConfigUpdate, isBuffBar)
end
