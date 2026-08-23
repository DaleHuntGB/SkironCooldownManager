--[[-----------------------------------------------------------------------------
ScrollFrame Container
Plain container that scrolls its content and doesn't grow in height.
-------------------------------------------------------------------------------]]

local Type, Version = "SCMHorizontalScrollFrame", 4
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then
	return
end

local COOLDOWN_CONFIG_KEY_PREFIX = "cooldown:"

-- Lua APIs
local pairs, ipairs = pairs, ipairs
local abs, min, max = math.abs, math.min, math.max

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

local function UpdateMarkerPosition(frame, draggedX, marker)
	local left = frame:GetLeft()
	local right = frame:GetRight()
	local centerX = (left + right) / 2
	marker:ClearAllPoints()

	if draggedX < centerX then
		marker:SetPoint("CENTER", frame, "LEFT", -3, 0)
		return false -- before
	else
		marker:SetPoint("CENTER", frame, "RIGHT", 3, 0)
		return true -- after
	end
end

local function FindBestTarget(scrollView, draggedX, draggedFrame)
	local best, bestDistance
	scrollView:ForEachFrame(function(frame)
		if frame:IsShown() and frame ~= draggedFrame and not frame.data.isAddButton then
			local centerX = frame:GetCenter()
			local distance = abs(centerX - draggedX)
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

	local draggedX = self:GetCenter()
	local target = FindBestTarget(self.scrollView, draggedX, self.draggedFrame)
	if not target then
		self.marker:Hide()
		self.destinationIndex = nil
		return
	end

	self.marker:Show()
	local after = UpdateMarkerPosition(target, draggedX, self.marker)
	local targetIndex = self.dataProvider:FindIndex(target.data)
	self.destinationIndex = GetDestinationIndex(self.sourceIndex, targetIndex, after)
end

local function Button_OnDragStart(self)
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
	controller.Icon:SetTexture(self.data.texture)
	controller:ClearAllPoints()
	controller:SetPoint("CENTER", self, "CENTER")
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
			local sortComparator = dataProvider.sortComparator
			dataProvider:ClearSortComparator()
			dataProvider:MoveElementDataToIndex(sourceData, destinationIndex)

			for i, entry in ipairs(dataProvider:GetCollection()) do
				if not entry.isAddButton then
					entry.dataIndex = i
				end
			end

			self.obj:Fire("OnDragStop", dataProvider:GetCollection())
			dataProvider:SetSortComparator(sortComparator)
		end
	end

	self.scrollBox:Layout()
	obj.dragInProgress = nil
	obj:ResumeLayout()
end

local function Button_OnClick(self, button, down)
	if down then
		self.obj:Fire("OnGroupSelected", self, button)
	end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self.dataProvider:ClearSortComparator()
		self.dataProvider:Flush()
	end,

	["OnRelease"] = function(self)
		self.dataProvider:Flush()
		self.dragInProgress = nil
		self:ResumeLayout()

		local controller = self.controller
		controller.draggedFrame = nil
		controller.draggedData = nil
		controller.sourceIndex = nil
		controller.destinationIndex = nil
		controller:SetScript("OnUpdate", nil)
		controller.marker:Hide()
		controller:Hide()
	end,

	["OnWidthSet"] = function(self, width)
		self.frame:SetWidth(width)
	end,

	["OnHeightSet"] = function(self, height)
		self.frame:SetHeight(height)
	end,

	["AddSpellBySpellID"] = function(self, info, dataIndex, isBuffIcon, texture)
		if not dataIndex then
			local highestIndex = 0
			for _, data in self.dataProvider:Enumerate() do
				if data.dataIndex > highestIndex and data.dataIndex < 100 then
					highestIndex = data.dataIndex
				end
			end
			self.dataProvider.highestIndex = highestIndex
			dataIndex = highestIndex + 1
		end

		local spellID = info.spellID
		if info.linkedSpellIDs and #info.linkedSpellIDs == 1 then
			spellID = info.linkedSpellIDs[1]
		end
		local configID = info.configID or (info.cooldownID and (COOLDOWN_CONFIG_KEY_PREFIX .. tostring(info.cooldownID)))
		if not configID then
			return dataIndex
		end

		self.dataProvider:Insert({
			id = configID,
			dataIndex = dataIndex,
			texture = texture or (spellID and C_Spell.GetSpellTexture(spellID)) or 134400,
			spellID = spellID,
			isKnown = info.isKnown,
			iconType = "spell",
			isDisabled = info.isDisabled or (info.category and (info.category < 0 or info.category >= 4)),
			isBuffIcon = isBuffIcon or info.category >= 2,
			cooldownID = info.cooldownID,
		})

		return dataIndex
	end,

	["AddSpellByCooldownID"] = function(self, cooldownID)
		--self.dataProvider:Insert()
	end,

	["AddCustomIcon"] = function(self, iconData)
		local highestIndex = 0
		for _, data in self.dataProvider:Enumerate() do
			if data.dataIndex > highestIndex and data.dataIndex < 100 then
				highestIndex = data.dataIndex
			end
		end
		local dataIndex = highestIndex + 1
		local data = {
			dataIndex = dataIndex,
			texture = iconData.texture,
			spellID = iconData.spellID,
			itemID = iconData.itemID,
			slotID = iconData.slotID,
			isKnown = true,
			isCustom = true,
			iconType = iconData.iconType,
			id = iconData.id,
		}
		self.dataProvider:Insert(data)
		return dataIndex, data
	end,

	["AddAddButton"] = function(self)
		self.dataProvider:Insert({ dataIndex = 100, isAddButton = true })
	end,

	["RemoveButton"] = function(self, data)
		self.dataProvider:Remove(data)

		local highestIndex = 0
		for _, data in self.dataProvider:Enumerate() do
			if data.dataIndex > highestIndex and data.dataIndex < 100 then
				highestIndex = data.dataIndex
			end
		end
		self.dataProvider.highestIndex = highestIndex
	end,

	["SetSortComparator"] = function(self, sortComparator, skipSort)
		self.dataProvider:SetSortComparator(sortComparator, skipSort)
	end,

	["InitButton"] = function(self, button, data)
		button.controller = self.controller
		button.scrollBox = self.scrollBox
		button.dataProvider = self.dataProvider
		button.obj = self

		button:SetSize(45, 45)
		button.dataIndex = data.dataIndex
		button.data = data
		button:RegisterForClicks("AnyUp", "AnyDown")
		button:SetScript("OnClick", Button_OnClick)

		if data.isAddButton then
			button.CustomText.Text:Hide()
			button.Icon:SetAtlas("cdm-empty")
			button.Icon:SetVertexColor(1, 1, 1, 1)
			button:SetMovable(false)
		else
			if data.texture then
				button.Icon:SetTexture(data.texture)
			end

			button.Icon:SetDesaturated(not data.isKnown)
			button.CustomText.Text:Hide()
			if data.isDisabled then
				button.Icon:SetVertexColor(0.7, 0, 0, 1)
			elseif data.isCustom then
				button.CustomText.Text:SetText(button.data.iconType:gsub("^%l", string.upper))
				button.CustomText.Text:Show()
			else
				button.Icon:SetVertexColor(1, 1, 1, 1)
			end
			button:RegisterForDrag("LeftButton")
			button:SetMovable(true)
			button:SetScript("OnDragStart", Button_OnDragStart)
			button:SetScript("OnDragStop", Button_OnDragStop)
		end
	end,
}
--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetHeight(50)
	frame:SetWidth(300)
	frame:SetFrameStrata("BACKGROUND")

	local dataProvider = CreateDataProvider()
	local scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
	local content = CreateFrame("Frame", nil, scrollBox)
	content:SetAllPoints(scrollBox)

	local name = (Type .. "%dScrollBar"):format(AceGUI:GetNextWidgetNum(Type))
	local scrollbar = CreateFrame("EventFrame", name, frame, "WowTrimHorizontalScrollBar")
	scrollBox:SetPoint("TOPLEFT", frame, "TOPLEFT")
	scrollBox:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	scrollBox:SetPoint("BOTTOMLEFT", scrollbar, "TOPLEFT", 0, 2)
	scrollBox:SetPoint("BOTTOMRIGHT", scrollbar, "TOPRIGHT", 0, 2)
	scrollbar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
	scrollbar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")

	local scrollbg = scrollBox:CreateTexture(nil, "BACKGROUND")
	scrollbg:SetAllPoints(scrollBox)
	scrollbg:SetColorTexture(0, 0, 0, 0.4)

	local scrollView = CreateScrollBoxListLinearView(10, 5, 5, 5, 5)
	scrollView:SetHorizontal(true)
	scrollView:SetElementExtent(45)

	local controller = CreateFrame("Button", nil, UIParent, "PermokScrollIconTemplate")
	--controller:SetAllPoints(frame)
	controller:SetSize(40, 40)
	controller:SetFrameStrata("TOOLTIP")
	controller:Hide()
	controller.scrollView = scrollView
	controller.dataProvider = dataProvider

	local markerFrame = CreateFrame("Frame", nil, scrollBox)
	markerFrame:SetSize(2, 45)
	markerFrame:Hide()

	local marker = markerFrame:CreateTexture(nil, "OVERLAY")
	marker:SetAllPoints()
	marker:SetColorTexture(1, 1, 1, 0.8)
	controller.marker = markerFrame

	scrollView:SetElementInitializer("PermokScrollIconTemplate", function(button, data)
		frame.obj:InitButton(button, data)
	end)

	ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollbar, scrollView)
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
