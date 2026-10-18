local SCM = select(2, ...)

local Profiles = SCM.Profiles
local ApplyCustomConfig = Profiles.ApplyCustomConfig

local EXPORT_TYPE = SCM.Constants.PROFILES.EXPORT_TYPE

function Profiles.CopyAnchors(anchors, sharedAnchors)
	local result = {}

	for index, anchorConfig in ipairs(anchors) do
		if anchorConfig.useGlobalProfileConfig and sharedAnchors and sharedAnchors[index] then
			anchorConfig = sharedAnchors[index]
		end

		local copy = CopyTable(anchorConfig)
		copy.useGlobalProfileConfig = nil
		result[index] = copy
	end

	return result
end

function Profiles.ApplyAnchors(destination, anchors)
	for index, anchorConfig in ipairs(anchors) do
		destination[index] = anchorConfig
	end
end

local function GetImportedGlobalAnchors(data)
	local anchors = data and data.globalAnchorConfig

	if anchors and #anchors > 0 then
		anchors = CopyTable(anchors)

		for _, anchorConfig in ipairs(anchors) do
			if not anchorConfig.anchor then
				anchorConfig.anchor = { "CENTER", "UIParent", "CENTER", 0, 0 }
			end

			if not anchorConfig.rowConfig or #anchorConfig.rowConfig == 0 then
				anchorConfig.rowConfig = {
					{
						iconWidth = 40,
						iconHeight = 40,
						limit = 8,
					},
				}
			end
		end
	else
		anchors = nil
	end

	return anchors
end

function SCM:ExportGlobalAnchors(exportOptions)
	local excludeIcons = exportOptions and exportOptions.excludeIcons
	local data = { globalAnchorConfig = CopyTable(self.db.profile.globalAnchorConfig) }

	if not excludeIcons then
		data.globalCustomConfig = CopyTable(self.db.profile.globalCustomConfig)
	end

	return Profiles.EncodeExport(EXPORT_TYPE.GLOBAL_ANCHORS, data, excludeIcons)
end

function SCM:ImportGlobalAnchors(importString)
	self:ImportProfile(nil, importString)
end

function SCM:ImportGlobalAnchorsFromData(data, refreshData, excludeIcons)
	local previousAnchorCount = #self.db.profile.globalAnchorConfig
	local anchors = GetImportedGlobalAnchors(data)

	if anchors then
		if excludeIcons or not data.globalCustomConfig then
			Profiles.ApplyAnchors(self.db.profile.globalAnchorConfig, anchors)
		else
			self.db.profile.globalAnchorConfig = anchors
		end
	end

	local customConfig = data and data.globalCustomConfig

	if customConfig and not excludeIcons then
		ApplyCustomConfig(self.db.profile.globalCustomConfig, customConfig)
	end

	local currentAnchorCount = #self.db.profile.globalAnchorConfig

	for index = currentAnchorCount + 1, previousAnchorCount do
		local globalGroup = self.Utils.ToGlobalGroup(index)
		local anchorFrame = self.anchorFrames[globalGroup]

		if anchorFrame then
			anchorFrame:Hide()
		end
	end

	if refreshData then
		SCM:ResetCooldownViewer()
	end
end
