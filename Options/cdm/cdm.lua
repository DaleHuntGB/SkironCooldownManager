local SCM = select(2, ...)
local Options = SCM.Options

Options.CDM = {}
local CDMOptions = Options.CDM

local AceGUI = LibStub("AceGUI-3.0")
local Utils = SCM.Utils
local CustomIcons = SCM.CustomIcons
local Constants = SCM.Constants

SCM.MainTabs.CDM = { value = "CDM", text = "Cooldown Manager", order = 2, subgroups = {} }

function CDMOptions.ShowIconSettingsMessage(parentWidget, scrollFrame, message)
	parentWidget:SetTitle("")

	local label = AceGUI:Create("Label")
	label:SetRelativeWidth(1.0)
	label:SetHeight(24)
	label:SetJustifyH("CENTER")
	label:SetJustifyV("MIDDLE")
	label:SetText(message)
	label:SetFontObject("Game12Font")
	parentWidget:AddChild(label)

	parentWidget:DoLayout()
	scrollFrame:DoLayout()
end

local function CDM(self, frame, group)
	local modeTabs = AceGUI:Create("TabGroup")
	modeTabs:SetLayout("fill")
	modeTabs:SetFullWidth(true)
	modeTabs:SetFullHeight(true)

	local tabs = {
		{ value = "spec", text = "|cFFFFFFFFSpecialization|r: Icons" },
		{ value = "buffbars", text = "|cFFFFFFFFSpecialization|r: Bars" },
		{ value = "global", text = "|cFFFFFFFFGlobal|r: Icons" },
		{ value = "copy", text = "|cFFFFFFFFCopy|r Anchors" },
	}

	modeTabs:SetTabs(tabs)
	modeTabs:SetCallback("OnGroupSelected", function(widget, event, mode)
		if mode == "copy" then
			CreateCopyAnchorTab(widget, frame, modeTabs)
		else
			CreateAnchorTabGroup(widget, frame, mode)
		end
	end)
	modeTabs:SelectTab("spec")
	self:AddChild(modeTabs)

	self.typeTab = modeTabs
end

SCM.MainTabs.CDM.callback = CDM
