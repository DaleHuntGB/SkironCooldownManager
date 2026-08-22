local SCM = select(2, ...)

local function GetSpecConfigValue(configTable, specID)
	if type(configTable) ~= "table" then
		return
	end

	return configTable[specID] or configTable
end

function SCM.DB:LoadData()
	SCM.DB.currentConfig = self:GetClassConfig(SCM.Utils.GetClass())
	SCM.DB.configLoaded = SCM.DB.currentConfig ~= nil

	return SCM.DB.currentConfig
end

function SCM.DB:ResetData()
	self.classes = {}
end
function SCM.DB:GetClassConfig(classFileName)
	return self.classes[classFileName]
end

function SCM.DB:RegisterClassConfig(classFileName, config)
	self.classes[classFileName] = self.classes[classFileName] or {
		anchorConfig = {},
		spellConfig = {},
		itemConfig = {},
		customConfig = {},
	}

	for specID, anchorConfig in pairs(config.anchorConfig) do
		if #anchorConfig == 0 then
			self.classes[classFileName].anchorConfig[specID] = CopyTable(self.defaultAnchorConfig)
		else
			self.classes[classFileName].anchorConfig[specID] = anchorConfig
		end
	end

	for specID, spellConfig in pairs(config.spellConfig) do
		self.classes[classFileName].spellConfig[specID] = spellConfig

		if config.itemConfig then
			self.classes[classFileName].itemConfig[specID] = GetSpecConfigValue(config.itemConfig, specID)
		end
		if config.customConfig then
			self.classes[classFileName].customConfig[specID] = config.customConfig[specID] or config.customConfig
		end
	end
end

function SCM.DB:RegisterClassSpecConfig(classFileName, config, specID)
	self.classes[classFileName] = self.classes[classFileName] or {
		anchorConfig = {},
		spellConfig = {},
		itemConfig = {},
		customConfig = {},
	}

	if config.anchorConfig[specID] then
		if #config.anchorConfig[specID] == 0 then
			self.classes[classFileName].anchorConfig[specID] = CopyTable(self.defaultAnchorConfig)
		else
			self.classes[classFileName].anchorConfig[specID] = config.anchorConfig[specID]
		end
	end
	self.classes[classFileName].spellConfig[specID] = config.spellConfig[specID]

	if config.itemConfig then
		self.classes[classFileName].itemConfig[specID] = GetSpecConfigValue(config.itemConfig, specID)
	end
	if config.customConfig then
		self.classes[classFileName].customConfig[specID] = config.customConfig[specID] or config.customConfig
	end
end

function SCM.DB:RegisterAndLoadConfig(profileName, classFileName, config, specID)
	SCM.db:SetProfile(profileName)

	if specID then
		SCM.DB:RegisterClassSpecConfig(classFileName, config, specID)
	else
		SCM.DB:RegisterClassConfig(classFileName, config)
	end

	if classFileName == SCM.Utils.GetClass() then
		SCM.db.profile[classFileName] = SCM.db.profile[classFileName] or {}

		for specID, spellConfig in pairs(config.spellConfig) do
			if next(spellConfig) then
				SCM.db.profile[classFileName][specID] = nil
			end
		end

		SCM:LoadNewProfile(true)
	end
end

function SCM:GetConfigTable(iconType, isGlobal)
	if iconType == "spell" then
		return isGlobal and self.globalCustomConfig.spellConfig or self.customConfig.spellConfig
	end

	if iconType == "slot" then
		return isGlobal and self.globalCustomConfig.slotConfig or self.customConfig.slotConfig
	end

	if iconType == "timer" then
		return isGlobal and self.globalCustomConfig.timerConfig or self.customConfig.timerConfig
	end

	if iconType == "bloodlust" then
		return isGlobal and self.globalCustomConfig.bloodlustConfig or self.customConfig.bloodlustConfig
	end

	return isGlobal and self.globalCustomConfig.itemConfig or self.customConfig.itemConfig
end

function SCM:GetConfigTableByID(configID, iconType, isGlobal)
	local configTable = self:GetConfigTable(iconType, isGlobal)
	return configTable and configTable[configID]
end

function SCM:UpdateCooldownInfo()
	if InCombatLockdown() then
		return
	end

	local previousConfig = self.defaultCooldownViewerConfig
	local defaultCooldownViewerConfig = {
		cooldownIDs = {},
		spellIDs = {},
	}

	local dataProvider = CooldownViewerSettings:GetDataProvider()
	local displayData = dataProvider and dataProvider.displayData.cooldownInfoByID
	for _, cooldownCategory in pairs(CooldownViewerSettingsDataProvider_GetCategories()) do
		defaultCooldownViewerConfig[cooldownCategory] = {
			spellIDs = {},
			cooldownIDs = {},
		}

		local cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(cooldownCategory, true)
		for _, cooldownID in ipairs(cooldownIDs) do
			local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
			local data = displayData and displayData[cooldownID]
			if info and data then
				data = CopyTable(data)
				if issecretvalue(data.spellID) then
					data = previousConfig and previousConfig.cooldownIDs[cooldownID]
				end

				if data then
					defaultCooldownViewerConfig[cooldownCategory][cooldownID] = data
					defaultCooldownViewerConfig[cooldownCategory].cooldownIDs[cooldownID] = data
					defaultCooldownViewerConfig.cooldownIDs[cooldownID] = data

					local spellID = data.spellID
					if spellID then
						defaultCooldownViewerConfig[cooldownCategory].spellIDs[spellID] = data
						defaultCooldownViewerConfig.spellIDs[spellID] = data
						for _, linkedSpellID in ipairs(data.linkedSpellIDs or {}) do
							if not issecretvalue(linkedSpellID) then
								defaultCooldownViewerConfig[cooldownCategory].spellIDs[linkedSpellID] = data
								defaultCooldownViewerConfig.spellIDs[linkedSpellID] = data
							end
						end
					end
				end
			end
		end
	end

	self.defaultCooldownViewerConfig = defaultCooldownViewerConfig
end
