--[[-----------------------------------------------------------------------------
ScrollFrame Container
Plain container that scrolls its content and doesn't grow in height.
-------------------------------------------------------------------------------]]

local Type, Version = "SCMVerticalScrollFrame", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
	return
end

local pairs, ipairs = pairs, ipairs
local abs, min, max = math.abs, math.min, math.max
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

local function UpdateMarkerPosition(frame, draggedY, marker)
	local top = frame:GetTop()
	local bottom = frame:GetBottom()
	local centerY = (top + bottom) / 2
	marker:ClearAllPoints()

	if draggedY >= centerY then
		marker:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 1)
		marker:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 1)
		return false
	else
		marker:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -1)
		marker:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -1)
		return true
	end
end

local function FindBestTarget(scrollView, draggedY, draggedFrame)
	local best, bestDistance
	scrollView:ForEachFrame(function(frame)
		if frame:IsShown() and frame ~= draggedFrame then
			local _, centerY = frame:GetCenter()
			local distance = abs(centerY - draggedY)
			if not bestDistance or distance < bestDistance then
				best = frame
				bestDistance = distance
			end
		end
	end)

	return best
end

local function GetDestinationIndex(sourceIndex, targetIndex, after)
	if sourceIndex < targetIndex then
		targetIndex = targetIndex - 1
	end

	if after then
		targetIndex = targetIndex + 1
	end

	return targetIndex
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]

local function Controller_OnUpdate(self)
	if not self.draggedFrame then
		return
	end

	local _, draggedY = self:GetCenter()
	local target = FindBestTarget(self.scrollView, draggedY, self.draggedFrame)
	if not target then
		self.marker:Hide()
		self.destinationIndex = nil
		return
	end

	self.marker:Show()
	local after = UpdateMarkerPosition(target, draggedY, self.marker)
	local targetIndex = self.dataProvider:FindIndex(target.data)
	self.destinationIndex = GetDestinationIndex(self.sourceIndex, targetIndex, after)
end

local function Button_OnDragStart(self)
	if self.dataProvider:GetSize() < 2 then
		return
	end

	self.obj:CancelDrag()
	self:StartMoving()
	self:SetAlpha(0)
	self.obj:PauseLayout()
	self.obj.dragInProgress = true

	local controller = self.controller
	controller.draggedFrame = self
	controller.draggedData = self.data
	controller.sourceIndex = self.dataProvider:FindIndex(self.data)
	controller.destinationIndex = controller.sourceIndex
	controller.marker:Hide()

	controller:Show()
	controller.Icon:SetTexture(self.data.texture or 134400)
	controller:ClearAllPoints()
	controller:SetPoint("LEFT", self, "LEFT", 4, 0)
	controller:SetScript("OnUpdate", Controller_OnUpdate)
end

local function Button_OnDragStop(self)
	self:StopMovingOrSizing()
	self:SetAlpha(1)

	local obj = self.obj
	local controller = self.controller
	local dataProvider = self.dataProvider

	local sourceData = controller.draggedData
	local sourceIndex = controller.sourceIndex
	local destinationIndex = controller.destinationIndex

	controller.draggedFrame = nil
	controller.draggedData = nil
	controller.sourceIndex = nil
	controller.destinationIndex = nil
	controller.marker:Hide()
	controller:SetScript("OnUpdate", nil)
	controller:Hide()

	if sourceData and destinationIndex then
		if sourceIndex == destinationIndex then
			self.scrollBox:Layout()
			obj.dragInProgress = nil
			obj:ResumeLayout()
			return
		end

		destinationIndex = max(1, min(dataProvider:GetSize(), destinationIndex))

		if dataProvider:FindIndex(sourceData) then
			local scrollOffset = self.scrollBox:GetDerivedScrollOffset()
			dataProvider:MoveElementDataToIndex(sourceData, destinationIndex)

			for i, entry in ipairs(dataProvider:GetCollection()) do
				entry.dataIndex = i
			end

			self.obj:Fire("OnDragStop", dataProvider:GetCollection())
			self.scrollBox:ScrollToOffset(scrollOffset, true)
		end
	end

	self.scrollBox:Layout()
	obj.dragInProgress = nil
	obj:ResumeLayout()
end

local function ScrollBar_OnScrollValueChanged(self, value)
	self.scrollBox:SetScrollPercentage(value / 1000, true)
end

local function ScrollBox_OnScroll(scrollbar, scrollPercentage)
	scrollbar:SetValue(scrollPercentage * 1000)
	scrollbar:SetShown(scrollbar.scrollBox:GetDerivedScrollRange() > 0)
end

local function RemoveButton_OnClick(self)
	local button = self:GetParent()
	button.obj:Fire("OnRemove", button.data)
end

local function Frame_OnHide(self)
	self.obj:CancelDrag()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]

local methods = {
	["OnAcquire"] = function(self)
		self.dataProvider:Flush()
		self.scrollBox:ScrollToBegin(true)
	end,

	["OnRelease"] = function(self)
		self:CancelDrag()
		self.dataProvider:Flush()
	end,

	["OnWidthSet"] = function(self, width)
		self.frame:SetWidth(width)
	end,

	["OnHeightSet"] = function(self, height)
		self.frame:SetHeight(height)
	end,

	["CancelDrag"] = function(self)
		local controller = self.controller
		local draggedFrame = controller.draggedFrame

		if draggedFrame then
			draggedFrame:StopMovingOrSizing()
			draggedFrame:SetAlpha(1)
		end
		self.dragInProgress = nil
		self:ResumeLayout()

		controller.draggedFrame = nil
		controller.draggedData = nil
		controller.sourceIndex = nil
		controller.destinationIndex = nil
		controller:SetScript("OnUpdate", nil)
		controller.marker:Hide()
		controller:Hide()

		if draggedFrame then
			self.scrollBox:Layout()
		end
	end,

	["SetEntries"] = function(self, entries)
		self:CancelDrag()

		local scrollOffset = self.scrollBox:GetDerivedScrollOffset()

		self.dataProvider:Flush()
		self.dataProvider:InsertTable(entries)

		self.scrollBox:ScrollToOffset(scrollOffset, true)
	end,

	["InitButton"] = function(self, button, data)
		button.controller = self.controller
		button.scrollBox = self.scrollBox
		button.dataProvider = self.dataProvider
		button.obj = self

		button.dataIndex = data.dataIndex
		button.data = data

		button:SetAlpha(data == self.controller.draggedData and 0 or 1)
		button.Text:SetText(data.text)

		button:RegisterForDrag("LeftButton")
		button:SetMovable(true)
		button:SetScript("OnDragStart", Button_OnDragStart)
		button:SetScript("OnDragStop", Button_OnDragStop)

		button.RemoveButton:SetText("Delete")
		button.RemoveButton:SetScript("OnClick", RemoveButton_OnClick)
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetHeight(300)
	frame:SetWidth(300)
	frame:SetScript("OnHide", Frame_OnHide)

	local dataProvider = CreateDataProvider()
	local scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
	local content = CreateFrame("Frame", nil, scrollBox)
	content:SetAllPoints(scrollBox)

	local name = (Type .. "%dScrollBar"):format(AceGUI:GetNextWidgetNum(Type))
	local scrollbar = CreateFrame("Slider", name, frame, "UIPanelScrollBarTemplate")
	scrollbar:SetScript("OnValueChanged", nil)
	scrollBox:SetPoint("TOPLEFT", frame, "TOPLEFT")
	scrollBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 0)
	scrollbar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -16)
	scrollbar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 16)

	scrollbar:SetWidth(16)
	scrollbar:SetMinMaxValues(0, 1000)
	scrollbar:SetValueStep(1)
	scrollbar:SetValue(0)
	scrollbar:Hide()

	scrollbar.scrollBox = scrollBox
	scrollbar:SetScript("OnValueChanged", ScrollBar_OnScrollValueChanged)

	local scrollbg = scrollbar:CreateTexture(nil, "BACKGROUND")
	scrollbg:SetAllPoints(scrollbar)
	scrollbg:SetColorTexture(0, 0, 0, 0.4)

	local scrollView = CreateScrollBoxListLinearView(4, 4, 0, 0, 3)
	scrollView:SetElementExtent(44)

	local controller = CreateFrame("Frame", nil, UIParent)
	controller:SetSize(30, 30)
	controller:SetFrameStrata("TOOLTIP")
	controller:Hide()
	controller.scrollView = scrollView
	controller.dataProvider = dataProvider

	controller.Icon = controller:CreateTexture(nil, "ARTWORK")
	controller.Icon:SetAllPoints()
	controller.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	local markerFrame = CreateFrame("Frame", nil, scrollBox)
	markerFrame:SetHeight(2)
	markerFrame:SetFrameLevel(scrollBox:GetFrameLevel() + 10)
	markerFrame:Hide()

	local marker = markerFrame:CreateTexture(nil, "OVERLAY")
	marker:SetAllPoints()
	marker:SetColorTexture(1, 1, 1, 0.8)
	controller.marker = markerFrame

	scrollView:SetElementInitializer("SCMVerticalScrollRowTemplate", function(button, data)
		frame.obj:InitButton(button, data)
	end)

	scrollBox:RegisterCallback(BaseScrollBoxEvents.OnScroll, ScrollBox_OnScroll, scrollbar)
	scrollBox:Init(scrollView)
	scrollView:SetDataProvider(dataProvider)

	local widget = {
		content = content,
		scrollbar = scrollbar,
		scrollView = scrollView,
		scrollBox = scrollBox,
		controller = controller,
		dataProvider = dataProvider,
		frame = frame,
		type = Type,
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
