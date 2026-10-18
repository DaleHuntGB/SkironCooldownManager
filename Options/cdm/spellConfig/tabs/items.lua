local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local AceGUI = LibStub("AceGUI-3.0")
local Utils = SCM.Utils

function CDMOptions.CreateItemsTabSettings(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, buttonConfig, anchorIndex, mode, isGlobal, isBuffBar)
	buttonConfig.customItems = buttonConfig.customItems or {}

	local listContainer = AceGUI:Create("SCMVerticalScrollFrame")
	listContainer:SetFullWidth(true)
	listContainer:SetFullHeight(true)

	local pendingItemLoads = {}
	local entries = {}
	local RefreshList

	listContainer:SetUserData("pendingItemLoads", pendingItemLoads)

	local function GetCustomItemDisplay(itemID)
		local itemName = C_Item.GetItemNameByID(itemID)
		local itemTexture = C_Item.GetItemIconByID(itemID)
		local isLoaded = itemName and itemTexture
		local qualityAtlas = Utils.GetCustomItemCraftQualityAtlas(itemID)
		local qualityIcon = qualityAtlas and ("|A:%s:45:45|a"):format(qualityAtlas) or ""
		local offsetX = qualityAtlas and 5 or 0
		itemTexture = itemTexture or 134400

		return ("|T%s:30:30:%d:0:30:30:3:27:3:27|t%s%s"):format(itemTexture, offsetX, qualityIcon, itemName or ("Item ID " .. itemID)), isLoaded, itemTexture
	end

	local function RequestCustomItemLoad(itemID)
		if pendingItemLoads[itemID] then
			return
		end

		pendingItemLoads[itemID] = true
		local item = Item:CreateFromItemID(itemID)
		item:ContinueOnItemLoad(function()
			pendingItemLoads[itemID] = nil
			if listContainer:GetUserData("pendingItemLoads") == pendingItemLoads and listContainer:IsShown() then
				RefreshList()
			end
		end)
	end

	RefreshList = function()
		wipe(entries)

		for i, itemID in ipairs(buttonConfig.customItems) do
			itemID = tonumber(itemID)
			if itemID then
				buttonConfig.customItems[i] = itemID

				local text, isLoaded, texture = GetCustomItemDisplay(itemID)
				entries[#entries + 1] = {
					itemID = itemID,
					dataIndex = i,
					text = text,
					texture = texture,
				}

				if not isLoaded then
					RequestCustomItemLoad(itemID)
				end
			end
		end

		listContainer:SetEntries(entries)
		iconSettingsTabs:DoLayout()
		scrollFrame:DoLayout()
	end

	listContainer:SetCallback("OnRemove", function(_, _, entry)
		table.remove(buttonConfig.customItems, entry.dataIndex)
		RefreshList()
		CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	end)

	listContainer:SetCallback("OnDragStop", function(_, _, collection)
		wipe(buttonConfig.customItems)
		for i, entry in ipairs(collection) do
			buttonConfig.customItems[i] = entry.itemID
		end
		CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	end)

	local addItemButton = AceGUI:Create("EditBox")
	addItemButton:SetRelativeWidth(0.8)
	addItemButton:SetLabel("Add Fallback Item IDs")
	addItemButton:SetCallback("OnEnterPressed", function(self, _, value)
		local itemID = value and tonumber(value)
		if itemID and itemID > 0 then
			table.insert(buttonConfig.customItems, itemID)
			self:SetText("")
			RefreshList()
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
		end
	end)

	iconSettingsTabs:AddChild(addItemButton)
	iconSettingsTabs:AddChild(listContainer)

	RefreshList()
end
