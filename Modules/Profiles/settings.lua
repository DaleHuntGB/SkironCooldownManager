local SCM = select(2, ...)

local Profiles = SCM.Profiles

local EXPORT_TYPE = SCM.Constants.PROFILES.EXPORT_TYPE
local PROFILE_OPTION_KEYS = SCM.Constants.PROFILES.OPTION_KEYS

function Profiles.CopyValue(value)
	if type(value) == "table" then
		return CopyTable(value)
	end

	return value
end

function Profiles.BuildGeneralSettingsExport(options)
	local exportData = {}

	for key, value in pairs(options) do
		if not PROFILE_OPTION_KEYS[key] then
			exportData[key] = Profiles.CopyValue(value)
		end
	end

	SCM:CreateCooldownBreakpoints(exportData)

	return exportData
end

function Profiles.ApplyOptionsData(options, data)
	if not data then
		return
	end

	for key, value in pairs(data) do
		options[key] = Profiles.CopyValue(value)
	end
end

function Profiles.ApplyResourceBarSettings(options, data)
	if not data then
		return
	end

	if data.resourceBar then
		options.resourceBar = Profiles.CopyValue(data.resourceBar)
	end
end

function SCM:ExportGlobalSettings()
	return Profiles.EncodeExport(EXPORT_TYPE.GLOBAL_SETTINGS, Profiles.BuildGeneralSettingsExport(self.db.profile.options))
end

function SCM:ImportGlobalSettings(importString)
	self:ImportProfile(nil, importString)
end

function SCM:ImportGlobalSettingsFromData(data)
	local options = self.db.profile.options

	Profiles.ApplyOptionsData(options, data)
	self.db.profile.options = options

	self.db:RegisterDefaults(SCM.DefaultDB)
	SCM.appliedOptions = nil
	SCM:ResetCooldownViewer()
	SCM:ApplyOptions()
end
