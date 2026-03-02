local _, SCM = ...

local uidCounter = 0
local sessionSeed = math.floor(GetTimePreciseSec() * 1000000) % 0xFFFFFF

function SCM:UID(prefix)
	uidCounter = (uidCounter + 1) % 0xFFFFFF
	if uidCounter == 0 then
		uidCounter = 1
	end

	local rawUID = string.format("%08x%06x%06x", GetServerTime(), sessionSeed, uidCounter)
	if prefix and prefix ~= "" then
		return prefix .. "#" .. rawUID
	end
	return rawUID
end
