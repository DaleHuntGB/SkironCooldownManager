local SCM = select(2, ...)

local CustomIcons = SCM.CustomIcons
local CustomSpellFrames = CustomIcons.SpellFrames
local BloodlustTimerEntries = CustomIcons.BloodlustTimerEntries

local BloodlustTimerEventFrame

local function TriggerBloodlustTimers(startTime)
	for i = 1, #BloodlustTimerEntries do
		local frame = CustomSpellFrames[BloodlustTimerEntries[i]]
		if frame and not frame.SCMReleased and not frame.lastCastStartTime then
			frame.lastCastStartTime = startTime
			SCM:ApplyAnchorGroupCDManagerConfig(frame.SCMGroup, frame.SCMGlobal)
		end
	end
end

local function OnBloodlustUnitAura(self, _, _, updateInfo)
	if not updateInfo.addedAuras then
		return
	end

	local auraData
	local now = GetTime()
	for spellID in pairs(SCM.Constants.SatedDebuffs) do
		auraData = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
		if auraData then
			if not self.expirationTime or now > self.expirationTime then
				self.expirationTime = auraData.expirationTime

				TriggerBloodlustTimers(auraData.expirationTime - auraData.duration)
			end
			return
		end
	end

	self.expirationTime = nil
end

function CustomIcons.UpdateBloodlustTimerEvent()
	if #BloodlustTimerEntries > 0 then
		if not BloodlustTimerEventFrame then
			BloodlustTimerEventFrame = CreateFrame("Frame")
			BloodlustTimerEventFrame:SetScript("OnEvent", OnBloodlustUnitAura)
		end
		BloodlustTimerEventFrame:RegisterUnitEvent("UNIT_AURA", "player")
	elseif BloodlustTimerEventFrame then
		BloodlustTimerEventFrame:UnregisterEvent("UNIT_AURA")
	end
end

function CustomIcons.GetActiveCustomTimer(frame, iconType, config, now)
	local duration
	if iconType == "spell" or iconType == "timer" or iconType == "bloodlust" then
		duration = config.duration
	end

	if not duration or duration <= 0 then
		return
	end

	local startTime = frame.lastCastStartTime
	if not startTime then
		return
	end

	if startTime + duration > (now + 0.1) then
		return startTime, duration
	end

	frame.lastCastStartTime = nil
end
