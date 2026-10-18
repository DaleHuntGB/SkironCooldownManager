local SCM = select(2, ...)

local Profiles = SCM.Profiles

local CopyValue = Profiles.CopyValue
local ApplyOptionsData = Profiles.ApplyOptionsData
local ApplyResourceBarSettings = Profiles.ApplyResourceBarSettings
local DecodeImportString = Profiles.DecodeImport

local EXPORT_TYPE = SCM.Constants.PROFILES.EXPORT_TYPE

local function ImportProfile(self, profileName, importString, importSettings)
	local typeID, data = DecodeImportString(importString)

	if not typeID then
		return
	end

	local excludeIcons = (importSettings and importSettings.excludeIcons) or data.excludeIcons
	local includeResourceBar = not importSettings or importSettings.includeResourceBar
	local includeCastBar = not importSettings or importSettings.includeCastBar
	local includeGlobalSettings = not importSettings or importSettings.includeGlobalSettings
	local includeGlobalAnchors = not importSettings or importSettings.includeGlobalAnchors

	if typeID == EXPORT_TYPE.GLOBAL_SETTINGS then
		if includeGlobalSettings and data.globalSettings then
			self:ImportGlobalSettingsFromData(data.globalSettings)

			return true
		end

		return
	end

	if typeID == EXPORT_TYPE.GLOBAL_ANCHORS then
		if includeGlobalAnchors and data.globalAnchors then
			self:ImportGlobalAnchorsFromData(data.globalAnchors, true, excludeIcons)

			return true
		end

		return
	end

	if not profileName or profileName == "" then
		profileName = SCM.db:GetCurrentProfile()
	end

	SCM.importingProfile = true
	SCM.db:SetProfile(profileName)

	local db = self.db.profile
	local options = db.options

	Profiles.ImportProfileData(db, typeID, data, importSettings)

	if includeResourceBar and data.resourceBarSettings then
		ApplyResourceBarSettings(options, data.resourceBarSettings)
	end

	if includeCastBar and data.castBarSettings then
		options.castBar = CopyValue(data.castBarSettings)
	end

	if includeGlobalSettings and data.globalSettings then
		ApplyOptionsData(options, data.globalSettings)
	end

	if includeGlobalAnchors and data.globalAnchors then
		self:ImportGlobalAnchorsFromData(data.globalAnchors, nil, excludeIcons)
	end

	self.db.profile.options = options
	SCM.db:RegisterDefaults(SCM.DefaultDB)
	SCM:ResetCooldownViewer()

	SCM.appliedOptions = nil
	SCM:ApplyOptions()

	SCM.importingProfile = nil

	return true
end

function SCM:ImportProfile(profileName, importString, importSettings)
	return self:RunLayoutBatch(ImportProfile, self, profileName, importString, importSettings)
end
