local _, SCM = ...

local COOLDOWN_CONFIG_KEY_PREFIX = "cooldown:"

local function GetCooldownConfigKey(cooldownID)
	if not cooldownID then
		return
	end

	return COOLDOWN_CONFIG_KEY_PREFIX .. tostring(cooldownID)
end

local function GetSpellConfigByCooldownID(spellConfig, cooldownID)
	local configID = GetCooldownConfigKey(cooldownID)
	return configID, configID and spellConfig and spellConfig[configID]
end

local function MigrateLegacyGlobalOptionsToProfiles(db)
	if not db or not db.sv or not db.sv.global then
		return
	end

	local legacyOptions = db.sv.global.options
	if type(legacyOptions) ~= "table" then
		return
	end

	db.sv.profiles = db.sv.profiles or {}

	for _, storedProfile in pairs(db.sv.profiles) do
		if type(storedProfile) == "table" and type(storedProfile.options) ~= "table" then
			storedProfile.options = CopyTable(legacyOptions)
		end
	end

	local profileKey = db.keys and db.keys.profile
	if profileKey then
		db.sv.profiles[profileKey] = db.sv.profiles[profileKey] or {}
		if type(db.sv.profiles[profileKey].options) ~= "table" then
			db.sv.profiles[profileKey].options = CopyTable(legacyOptions)
		end
	end

	db.sv.global.options = nil
end

local function GetCooldownDataForLegacySpellConfig(defaultCooldownViewerConfig, configID, config)
	local spellID = config.spellID or (type(configID) == "number" and configID)
	if not spellID or not defaultCooldownViewerConfig then
		return
	end

	for sourceIndex in pairs(config.source) do
		local categoryConfig = defaultCooldownViewerConfig[sourceIndex]
		local pairIndex = SCM.Constants.SourcePairs[sourceIndex]
		local pairConfig = pairIndex and defaultCooldownViewerConfig[pairIndex]
		local data = categoryConfig and categoryConfig.spellIDs[spellID]
		if not data and pairConfig then
			data = pairConfig.spellIDs[spellID]
		end
		if data and data.cooldownID then
			return data
		end
	end

	return defaultCooldownViewerConfig.spellIDs and defaultCooldownViewerConfig.spellIDs[spellID]
end

function SCM:GetCooldownConfigKey(cooldownID)
	return GetCooldownConfigKey(cooldownID)
end

function SCM:GetSpellConfigByCooldownID(cooldownID)
	return GetSpellConfigByCooldownID(self.spellConfig, cooldownID)
end

function SCM:MigrateLegacyProfileOptions()
	if not self.db then
		return
	end

	MigrateLegacyGlobalOptionsToProfiles(self.db)
end

function SCM:MigrateLegacySpellConfigKeys(spellConfig, defaultCooldownViewerConfig)
	local legacyKeys = {}
	for configID in pairs(spellConfig) do
		if type(configID) == "number" then
			legacyKeys[#legacyKeys + 1] = configID
		end
	end

	for _, legacyID in ipairs(legacyKeys) do
		local config = spellConfig[legacyID]
		local spellID = config.spellID or legacyID
		local cooldownData = GetCooldownDataForLegacySpellConfig(defaultCooldownViewerConfig, legacyID, config)
		local cooldownID = config.cooldownID or (cooldownData and cooldownData.cooldownID)
		if cooldownID then
			local migratedID = GetCooldownConfigKey(cooldownID)
			config.spellID = spellID
			config.cooldownID = cooldownID
			if migratedID then
				spellConfig[migratedID] = config
				spellConfig[legacyID] = nil
			end
		else
			spellConfig[legacyID] = nil
		end
	end
end
