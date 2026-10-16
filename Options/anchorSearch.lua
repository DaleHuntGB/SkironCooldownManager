local SCM = select(2, ...)

local CONSTANTS = SCM.Constants.GENERAL
local Options = SCM.Options

local SCMAnchorSearchMixin = {}
local anchorSuggestionFrame

local ANCHOR_CONFIGS = {
	["Anchor"] = "anchorConfig",
	["Global Anchor"] = "globalAnchorConfig",
	["Buff Bar Anchor"] = "buffBarsAnchorConfig",
}

function SCMAnchorSearchMixin:BuildCandidates()
	local candidates = self.candidates
	local count = 0

	for _, anchors in pairs(CONSTANTS.SCM_ANCHORS) do
		for label, anchorName in pairs(anchors) do
			if anchorName then
				local configKey = ANCHOR_CONFIGS[label]
				local anchorCount = configKey and #SCM[configKey] or 1

				for index = 1, anchorCount do
					count = count + 1

					local candidate = candidates[count]

					if not candidate then
						candidate = {}
						candidates[count] = candidate
					end

					local anchor = anchorName:gsub("#", index)
					local text = configKey and (label .. " #" .. index) or label

					candidate.anchor = anchor
					candidate.text = text
					candidate.anchorLower = strlower(anchor)
					candidate.textLower = strlower(text)
				end
			end
		end
	end

	for index = #candidates, count + 1, -1 do
		candidates[index] = nil
	end

	self.needsRefresh = nil
end

function SCMAnchorSearchMixin:GetSearchToken(text, cursorPosition)
	local beforeCursor = text:sub(1, cursorPosition)
	local tokenPrefix = beforeCursor:match("^(.*,%s*)[^,]*$") or beforeCursor:match("^%s*")

	return strtrim(beforeCursor:sub(#tokenPrefix + 1)), #tokenPrefix
end

function SCMAnchorSearchMixin:CommitAnchorText(text, cursorPosition)
	self.suppressSuggestions = true

	anchorSuggestionFrame:Hide()

	if self:GetText() ~= text then
		self:SetText(text)
	end

	self.editbox:SetCursorPosition(cursorPosition)
	self.onValueSelected(text)
end

function SCMAnchorSearchMixin:SelectSuggestion(anchor)
	local input = self.editbox
	local text = self:GetText()
	local cursorPosition = input:GetCursorPosition()
	local token, startIndex = self:GetSearchToken(text, cursorPosition)

	if strlower(token) ~= anchorSuggestionFrame.token then
		anchorSuggestionFrame:Hide()
		return
	end

	local suffixIndex = text:find(",", cursorPosition + 1, true) or (#text + 1)

	self:CommitAnchorText(text:sub(1, startIndex) .. anchor .. text:sub(suffixIndex), startIndex + #anchor)
end

local function OnAnchorSuggestionClick(row)
	row:GetParent().editBox:SelectSuggestion(row.anchor)
end

function SCMAnchorSearchMixin:SetSelectedSuggestion(index)
	local frame = anchorSuggestionFrame

	if frame.selectedIndex == index then
		return
	end

	if frame.selectedIndex then
		frame.rows[frame.selectedIndex]:UnlockHighlight()
	end

	frame.selectedIndex = index

	if index then
		frame.rows[index]:LockHighlight()
	end
end

local function OnAnchorSuggestionEnter(row)
	row:GetParent().editBox:SetSelectedSuggestion(row:GetID())
end

function SCMAnchorSearchMixin:ShowSuggestions(token)
	local frame = anchorSuggestionFrame

	if frame.token == token then
		return
	end

	if not frame:IsShown() then
		frame.editBox = self
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", self.editbox, "BOTTOMLEFT", 0, -2)
		frame:SetPoint("TOPRIGHT", self.editbox, "BOTTOMRIGHT", 0, -2)
	end

	self:SetSelectedSuggestion(nil)

	local count = 0

	for _, candidate in ipairs(self.candidates) do
		local startIndex, endIndex = candidate.textLower:find(token, 1, true)

		if startIndex or candidate.anchorLower:find(token, 1, true) then
			count = count + 1

			local row = frame.rows[count]

			if not row then
				row = CreateFrame("Button", nil, frame)
				row:SetID(count)
				row:SetFrameLevel(frame:GetFrameLevel() + 1)
				row:EnableMouse(true)
				row:SetHeight(18)
				row:SetPoint("TOPLEFT", 2, -2 - ((count - 1) * 18))
				row:SetPoint("TOPRIGHT", -2, -2 - ((count - 1) * 18))
				row:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")

				local highlight = row:GetHighlightTexture()

				highlight:SetColorTexture(204 / 255, 204 / 255, 204 / 255, 0.5)
				highlight:SetBlendMode("BLEND")

				row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				row.text:SetPoint("LEFT", 4, 0)
				row.text:SetPoint("RIGHT", -4, 0)
				row.text:SetJustifyH("LEFT")

				row:SetScript("OnClick", OnAnchorSuggestionClick)
				row:SetScript("OnEnter", OnAnchorSuggestionEnter)

				frame.rows[count] = row
			end

			row.anchor = candidate.anchor

			local text = candidate.text

			if startIndex then
				row.text:SetText("|cFF4080FF" .. text:sub(1, startIndex - 1) .. "|cFFFFFFFF" .. text:sub(startIndex, endIndex) .. "|cFF4080FF" .. text:sub(endIndex + 1) .. "|r")
			else
				row.text:SetText("|cFF4080FF" .. text .. "|r")
			end

			row:Show()
		end
	end

	for index = count + 1, frame.count do
		frame.rows[index]:Hide()
	end

	frame.count = count

	if count == 0 then
		frame:Hide()
		return
	end

	frame.token = token

	frame:SetHeight(4 + (count * 18))
	frame:Show()
end

function SCMAnchorSearchMixin:RefreshSuggestions()
	if self.suppressSuggestions or not self.editbox:HasFocus() then
		return
	end

	local input = self.editbox
	local text = self:GetText()
	local token = self:GetSearchToken(text, input:GetCursorPosition())

	if token == "" then
		anchorSuggestionFrame:Hide()
		return
	end

	if self.needsRefresh then
		self:BuildCandidates()
	end

	self:ShowSuggestions(strlower(token))
end

function SCMAnchorSearchMixin:ReleaseSearch()
	self.suppressSuggestions = true
	self.onValueSelected = nil
	self.editbox:SetAltArrowKeyMode(self.altArrowKeyMode)
end

function SCMAnchorSearchMixin:OnTextChanged()
	self.suppressSuggestions = nil
	self:RefreshSuggestions()
end

function SCMAnchorSearchMixin:OnEnterPressed(_, text)
	local frame = anchorSuggestionFrame

	if frame.selectedIndex then
		self:SelectSuggestion(frame.rows[frame.selectedIndex].anchor)
	else
		self:CommitAnchorText(text, self.editbox:GetCursorPosition())
	end
end

local function OnAnchorSearchArrowPressed(_, key)
	if key ~= "UP" and key ~= "DOWN" then
		return
	end

	local frame = anchorSuggestionFrame

	if not frame:IsShown() then
		return
	end

	local index = frame.selectedIndex or (key == "UP" and 1 or 0)
	local direction = key == "UP" and -1 or 1

	frame.editBox:SetSelectedSuggestion((index - 1 + direction) % frame.count + 1)
end

local function OnAnchorSearchCursorChanged(input)
	input.obj:RefreshSuggestions()
end

local function OnAnchorSearchFocusLost(input)
	local editBox = input.obj

	editBox.suppressSuggestions = true
	anchorSuggestionFrame:Hide()
end

local function OnAnchorSearchHide(frame)
	local editBox = frame.obj

	if editBox.editbox:HasFocus() then
		editBox:ClearFocus()
	end
end

function SCMAnchorSearchMixin:OnLoad()
	self.candidates = {}

	local input = self.editbox

	input:HookScript("OnCursorChanged", OnAnchorSearchCursorChanged)
	input:HookScript("OnArrowPressed", OnAnchorSearchArrowPressed)
	input:HookScript("OnEditFocusLost", OnAnchorSearchFocusLost)
	self.frame:HookScript("OnHide", OnAnchorSearchHide)
end

function SCMAnchorSearchMixin:Init(onValueSelected)
	self.onValueSelected = onValueSelected
	self.suppressSuggestions = true
	self.needsRefresh = true

	local input = self.editbox

	self.altArrowKeyMode = input:GetAltArrowKeyMode()
	input:SetAltArrowKeyMode(false)

	self:SetCallback("OnTextChanged", self.OnTextChanged)
	self:SetCallback("OnEnterPressed", self.OnEnterPressed)
	self:SetCallback("OnRelease", self.ReleaseSearch)
end

function Options.AddAnchorParentAutocomplete(editBox, onValueSelected)
	if not onValueSelected then
		return
	end

	if not anchorSuggestionFrame then
		local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")

		frame:SetFrameStrata("TOOLTIP")
		frame:SetFrameLevel(100)
		frame:SetToplevel(true)
		frame:EnableMouse(true)
		frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
		frame:SetBackdropColor(26 / 255, 26 / 255, 26 / 255, 1)
		frame:SetBackdropBorderColor(0, 0, 0, 1)

		frame.rows = {}
		frame.count = 0

		EventRegistry:RegisterCallback("UI.QueryStickyFocusFrames", function(frame, request)
			request:AddFrame(frame)
		end, frame)

		frame:SetScript("OnHide", function(self)
			if self.selectedIndex then
				self.rows[self.selectedIndex]:UnlockHighlight()
			end

			self.selectedIndex = nil
			self.token = nil
		end)

		frame:Hide()

		anchorSuggestionFrame = frame
	end

	if not editBox.Init then
		Mixin(editBox, SCMAnchorSearchMixin)
		editBox:OnLoad()
	end

	editBox:Init(onValueSelected)

	return editBox.frame
end
