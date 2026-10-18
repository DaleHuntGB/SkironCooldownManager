local SCM = select(2, ...)

local layoutUpdateQueues = {}
local pendingLayoutCallbacks = {}

local function ApplyCooldownViewerLayout()
	SCM:ApplyAllCDManagerConfigs(true, true)
	SCM:InitializeCastBar()
	SCM:RefreshResourceBarConfig(true, true)
	SCM:RefreshAuraContainers()

	if SCM.isForever then
		SCM:InitializeSwingTimer()
	end
end

local function ApplyLayoutUpdates(callback, ...)
	local result = callback(...)
	while next(pendingLayoutCallbacks) do
		local pendingCallback = pendingLayoutCallbacks[ApplyCooldownViewerLayout] and ApplyCooldownViewerLayout or next(pendingLayoutCallbacks)
		local owners = layoutUpdateQueues[pendingCallback]
		local owner = next(owners)

		if owner then
			owners[owner] = nil
		end

		if not next(owners) then
			pendingLayoutCallbacks[pendingCallback] = nil
		end

		pendingCallback(owner)
	end
	return result
end

function SCM:RunLayoutBatch(callback, ...)
	if self.layoutUpdatesSuspended then
		return callback(...)
	end

	self.layoutUpdatesSuspended = true
	local success, result = pcall(ApplyLayoutUpdates, callback, ...)
	self.layoutUpdatesSuspended = nil

	if not success then
		wipe(pendingLayoutCallbacks)
		for _, owners in pairs(layoutUpdateQueues) do
			wipe(owners)
		end
		error(result, 0)
	end
	return result
end

function SCM:RequestLayoutUpdate(owner, callback)
	if not self.layoutUpdatesSuspended then
		callback(owner)
		return
	end

	local owners = layoutUpdateQueues[callback]
	if not owners then
		owners = {}
		layoutUpdateQueues[callback] = owners
	end

	owners[owner] = true
	pendingLayoutCallbacks[callback] = true
end

function SCM:CreateLayoutCallback(callback)
	return function(owner)
		self:RequestLayoutUpdate(owner, callback)
	end
end

function SCM.RefreshCooldownViewerLayout()
	SCM:RequestLayoutUpdate(SCM, ApplyCooldownViewerLayout)
end
