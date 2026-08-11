local SCM = select(2, ...)

local Utils = SCM.Utils

local function GetSpellAnchorGroupConfig(spellConfig, group)
	return spellConfig and spellConfig.anchorGroup and spellConfig.anchorGroup[group]
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
		self.resourceBarConfig = SetSpecConfigMetatables(self.specResourceBarConfig, options.resourceBar, defaultOptions.resourceBar)
	else
		self.resourceBarConfig = options.resourceBar
	end

	if self.specCastBarConfig.active then
		self.castBarConfig = SetSpecConfigMetatables(self.specCastBarConfig, options.castBar, defaultOptions.castBar)
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

	local specAnchorConfig = self.DB.defaultAnchorConfig
	local specBuffBarsAnchorConfig = self.DB.defaultBuffBarsAnchorConfig
	local specAurasAnchorConfig = self.DB.defaultAurasAnchorConfig
	local specSpellConfig = {}
	local specCustomConfig = {}
	local specResourceBarConfig = {}
	local specCastBarConfig = {}

	if currentConfig then
		specAnchorConfig = currentConfig.anchorConfig[specID] or specAnchorConfig
		specBuffBarsAnchorConfig = (currentConfig.buffBarsAnchorConfig and currentConfig.buffBarsAnchorConfig[specID]) or specBuffBarsAnchorConfig
		specAurasAnchorConfig = (currentConfig.aurasAnchorConfig and currentConfig.aurasAnchorConfig[specID]) or specAurasAnchorConfig
		specSpellConfig = currentConfig.spellConfig[specID] or specSpellConfig
		specCustomConfig = (currentConfig.customConfig and currentConfig.customConfig[specID]) or specCustomConfig
		specResourceBarConfig = (currentConfig.resourceBarConfig and currentConfig.resourceBarConfig[specID]) or specResourceBarConfig
		specCastBarConfig = (currentConfig.castBarConfig and currentConfig.castBarConfig[specID]) or specCastBarConfig
	end

	self.db.profile[class] = self.db.profile[class] or {}
	self.db.profile[class][specID] = self.db.profile[class][specID]
		or {
			anchorConfig = CopyTable(specAnchorConfig),
			buffBarsAnchorConfig = CopyTable(specBuffBarsAnchorConfig),
			aurasAnchorConfig = CopyTable(specAurasAnchorConfig),
			spellConfig = specSpellConfig,
			customConfig = specCustomConfig,
			resourceBarConfig = specResourceBarConfig,
			castBarConfig = specCastBarConfig,
		}

	self.currentConfig = self.db.profile[class][specID]

	self.anchorConfig = self.currentConfig.anchorConfig
	self.buffBarsAnchorConfig = self.currentConfig.buffBarsAnchorConfig
	self.aurasAnchorConfig = self.currentConfig.aurasAnchorConfig
	self.spellConfig = self.currentConfig.spellConfig

	self:MigrateDB()

	self.globalAnchorConfig = self.db.profile.globalAnchorConfig
	self.globalCustomConfig = self.db.profile.globalCustomConfig
	self.globalAurasAnchorConfig = self.db.profile.globalAurasAnchorConfig

	self.customConfig = self.currentConfig.customConfig
	self.specResourceBarConfig = self.currentConfig.resourceBarConfig
	self.specCastBarConfig = self.currentConfig.castBarConfig
	self:UpdateCastAndResourceBarConfigs()

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
