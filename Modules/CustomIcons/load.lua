local SCM = select(2, ...)

local CustomIcons = SCM.CustomIcons
local Utils = SCM.Utils
local GetIconType = Utils.GetIconType
local CustomIconAlwaysVisibilityConfigs = CustomIcons.AlwaysVisibilityConfigs

function CustomIcons.HasAlwaysVisibilityRule(config)
	local visibilityRules = config.effectRules and config.effectRules.visibility
	local rules = visibilityRules and visibilityRules.rules
	if not rules then
		return
	end

	for i = 1, #rules do
		if rules[i].state == "always" then
			return true
		end
	end
end

function CustomIcons.ShouldCreateCustomIcon(config)
	local iconType = GetIconType(config)
	if iconType == "empty" then
		return true
	end

	local hasAlwaysVisibility = CustomIconAlwaysVisibilityConfigs[config]

	if iconType == "spell" or iconType == "timer" or iconType == "bloodlust" then
		return config.spellID and (hasAlwaysVisibility or C_Spell.DoesSpellExist(config.spellID))
	end

	if iconType == "item" then
		return config.itemID and (hasAlwaysVisibility or C_Item.DoesItemExistByID(config.itemID))
	end

	if iconType == "slot" and config.slotID then
		local itemID = GetInventoryItemID("player", config.slotID)
		return itemID and (not config.filterItems or not config.filterItems[itemID]) and C_Item.DoesItemExistByID(itemID) and (hasAlwaysVisibility or C_Item.GetItemSpell(itemID))
	end
end

function CustomIcons.GetDefaultLoadClasses()
	local loadClasses = {}
	for classFile in pairs(SCM.Utils.GetClassList(false)) do
		loadClasses[classFile] = false
	end
	return loadClasses
end

function CustomIcons.GetDefaultLoadRaces()
	local loadRaces = {}
	for raceID in pairs(SCM.Constants.Races) do
		loadRaces[raceID] = false
	end
	return loadRaces
end

local function MatchesLoadFilter(loadFilter, value)
	if loadFilter then
		if not next(loadFilter) then
			return false
		end

		return loadFilter[value]
	end

	return true
end

function CustomIcons.ShouldLoadCustomIcon(config)
	if config.useLoadRole and not MatchesLoadFilter(config.loadRoles, SCM.currentRole) then
		return false
	end

	if config.useLoadClass and not MatchesLoadFilter(config.loadClasses, SCM.currentClass) then
		return false
	end

	if config.useLoadRace and not MatchesLoadFilter(config.loadRaces, SCM.currentRace) then
		return false
	end

	if config.useSpellKnown or config.useSpellKnown == nil then
		if not config.spellKnownSpellID or type(config.spellKnownSpellID) ~= "number" then
			return true
		end

		local isSpellKnown = C_SpellBook.IsSpellKnown(config.spellKnownSpellID)
		return (config.useSpellKnown and isSpellKnown) or (config.useSpellKnown == nil and not isSpellKnown)
	end

	return true
end
