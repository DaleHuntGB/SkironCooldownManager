--[[-----------------------------------------------------------------------------
InteractiveLabel Widget
-------------------------------------------------------------------------------]]
local Type, Version = "SCMHeaderButton", 21
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
	return
end

-- Lua APIs
local select, pairs = select, pairs

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
end

local function Label_OnClick(frame, button)
	frame.obj:Fire("OnClick", button)
	AceGUI:ClearFocus()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:LabelOnAcquire()
		self:SetHighlight()
		self:SetHighlightTexCoord()
		self:SetDisabled(false)
	end,

	-- ["OnRelease"] = nil,

	["SetHighlight"] = function(self, ...)
		self.highlight:SetTexture(...)
	end,

	["SetHighlightTexCoord"] = function(self, ...)
		local c = select("#", ...)
		if c == 4 or c == 8 then
			self.highlight:SetTexCoord(...)
		else
			self.highlight:SetTexCoord(0, 1, 0, 1)
		end
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.frame:EnableMouse(false)
			self.label:SetTextColor(0.5, 0.5, 0.5)
		else
			self.frame:EnableMouse(true)
			self.label:SetTextColor(1, 1, 1)
		end
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	-- create a Label type that we will hijack
	local num = AceGUI:GetNextWidgetNum(Type)
	local button = CreateFrame("Button", ("Type%d"):format(num), UIParent, "OptionsListButtonTemplate")
	button:SetHeight(20)
	button:SetWidth(500)

	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight.blp")
	bg:SetBlendMode("ADD")
	bg:SetVertexColor(0.5, 0.5, 0.5, 0.6)
	bg:SetAllPoints(button)

	local toggle = button.toggle
	toggle:SetNormalTexture(130838) -- Interface\\Buttons\\UI-PlusButton-UP
	toggle:SetPushedTexture(130836) -- Interface\\Buttons\\UI-PlusButton-DOWN
	toggle:Show()

	local widget = {
		text = button.text,
		frame = button,
		toggle = button.toggle,
		type = Type,
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
