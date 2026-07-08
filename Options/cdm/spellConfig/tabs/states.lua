local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local Constants = SCM.Constants
local AceGUI = LibStub("AceGUI-3.0")

local effectTabs = {
	{ value = "visibility", text = "Visibility" },
	{ value = "desaturate", text = "Desaturate" },
	{ value = "glow", text = "Glow" },
	{ value = "border", text = "Border" },
}

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
		name = "Glow",
		allowsMultiple = true,
		subregionType = "glow",
	},
	border = {
		name = "Border",
		allowsMultiple = true,
		subregionType = "border",
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

local function GetRuleStateList(rules, currentRule, iconType, isCustom)
	local usedStates = GetUsedRuleStates(rules, currentRule)
	local states, statesSorted = {}, {}

	local constantStatesSorted = Constants.StatesSorted[iconType] or Constants.StatesSorted.spell
	if isCustom and iconType == "spell" then
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

local function GetFirstUnusedRuleState(rules, iconType, isCustom)
	local constantStatesSorted = Constants.StatesSorted[iconType] or Constants.StatesSorted.spell
	if isCustom and iconType == "spell" then
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
	if not subregionOptions then
		return {}, {}
	end

	local subregions, subregionsSorted = {}, {}
	for index, subregionData in ipairs(subregionOptions) do
		local name = (Constants.Subregions[subregionData.type] or "Subregion") .. " " .. index
		if subregionData.type == "glow" and subregionData.glowType then
			name = (Constants.GlowTypes[subregionData.glowType] or subregionData.glowType) .. " " .. name
		end

		subregions[index] = name
		tinsert(subregionsSorted, index)
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
	end
end

local function AddEffectRule(effectTabGroup, effectKey, rules, buttonData, iconConfig, rule, ruleIndex, applyConfigUpdate)
	local stateDropdown = AceGUI:Create("Dropdown")
	stateDropdown:SetLabel("State")
	stateDropdown:SetRelativeWidth(0.33)
	stateDropdown:SetList(GetRuleStateList(rules, rule, buttonData.iconType, buttonData.isCustom))
	stateDropdown:SetValue(rule.state)
	stateDropdown:SetCallback("OnValueChanged", function(_, _, value)
		rule.state = value
		applyConfigUpdate()
		effectTabGroup:SelectTab(effectKey)
	end)
	effectTabGroup:AddChild(stateDropdown)

	AddRuleValueControl(effectTabGroup, effectKey, iconConfig, rule, applyConfigUpdate)

	local elseIf = AceGUI:Create("CheckBox")
	elseIf:SetLabel("Else If")
	elseIf:SetRelativeWidth(0.33)
	elseIf:SetValue(rule.elseIf)
	elseIf:SetDisabled(ruleIndex == 1)
	elseIf:SetCallback("OnValueChanged", function(_, _, value)
		rule.elseIf = value or nil
		applyConfigUpdate()
	end)
	effectTabGroup:AddChild(elseIf)

	local moveUp = AceGUI:Create("Button")
	moveUp:SetText("Move Up")
	moveUp:SetRelativeWidth(0.33)
	moveUp:SetDisabled(ruleIndex == 1)
	moveUp:SetCallback("OnClick", function()
		local previousRule = rules[ruleIndex - 1]
		rules[ruleIndex - 1] = rule
		rules[ruleIndex] = previousRule
		applyConfigUpdate()
		effectTabGroup:SelectTab(effectKey)
	end)
	effectTabGroup:AddChild(moveUp)

	local moveDown = AceGUI:Create("Button")
	moveDown:SetText("Move Down")
	moveDown:SetRelativeWidth(0.33)
	moveDown:SetDisabled(ruleIndex == #rules)
	moveDown:SetCallback("OnClick", function()
		local nextRule = rules[ruleIndex + 1]
		rules[ruleIndex + 1] = rule
		rules[ruleIndex] = nextRule
		applyConfigUpdate()
		effectTabGroup:SelectTab(effectKey)
	end)
	effectTabGroup:AddChild(moveDown)

	local remove = AceGUI:Create("Button")
	remove:SetText("Remove")
	remove:SetRelativeWidth(0.33)
	remove:SetCallback("OnClick", function()
		tremove(rules, ruleIndex)
		applyConfigUpdate()
		effectTabGroup:SelectTab(effectKey)
	end)
	effectTabGroup:AddChild(remove)
end

local function AddEffectOptions(effectKey, effectTabGroup, buttonData, iconConfig, ApplyConfigUpdate)
	local effectConfig = iconConfig.effectRules and iconConfig.effectRules[effectKey]
	local rules = effectConfig and effectConfig.rules

	if rules and #rules > 0 then
		for ruleIndex, rule in ipairs(rules) do
			if ruleIndex > 1 then
				local separator = AceGUI:Create("Heading")
				separator:SetText("")
				separator:SetRelativeWidth(1)
				effectTabGroup:AddChild(separator)
			end
			AddEffectRule(effectTabGroup, effectKey, rules, buttonData, iconConfig, rule, ruleIndex, ApplyConfigUpdate)
		end

		local separator = AceGUI:Create("Heading")
		separator:SetText("")
		separator:SetRelativeWidth(1)
		effectTabGroup:AddChild(separator)
	end

	local firstUnusedRuleState = GetFirstUnusedRuleState(rules, buttonData.iconType, buttonData.isCustom)
	local addRule = AceGUI:Create("Button")
	addRule:SetText("Add Rule")
	addRule:SetRelativeWidth(0.33)
	addRule:SetDisabled(firstUnusedRuleState == nil)
	addRule:SetCallback("OnClick", function()
		if not firstUnusedRuleState then
			return
		end

		iconConfig.effectRules = iconConfig.effectRules or {}

		effectConfig = iconConfig.effectRules[effectKey]
		if not effectConfig then
			effectConfig = {
				rules = {},
			}
			iconConfig.effectRules[effectKey] = effectConfig
		end

		rules = effectConfig.rules
		if not rules then
			rules = {}
			effectConfig.rules = rules
		end

		local rule = {
			state = firstUnusedRuleState,
		}
		if #rules > 0 and not effectOptions[effectKey].allowsMultiple then
			rule.elseIf = true
		end
		SetDefaultRuleValues(rule, effectKey, iconConfig)
		tinsert(rules, rule)
		ApplyConfigUpdate()
		effectTabGroup:SelectTab(effectKey)
	end)
	effectTabGroup:AddChild(addRule)
end

function CDMOptions.CreateStateTabSettings(iconSettingsTabs, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
	if isBuffBar then
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

	local effectTabGroup = AceGUI:Create("TabGroup")
	effectTabGroup:SetLayout("flow")
	effectTabGroup:SetFullWidth(true)
	effectTabGroup:SetTabs(effectTabs)
	effectTabGroup:SetCallback("OnGroupSelected", function(self, _, selectedTab)
		self:ReleaseChildren()
		if not selectedTab then
			return
		end

		AddEffectOptions(selectedTab, self, buttonData, iconConfig, ApplyConfigUpdate)
		iconSettings:DoLayout()
		parentScrollFrame:DoLayout()
	end)
	scrollFrame:AddChild(effectTabGroup)
	effectTabGroup:SelectTab("visibility")
end
