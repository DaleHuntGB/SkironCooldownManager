local _, SCM = ...

local Cache = SCM.Cache
local Utils = SCM.Utils
local CDM = SCM.CDM
local Icons = SCM.Icons
local SortBySCMOrder = Utils.SortBySCMOrder

local DEFAULT_ROW_CONFIG = { { limit = 8, iconWidth = 47, iconHeight = 47 } }
local DEFAULT_ANCHOR = { "CENTER", UIParent, "CENTER", 0, 0 }

local function GetAnchorState(group)
	local state = Cache.cachedAnchorStates[group]
	if not state then
		state = { rows = {} }
		Cache.cachedAnchorStates[group] = state
	end

	return state
end

local function GetNextLayoutDuplicateChild(child, masterCooldownID, masterChild)
	local duplicateChild = child.SCMLayoutNextDuplicate
	if duplicateChild and (duplicateChild == masterChild or duplicateChild:GetCooldownID() ~= masterCooldownID) then
		child.SCMLayoutNextDuplicate = nil
		return
	end

	return duplicateChild
end

local function LayoutManagedAnchorChild(child, row, anchorConfig, childAnchor, startPoint, offsetX, useProxyAnchor)
	child.SCMRowConfig = row.rowConfig
	child.SCMAnchorFrameStrata = anchorConfig and anchorConfig.frameStrata or nil

	if child.SCMLayoutLimited then
		child.SCMLayoutLimited = nil
		Icons.SetChildVisibilityState(child, child.SCMShouldBeVisible, true)
	end

	if child.SCMShouldBeVisible then
		SCM:UpdateManagedAnchorChild(child, childAnchor, startPoint, offsetX, row.offsetY, row.rowIconWidth, row.rowIconHeight, useProxyAnchor)
	end

	if not child.SCMBuffBar then
		local frameStrata = SCM.db.profile.options.iconFrameStrata
		child:SetFrameStrata(frameStrata and frameStrata ~= "" and frameStrata or "MEDIUM")
		child:SetFrameLevel(childAnchor:GetFrameLevel() - 1)
		SCM:SkinChild(child, child.SCMConfig)
	else
		SCM:SkinBuffBar(child, child.SCMConfig)
	end
	child.SCMChanged = false
end

local function GetDuplicateChildren(layoutChildren, layoutChildCount)
	local uniqueChildren = Cache.cachedLayoutChildren
	local seenCooldownIDs = Cache.cachedLayoutCooldownIDs
	local hasDuplicateChildren = false
	local totalChildren = 0

	if not uniqueChildren then
		uniqueChildren = {}
		Cache.cachedLayoutChildren = uniqueChildren
	else
		wipe(uniqueChildren)
	end
	if not seenCooldownIDs then
		seenCooldownIDs = {}
		Cache.cachedLayoutCooldownIDs = seenCooldownIDs
	else
		wipe(seenCooldownIDs)
	end

	for index = 1, layoutChildCount do
		local child = layoutChildren[index]
		local cooldownID = child.SCMCooldownID
		child.SCMLayoutNextDuplicate = nil

		if cooldownID then
			local masterChild = seenCooldownIDs[cooldownID]
			if masterChild then
				hasDuplicateChildren = true
				if masterChild ~= child then
					child.SCMLayoutNextDuplicate = masterChild.SCMLayoutNextDuplicate
					masterChild.SCMLayoutNextDuplicate = child
				end
			else
				seenCooldownIDs[cooldownID] = child
				totalChildren = totalChildren + 1
				uniqueChildren[totalChildren] = child
			end
		else
			totalChildren = totalChildren + 1
			uniqueChildren[totalChildren] = child
		end
	end

	wipe(seenCooldownIDs)
	if hasDuplicateChildren then
		return uniqueChildren, totalChildren
	end

	wipe(uniqueChildren)
	return layoutChildren, layoutChildCount
end

local function GetMatchedAnchorWidth(group, anchorConfig)
	if not anchorConfig.matchAnchorWidth or not Utils.IsBuffBarGroup(group) then
		return
	end

	local anchorFrame = Utils.GetActiveAnchorFrame((anchorConfig.anchor or DEFAULT_ANCHOR)[2])
	if not anchorFrame then
		return
	end

	local matchedAnchorWidth = max(anchorFrame:GetWidth(), 1)
	if anchorFrame.SCMProxyGroup then
		SCM.SCMRefreshMatchedBuffBarWidths = true
	elseif not anchorFrame.SCMBuffBarWidthHook then
		anchorFrame.SCMBuffBarWidthHook = true
		anchorFrame:HookScript("OnSizeChanged", function()
			if InCombatLockdown() then
				SCM.SCMRefreshMatchedBuffBarWidths = true
				return
			end

			SCM:ApplyBuffBarCDManagerConfig()
		end)
	end

	return matchedAnchorWidth
end

local function ShouldLayoutChildren(group, visibleChildren, state, anchorConfig, resetSize, allowLayoutSkip)
	local configuredChildren = Cache.cachedChildrenTbl[group]
	local visibleChildCount = #visibleChildren
	local configuredChildCount = configuredChildren and #configuredChildren or 0
	local layoutSignature = visibleChildCount
	local hasChangedChild = false
	local lockGroupSize = group == 1 and SCM.anchorFrames[1] and SCM.anchorFrames[1]:IsProtected() and InCombatLockdown()

	table.sort(visibleChildren, SortBySCMOrder)
	for index = 1, visibleChildCount do
		local child = visibleChildren[index]
		hasChangedChild = hasChangedChild or child.SCMChanged
		local cooldownID = child.SCMCooldownID
		local cooldownSignature = tonumber(cooldownID) or 0
		if cooldownSignature == 0 and cooldownID then
			cooldownID = tostring(cooldownID)
			for byteIndex = 1, #cooldownID do
				cooldownSignature = cooldownSignature + (cooldownID:byte(byteIndex) * byteIndex)
			end
		end
		layoutSignature = layoutSignature + (cooldownSignature * index) + ((child.SCMOrder or 0) * 17)
	end

	local layoutChildren = visibleChildren
	if (anchorConfig.grow or "CENTERED") == "FIXED" then
		layoutChildren = configuredChildren or visibleChildren
		table.sort(layoutChildren, SortBySCMOrder)
	end

	Cache.cachedAnchorChildren[group] = visibleChildren
	state.visibleChildCount = visibleChildCount

	local layoutChildCount = #layoutChildren
	layoutSignature = layoutSignature + (configuredChildCount * 31) + (layoutChildCount * 131) + (lockGroupSize and 8191 or 0)

	if allowLayoutSkip and not hasChangedChild and not resetSize and not SCM.isOptionsOpen and state.layoutSignature == layoutSignature then
		return
	end

	state.layoutSignature = layoutSignature
	layoutChildren, layoutChildCount = GetDuplicateChildren(layoutChildren, layoutChildCount)

	return layoutChildren, layoutChildCount, lockGroupSize and layoutChildCount or visibleChildCount
end

local function BuildRowLayout(group, rows, rowConfig, anchorConfig, layoutChildCount, hardLimitChildCount)
	local lastRowConfig = rowConfig[#rowConfig]
	local baseSpacing = anchorConfig.spacing or 0
	local growsUp = (anchorConfig.secondaryGrow or "DOWN") == "UP"
	-- Doesn't exist yet as an option but it will at some point
	local scaleData = anchorConfig.advancedScale
	local matchedAnchorWidth = GetMatchedAnchorWidth(group, anchorConfig)
	local childIndex = 1
	local rowIndex = 1
	local rowCount = 0
	local accumulatedY = 0
	local maxGroupWidth = 0
	local totalChildren = layoutChildCount

	while childIndex <= totalChildren do
		local currentRowConfig = rowConfig[rowIndex] or lastRowConfig
		local rowLimit = max(currentRowConfig.limit or 8, 1)
		if currentRowConfig.hardLimit then
			totalChildren = min(hardLimitChildCount, layoutChildCount, childIndex + rowLimit - 1)
		end

		local rowIconWidth = currentRowConfig.iconWidth or currentRowConfig.size or 47
		local rowIconHeight = currentRowConfig.iconHeight or currentRowConfig.size or 47

		if scaleData then
			local targetViewer = Cache.cachedCooldownFrameTbl[scaleData.viewer]
			local targetGroup = targetViewer and targetViewer[scaleData.anchorGroup]
			if targetGroup and #targetGroup <= scaleData.numChildren then
				rowIconWidth = scaleData.iconWidth or scaleData.size or rowIconWidth
				rowIconHeight = scaleData.iconHeight or scaleData.size or rowIconHeight
			end
		end

		if matchedAnchorWidth then
			rowIconWidth = matchedAnchorWidth
		end

		local endIndex = min(childIndex + rowLimit - 1, totalChildren)
		local numInRow = endIndex - childIndex + 1
		local rowWidth = (numInRow * rowIconWidth) + ((numInRow - 1) * baseSpacing)
		local fixedWidth = (currentRowConfig.useFixedWidth and currentRowConfig.fixedWidth) or rowWidth
		local row = rows[rowCount + 1]

		if fixedWidth > maxGroupWidth then
			maxGroupWidth = fixedWidth
		end

		if not row then
			row = {}
			rows[rowCount + 1] = row
		end

		rowCount = rowCount + 1
		row.startIndex = childIndex
		row.endIndex = endIndex
		row.rowConfig = currentRowConfig
		row.rowIconWidth = rowIconWidth
		row.rowIconHeight = rowIconHeight
		row.rowWidth = rowWidth
		row.offsetY = growsUp and accumulatedY or -accumulatedY

		accumulatedY = accumulatedY + rowIconHeight + baseSpacing
		childIndex = endIndex + 1
		rowIndex = rowIndex + 1
	end

	for index = rowCount + 1, #rows do
		rows[index] = nil
	end

	local firstRow = rows[1]
	local firstRowConfig = rowConfig[1]
	local firstRowWidth = (firstRow and firstRow.rowIconWidth) or (firstRowConfig.useFixedWidth and firstRowConfig.fixedWidth) or firstRowConfig.iconWidth or firstRowConfig.size or 47
	local firstRowHeight = (firstRow and firstRow.rowIconHeight) or firstRowConfig.iconHeight or firstRowConfig.size or 47
	local effectiveWidth = matchedAnchorWidth or max(firstRowWidth, maxGroupWidth, 1)
	local effectiveHeight = max(firstRowHeight, accumulatedY - baseSpacing, 1)
	local heightDelta = max(effectiveHeight - firstRowHeight, 0)
	local point = (anchorConfig.anchor or DEFAULT_ANCHOR)[1]
	local pivot = SCM:GetAnchorPivot(point, anchorConfig.grow or "CENTERED")
	local anchorOffsetY = growsUp and ((pivot:find("TOP") and heightDelta) or (not pivot:find("BOTTOM") and heightDelta / 2) or 0)
		or ((pivot:find("BOTTOM") and -heightDelta) or (not pivot:find("TOP") and -heightDelta / 2) or 0)

	return rowCount, totalChildren, firstRowWidth, effectiveWidth, effectiveHeight, anchorOffsetY, pivot
end
local function ApplyGroupAnchor(group, state, anchorConfig, firstRowWidth, effectiveWidth, effectiveHeight, anchorOffsetY, changedGroups)
	local point, anchor, relativePoint, xOffset, yOffset = unpack(anchorConfig.anchor or DEFAULT_ANCHOR)
	local growDir = anchorConfig.grow or "CENTERED"
	local parentGroup = Utils.ParseAnchorString(anchor)
	local anchorResized = state.effectiveWidth ~= effectiveWidth or state.effectiveHeight ~= effectiveHeight
	local boundsChanged = anchorResized or state.anchorOffsetY ~= anchorOffsetY
	local parentChanged = state.parentGroup ~= parentGroup

	state.relativePoint = relativePoint
	state.parentGroup = parentGroup
	state.effectiveWidth = effectiveWidth
	state.effectiveHeight = effectiveHeight
	state.anchorOffsetY = anchorOffsetY

	local wasUsingProxy = state.currentProxyActive and true or false
	local groupAnchor = SCM:GetAnchor(group, point, anchor, relativePoint, xOffset, yOffset, growDir, firstRowWidth, effectiveWidth, effectiveHeight, anchorOffsetY)

	if parentChanged then
		Cache.cachedAnchorLinksDirty = true
	end

	local anchorSizeApplied = groupAnchor and (not InCombatLockdown() or not groupAnchor:IsProtected())
	if anchorSizeApplied or not state.appliedWidth then
		state.appliedWidth = effectiveWidth
	end
	if anchorSizeApplied or not state.appliedHeight then
		state.appliedHeight = effectiveHeight
	end
	if anchorSizeApplied or not state.appliedAnchorOffsetY then
		state.appliedAnchorOffsetY = anchorOffsetY
	end

	local childAnchor, useProxyAnchor = SCM:GetManagedAnchorChildAnchor(group, groupAnchor, point, anchor, relativePoint, xOffset, yOffset, growDir, firstRowWidth, effectiveWidth, effectiveHeight, anchorOffsetY)
	if SCM.initialized and (anchorResized or wasUsingProxy ~= useProxyAnchor) then
		SCM.Callbacks:Fire("SCM_AnchorChanged", group, childAnchor, effectiveWidth, effectiveHeight, useProxyAnchor)
	end

	local anchorOffsetChanged = SCM:UpdateAnchorOffset(group, true)
	if useProxyAnchor and changedGroups and anchorOffsetChanged then
		changedGroups[group] = true
	end

	return childAnchor, useProxyAnchor, boundsChanged
end

local function LayoutChildAndDuplicates(child, row, anchorConfig, childAnchor, startPoint, offsetX, useProxyAnchor)
	LayoutManagedAnchorChild(child, row, anchorConfig, childAnchor, startPoint, offsetX, useProxyAnchor)

	if not child.SCMLayoutNextDuplicate then
		return
	end

	local masterChild = child
	local masterCooldownID = child.SCMCooldownID
	local duplicateChild = GetNextLayoutDuplicateChild(child, masterCooldownID, masterChild)
	while duplicateChild do
		child = duplicateChild
		LayoutManagedAnchorChild(child, row, anchorConfig, childAnchor, startPoint, offsetX, useProxyAnchor)
		duplicateChild = GetNextLayoutDuplicateChild(child, masterCooldownID, masterChild)
	end
end

local function GetStartPoint(anchorConfig)
	local growDir = anchorConfig.grow or "CENTERED"
	local verticalPoint = (anchorConfig.secondaryGrow or "DOWN") == "UP" and "BOTTOM" or "TOP"
	if growDir == "CENTER" or growDir == "CENTERED" or growDir == "FIXED" then
		return verticalPoint
	end

	return verticalPoint .. (growDir == "LEFT" and "RIGHT" or "LEFT")
end

local function LayoutRows(layoutChildren, rows, rowCount, anchorConfig, childAnchor, startPoint, useProxyAnchor)
	local growDir = anchorConfig.grow or "CENTERED"
	local baseSpacing = anchorConfig.spacing or 0
	local centeredRows = growDir == "CENTER" or growDir == "CENTERED" or growDir == "FIXED"

	for currentRow = 1, rowCount do
		local row = rows[currentRow]
		for currentChild = row.startIndex, row.endIndex do
			local rowChild = currentChild - row.startIndex
			local offsetX = 0

			if centeredRows then
				offsetX = (rowChild * (row.rowIconWidth + baseSpacing)) - (row.rowWidth / 2) + (row.rowIconWidth / 2)
			elseif growDir == "LEFT" then
				offsetX = -(rowChild * (row.rowIconWidth + baseSpacing))
			else
				offsetX = rowChild * (row.rowIconWidth + baseSpacing)
			end

			LayoutChildAndDuplicates(layoutChildren[currentChild], row, anchorConfig, childAnchor, startPoint, offsetX, useProxyAnchor)
		end
	end
end

local function HandleDuplicates(child)
	if child.SCMShouldBeVisible then
		child.SCMLayoutLimited = true
		child.SCMLayoutApplied = nil
		Icons.SetChildVisibilityState(child, child.SCMShouldBeVisible, true)
	end

	if not child.SCMLayoutNextDuplicate then
		return
	end

	local masterChild = child
	local masterCooldownID = child.SCMCooldownID
	local duplicateChild = GetNextLayoutDuplicateChild(child, masterCooldownID, masterChild)
	while duplicateChild do
		child = duplicateChild
		if child.SCMShouldBeVisible then
			child.SCMLayoutLimited = true
			child.SCMLayoutApplied = nil
			Icons.SetChildVisibilityState(child, child.SCMShouldBeVisible, true)
		end
		duplicateChild = GetNextLayoutDuplicateChild(child, masterCooldownID, masterChild)
	end
end

local function HandleOverFlowAndDuplicates(layoutChildren, totalChildren, layoutChildCount)
	if totalChildren >= layoutChildCount then
		return
	end

	for index = totalChildren + 1, layoutChildCount do
		HandleDuplicates(layoutChildren[index])
	end
end

local function LayoutAnchorGroup(group, visibleChildren, anchorConfig, options, changedGroups, resetSize, allowLayoutSkip)
	Cache.cachedVisitedAnchorGroups[group] = true
	if not anchorConfig then
		return
	end

	local state = GetAnchorState(group)
	local rowConfig = anchorConfig.rowConfig or DEFAULT_ROW_CONFIG

	local layoutChildren, layoutChildCount, hardLimitChildCount = ShouldLayoutChildren(group, visibleChildren, state, anchorConfig, resetSize, allowLayoutSkip)
	if not layoutChildren then
		return
	end

	local rowCount, totalChildren, firstRowWidth, effectiveWidth, effectiveHeight, anchorOffsetY, pivot = BuildRowLayout(
		group,
		state.rows,
		rowConfig,
		anchorConfig,
		layoutChildCount,
		hardLimitChildCount
	)
	state.startPoint = GetStartPoint(anchorConfig)
	state.pivot = pivot
	local childAnchor, useProxyAnchor, boundsChanged = ApplyGroupAnchor(group, state, anchorConfig, firstRowWidth, effectiveWidth, effectiveHeight, anchorOffsetY, changedGroups)

	LayoutRows(layoutChildren, state.rows, rowCount, anchorConfig, childAnchor, state.startPoint, useProxyAnchor)
	HandleOverFlowAndDuplicates(layoutChildren, totalChildren, layoutChildCount)

	if not InCombatLockdown() and group == 1 then
		if options.adjustResourceWidth and C_AddOns.IsAddOnLoaded("SenseiClassResourceBar") then
			if SCRB and SCRB.registerCustomFrame then
				SCRB.registerCustomFrame(SCM:GetAnchor(1))
			else
				SCM:UpdateResourceBarWidth(effectiveWidth)
			end
		end

		SCM:UpdateUFValues(options, effectiveWidth, rowConfig)
	end

	if group == 1 then
		SCM:ApplyCustomAnchors(effectiveWidth, rowConfig)
	end

	if boundsChanged and changedGroups then
		changedGroups[group] = true
	end

	if layoutChildren == Cache.cachedLayoutChildren then
		wipe(layoutChildren)
	end
end

CDM.LayoutAnchorGroup = LayoutAnchorGroup
