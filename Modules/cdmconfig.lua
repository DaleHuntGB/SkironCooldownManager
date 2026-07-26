local SCM = select(2, ...)

local Utils = SCM.Utils

local function GetSpellAnchorGroupConfig(spellConfig, group)
	return spellConfig and spellConfig.anchorGroup and spellConfig.anchorGroup[group]
end

local function CreateCustomConfigTables(customConfig)
	customConfig = customConfig or {}
	customConfig.spellConfig = GetOrCreateTableEntry(customConfig, "spellConfig")
	customConfig.itemConfig = GetOrCreateTableEntry(customConfig, "itemConfig")
	customConfig.slotConfig = GetOrCreateTableEntry(customConfig, "slotConfig")
	customConfig.timerConfig = GetOrCreateTableEntry(customConfig, "timerConfig")
	customConfig.bloodlustConfig = GetOrCreateTableEntry(customConfig, "bloodlustConfig")

	local allowedKeys = SCM.DefaultDB.profile.globalCustomConfig
	for key in pairs(customConfig) do
		if not allowedKeys[key] then
			customConfig[key] = nil
		end
	end

	return customConfig
end

local function CreateAnchorConfigTables(customConfig)
	customConfig = customConfig or {}

	if not customConfig[1] then
		customConfig[1] = {
			anchor = { "CENTER", "UIParent", "CENTER", 0, 0 },
			rowConfig = {
				[1] = {
					iconWidth = 150,
					iconHeight = 40,
					limit = 8,
				},
			},
		}
	end

	return customConfig
end

local function SetSpecConfigMetatables(specConfig, profileConfig, defaultConfig)
	if not defaultConfig then
		defaultConfig = {}
	end

	for key, value in pairs(specConfig) do
		local profileValue = profileConfig[key]
		if type(value) == "table" and type(profileValue) == "table" then
			SetSpecConfigMetatables(value, profileValue, defaultConfig[key])
		end
	end

	if type(defaultConfig[1]) == "table" then
		for index, defaultValue in ipairs(defaultConfig) do
			if rawget(specConfig, index) == nil then
				local profileValue = profileConfig[index]
				if type(profileValue) == "table" then
					specConfig[index] = SetSpecConfigMetatables({}, profileValue, defaultValue)
				end
			end
		end
	end

	return setmetatable(specConfig, {
		__index = function(self, key)
			local value = profileConfig[key]
			if type(value) == "table" then
				value = SetSpecConfigMetatables({}, value, defaultConfig[key])
				rawset(self, key, value)
			end

			return value
		end,
	})
end

function SCM:UpdateCastAndResourceBarConfigs()
	local options = self.db.profile.options
	local defaultOptions = SCM.DefaultDB.profile.options

	if self.specResourceBarConfig.active then
		self.resourceBarConfig = SetSpecConfigMetatables(
			self.specResourceBarConfig,
			options.resourceBar,
			defaultOptions.resourceBar
		)
	else
		self.resourceBarConfig = options.resourceBar
	end

	if self.specCastBarConfig.active then
		self.castBarConfig = SetSpecConfigMetatables(
			self.specCastBarConfig,
			options.castBar,
			defaultOptions.castBar
		)
	else
		self.castBarConfig = options.castBar
	end

	if self.CastBar then
		self.CastBar.barOptions = self.castBarConfig
	end
end

function SCM:UpdateDB()
	local firstGlobalGroup = SCM.Utils.ToGlobalGroup(1)
	local firstBuffBarGroup = SCM.Utils.ToBuffBarGroup(1)
	local class = Utils.GetClass()
	local specID, _, _, _, role = Utils.GetSpec()
	local _, _, raceID = UnitRace("player")

	local currentConfig = self.DB:LoadData()
	local specAnchorConfig = currentConfig and currentConfig.anchorConfig[specID]
	local specBuffBarsAnchorConfig = currentConfig and currentConfig.buffBarsAnchorConfig and currentConfig.buffBarsAnchorConfig[specID]
	local specSpellConfig = currentConfig and currentConfig.spellConfig[specID]
	local specCustomConfig = currentConfig and currentConfig.customConfig and currentConfig.customConfig[specID]
	local specResourceBarConfig = currentConfig and currentConfig.resourceBarConfig and currentConfig.resourceBarConfig[specID]
	local specCastBarConfig = currentConfig and currentConfig.castBarConfig and currentConfig.castBarConfig[specID]

	self.db.profile[class] = self.db.profile[class] or {}
	self.db.profile[class][specID] = self.db.profile[class][specID]
		or {
			anchorConfig = CopyTable(specAnchorConfig or self.DB.defaultAnchorConfig),
			buffBarsAnchorConfig = CopyTable(specBuffBarsAnchorConfig or self.DB.defaultBuffBarsAnchorConfig),
			spellConfig = specSpellConfig or {},
			customConfig = specCustomConfig or {},
			resourceBarConfig = specResourceBarConfig or {},
			castBarConfig = specCastBarConfig or {},
		}

	self.currentConfig = self.db.profile[class][specID]
	self.anchorConfig = self.currentConfig.anchorConfig
	self.spellConfig = self.currentConfig.spellConfig
	self:MigrateDB()
	self.itemConfig = self.currentConfig.itemConfig

	self.currentConfig.customConfig = self.currentConfig.customConfig or {}
	self.customConfig = CreateCustomConfigTables(self.currentConfig.customConfig)

	self.currentConfig.resourceBarConfig = self.currentConfig.resourceBarConfig or {}
	self.specResourceBarConfig = self.currentConfig.resourceBarConfig

	self.currentConfig.castBarConfig = self.currentConfig.castBarConfig or {}
	self.specCastBarConfig = self.currentConfig.castBarConfig
	self:UpdateCastAndResourceBarConfigs()

	self.currentConfig.buffBarsAnchorConfig = self.currentConfig.buffBarsAnchorConfig or {}
	self.buffBarsAnchorConfig = CreateAnchorConfigTables(self.currentConfig.buffBarsAnchorConfig)

	self.globalAnchorConfig = self.db.profile.globalAnchorConfig
	self.globalCustomConfig = CreateCustomConfigTables(self.db.profile.globalCustomConfig)

	self.isHideWhenInactiveEnabled = self:GetHideWhenInactive() == 1
	self.showTooltips = self:GetShowTooltip() == 1
	self.currentClass = class
	self.currentSpecID = specID
	self.currentRole = role
	self.currentRace = raceID

	for group, anchorFrame in pairs(self.anchorFrames) do
		if group < firstGlobalGroup and not self.anchorConfig[group] then
			anchorFrame:Hide()
		elseif Utils.IsGlobalGroup(group) and not self.globalAnchorConfig[group - 100] then
			anchorFrame:Hide()
		elseif group >= firstBuffBarGroup and not self.buffBarsAnchorConfig[group - 200] then
			anchorFrame:Hide()
		end
	end
end

function SCM:GetSpellConfigForGroup(configID, group)
	return GetSpellAnchorGroupConfig(self.spellConfig and self.spellConfig[configID], group)
end
