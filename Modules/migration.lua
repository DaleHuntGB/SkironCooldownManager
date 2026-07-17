local SCM = select(2, ...)

local Utils = SCM.Utils
local GetCooldownConfigKey = Utils.GetCooldownConfigKey
local ToBuffBarGroup = Utils.ToBuffBarGroup
local IsBuffBarGroup = Utils.IsBuffBarGroup
local GlobalGlowSubregion = SCM.Constants.GlobalGlowSubregion

local function CreateCooldownBreakpoints(options)
	if not options.cooldownBreakpoints or #options.cooldownBreakpoints == 0 then
		options.cooldownBreakpoints = CopyTable(SCM.Constants.CooldownTimer.DefaultBreakpoints)
	else
		for _, breakpoint in ipairs(options.cooldownBreakpoints) do
			if not breakpoint.threshold then
				breakpoint.threshold = 0
			end

			if not breakpoint.step then
				breakpoint.step = 1
			end

			if breakpoint.components then
				local components = breakpoint.components
				local nextIndex = 1
				for i = 1, 10 do
					local component = components[i]
					if component then
						if i ~= nextIndex then
							components[nextIndex] = component
							components[i] = nil
						end

						nextIndex = nextIndex + 1
					end
				end
			end
		end
	end
end

local function CreateTrackedBarSpellConfig(spellConfig)
	if type(spellConfig) ~= "table" then
		return
	end

	for _, config in pairs(spellConfig) do
		if type(config) == "table" and type(config.source) == "table" and type(config.anchorGroup) == "table" then
			local trackedBarGroup = config.source[Enum.CooldownViewerCategory.TrackedBar]
			local normalizedTrackedBarGroup = Utils.NormalizeBuffBarGroup(trackedBarGroup)
			local legacyGroup = normalizedTrackedBarGroup and (normalizedTrackedBarGroup - 200)
			local groupConfig = (trackedBarGroup and config.anchorGroup[trackedBarGroup]) or (legacyGroup and config.anchorGroup[legacyGroup])

			if trackedBarGroup ~= normalizedTrackedBarGroup then
				config.source[Enum.CooldownViewerCategory.TrackedBar] = normalizedTrackedBarGroup
			end

			if normalizedTrackedBarGroup and groupConfig then
				config.anchorGroup[normalizedTrackedBarGroup] = groupConfig
			end

			if trackedBarGroup and trackedBarGroup ~= normalizedTrackedBarGroup then
				config.anchorGroup[trackedBarGroup] = nil
			end

			if legacyGroup and legacyGroup ~= normalizedTrackedBarGroup then
				config.anchorGroup[legacyGroup] = nil
			end
		end
	end
end

local function SetEffectRules(config, effect, rules)
	local effectRules = config.effectRules

	if not effectRules[effect] then
		effectRules[effect] = {
			rules = rules,
		}
	end
end

local function MigrateVisibilityRules(config, isBuffIcon)
	local hasVisibilityRules = config.effectRules.visibility ~= nil
	local shouldCreateRules = isBuffIcon or config.hideWhenInactive or config.hideWhenNotOnCooldown

	if not hasVisibilityRules and shouldCreateRules then
		local rules
		if isBuffIcon then
			if config.showWhileInactive then
				rules = {
					{ state = "active", value = "hide" },
					{ state = "inactive", value = "show" },
				}
			elseif config.alwaysShow then
				rules = {
					{ state = "active", value = "show" },
					{ state = "inactive", value = "show" },
				}
			else
				rules = {
					{ state = "active", value = "show" },
					{ state = "inactive", value = "hide" },
				}
			end
		elseif config.hideWhenNotOnCooldown then
			rules = {
				{ state = "cooldown", value = "show" },
				{ state = "ready", value = "hide" },
			}
		else
			rules = {
				{ state = "active", value = "show" },
				{ state = "inactive", value = "hide" },
			}
		end

		SetEffectRules(config, "visibility", rules)
	end

	config.hideWhenInactive = nil
	config.hideWhenNotOnCooldown = nil
	config.alwaysShow = nil
	config.showWhileInactive = nil
end

local function MigrateDesaturateRules(config, isBuffIcon)
	local hasDesaturateRules = config.effectRules.desaturate ~= nil
	if not hasDesaturateRules and isBuffIcon then
		local rules = {
			{ state = "active", enabled = false },
		}

		if config.desaturate then
			rules[2] = { state = "inactive", enabled = true }
		elseif config.alwaysShow or config.showWhileInactive then
			rules[2] = { state = "inactive", enabled = false }
		end

		SetEffectRules(config, "desaturate", rules)
	end

	config.desaturate = nil
end

local function MigrateGlowRules(config)
	local hasGlowRules = config.effectRules.glow ~= nil
	local shouldCreateRules = config.glowWhileActive or config.glowWhileInactive

	if not hasGlowRules and shouldCreateRules then
		local state = config.glowWhileActive and "active" or "inactive"
		SetEffectRules(config, "glow", {
			{ state = state, subregion = GlobalGlowSubregion },
		})
	end

	config.glowWhileActive = nil
	config.glowWhileInactive = nil
end

local function MigrateLegacyIconOptions(spellConfig)
	for _, config in pairs(spellConfig) do
		local source = config.source
		local anchorGroups = config.anchorGroup

		local buffIconGroup = source[Enum.CooldownViewerCategory.TrackedBuff]
		for anchorGroup, anchorGroupConfig in pairs(anchorGroups) do
			if not IsBuffBarGroup(anchorGroup) then
				local isBuffIcon = anchorGroup == buffIconGroup
				anchorGroupConfig.effectRules = anchorGroupConfig.effectRules or {}
				MigrateDesaturateRules(anchorGroupConfig, isBuffIcon)
				MigrateVisibilityRules(anchorGroupConfig, isBuffIcon)
				MigrateGlowRules(anchorGroupConfig)
			end
		end
	end
end

local function HasAnchorConfig(anchorGroup, anchorConfig, buffBarsAnchorConfig)
	anchorGroup = tonumber(anchorGroup)
	if not anchorGroup then
		return
	end

	if IsBuffBarGroup(anchorGroup) then
		return buffBarsAnchorConfig and buffBarsAnchorConfig[anchorGroup - ToBuffBarGroup(0)]
	end

	return anchorConfig and anchorConfig[anchorGroup]
end

local function RemoveOldSpellConfigAnchors(config, anchorConfig, buffBarsAnchorConfig)
	local source = type(config) == "table" and config.source
	local anchorGroups = type(config) == "table" and config.anchorGroup
	if type(anchorGroups) ~= "table" then
		return
	end

	if type(source) == "table" then
		for sourceIndex, anchorGroup in pairs(source) do
			if not HasAnchorConfig(anchorGroup, anchorConfig, buffBarsAnchorConfig) then
				source[sourceIndex] = nil
			end
		end
	end

	for anchorGroup in pairs(anchorGroups) do
		if not HasAnchorConfig(anchorGroup, anchorConfig, buffBarsAnchorConfig) then
			anchorGroups[anchorGroup] = nil
		end
	end

	return next(anchorGroups)
end

local function HasCustomAnchorConfig(config, anchorConfig)
	local anchorGroup = type(config) == "table" and config.anchorGroup
	return type(anchorGroup) == "number" and HasAnchorConfig(anchorGroup, anchorConfig)
end

local function RemoveOldSpellConfigAnchorsFromTable(spellConfig, anchorConfig, buffBarsAnchorConfig)
	if type(spellConfig) ~= "table" then
		return
	end

	for configID, config in pairs(spellConfig) do
		if not RemoveOldSpellConfigAnchors(config, anchorConfig, buffBarsAnchorConfig) then
			spellConfig[configID] = nil
		end
	end
end

local function RemoveOldCustomConfigAnchors(customConfig, anchorConfig)
	if type(customConfig) ~= "table" then
		return
	end

	for _, configKey in ipairs({ "spellConfig", "itemConfig", "slotConfig", "timerConfig" }) do
		local configTable = customConfig[configKey]
		if type(configTable) == "table" then
			for id, config in pairs(configTable) do
				if not HasCustomAnchorConfig(config, anchorConfig) then
					configTable[id] = nil
				end
			end
		end
	end
end

local function MigrateLegacyGlobalConfigToProfiles(self)
	local globalDB = self.db.global
	local legacyAnchorConfig = globalDB.globalAnchorConfig
	local legacyCustomConfig = globalDB.globalCustomConfig
	if not legacyAnchorConfig and not legacyCustomConfig then
		return
	end

	local profiles = self.db.profiles
	for _, profile in pairs(profiles) do
		if legacyAnchorConfig and not profile.globalAnchorConfig then
			profile.globalAnchorConfig = CopyTable(legacyAnchorConfig)
		end

		if legacyCustomConfig then
			local profileCustomConfig = profile.globalCustomConfig
			if profileCustomConfig == nil then
				profile.globalCustomConfig = CopyTable(legacyCustomConfig)
			elseif profileCustomConfig == "table" then
				for key, config in pairs(legacyCustomConfig) do
					if not profileCustomConfig[key] then
						profileCustomConfig[key] = CopyTable(config)
					end
				end
			end
		end
	end

	globalDB.globalAnchorConfig = nil
	globalDB.globalCustomConfig = nil
end

local function RemoveOldAnchorConfigs(currentConfig, globalAnchorConfig, globalCustomConfig)
	if type(currentConfig) == "table" then
		RemoveOldSpellConfigAnchorsFromTable(currentConfig.spellConfig, currentConfig.anchorConfig, currentConfig.buffBarsAnchorConfig)
		RemoveOldCustomConfigAnchors(currentConfig.customConfig, currentConfig.anchorConfig)
	end

	RemoveOldCustomConfigAnchors(globalCustomConfig, globalAnchorConfig)
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

local function MigrateLegacySpellConfigKeys(spellConfig, defaultCooldownViewerConfig)
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

function SCM:MigrateLegacyProfileOptions()
	local legacyOptions = self.db.global.options
	if type(legacyOptions) ~= "table" then
		return
	end

	for _, profile in pairs(self.db.profiles) do
		if type(profile) == "table" and type(profile.options) ~= "table" then
			profile.options = CopyTable(legacyOptions)
		end
	end
end

function SCM:MigrateDB()
	MigrateLegacyGlobalConfigToProfiles(self)

	local options = self.db.profile.options
	if options.enableIconSkinning == nil then
		options.enableIconSkinning = options.enableSkinning
	end
	if options.enableBuffBarSkinning == nil then
		options.enableBuffBarSkinning = options.enableSkinning
	end

	CreateCooldownBreakpoints(options)
	MigrateLegacySpellConfigKeys(self.spellConfig, self.defaultCooldownViewerConfig)
	CreateTrackedBarSpellConfig(self.spellConfig)
	MigrateLegacyIconOptions(self.spellConfig)
	RemoveOldAnchorConfigs(self.currentConfig, self.db.profile.globalAnchorConfig, self.db.profile.globalCustomConfig)
end
