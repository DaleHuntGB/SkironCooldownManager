local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM

local iconTypeTabs = {
	all = {
		{ value = "general", text = "General" },
		{ value = "glow", text = "Glow" },
		{ value = "load", text = "Load Conditions" },
	},
	spell = {},
	item = {
		{ value = "items", text = "Items" },
	},
	timer = {},
	slot = {
		{ value = "filter", text = "Filter" },
	},
}
for iconType, options in pairs(iconTypeTabs) do
	if iconType ~= "all" then
		for i = #iconTypeTabs.all, 1, -1 do
			tinsert(options, 1, iconTypeTabs.all[i])
		end
	end
end

function CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	if buttonFrame.data.isCustom then
		SCM:CreateAllCustomIcons(buttonData.iconType)
		SCM:ApplyAnchorGroupCDManagerConfig(anchorIndex, isGlobal)
		return
	end
	Options.ApplyModeConfigUpdate(anchorIndex, mode)
end

function CDMOptions.CreateSpellConfigTabs(scrollFrame, iconSettings, buttonFrame, anchorIndex, mode, isGlobal, isBuffBar)
	local buttonData = buttonFrame.data
	local iconConfig = buttonData.isCustom and SCM:GetConfigTableByID(buttonData.id, buttonData.iconType, isGlobal) or SCM:GetSpellConfigForGroup(buttonData.id, anchorIndex)
	if not iconConfig then
		CDMOptions.ShowIconSettingsMessage(iconSettings, scrollFrame, "|TInterface\\common\\help-i:40:40:0:0|tThis icon could not be resolved for the current anchor.")
		return
	end

	buttonFrame:SetBackdropBorderColor(0, 1, 0, 1)

	if iconConfig then
		local iconSettingsTabs = AceGUI:Create("TabGroup")
		iconSettingsTabs:SetLayout("flow")
		iconSettingsTabs:SetFullWidth(true)
		iconSettingsTabs:SetTabs(isBuffBar and { { value = "general", text = "General" } } or iconTypeTabs[buttonData.iconType])
		iconSettingsTabs:SetCallback("OnGroupSelected", function(self, _, group)
			self:ReleaseChildren()

			if group == "general" then
				CDMOptions.CreateGeneralTabSettings(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "load" then
				CDMOptions.CreateLoadTabSettings(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "glow" then
				CDMOptions.CreateGlowTabSettings(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "state" then
				CDMOptions.CreateStateTabSettings(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "items" then
				CDMOptions:CreateItemTabSettings(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			elseif group == "filter" then
				CDMOptions.CreateFilterTabSettings(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
			end

			iconSettings:DoLayout()
			scrollFrame:DoLayout()
		end)
		iconSettingsTabs:SelectTab("general")
		iconSettings:AddChild(iconSettingsTabs)

		iconSettings:DoLayout()
		scrollFrame:DoLayout()

		return buttonFrame
	end
end
