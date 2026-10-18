local SCM = select(2, ...)

local CURSOR_SIZES = { [0] = 32, 48, 64, 96, 128 }
local cursorFrame

SCMCursorMixin = {}

function SCMCursorMixin:SetInterval(interval)
	self.interval = interval
end

function SCMCursorMixin:UpdateSize()
	local cursorSize = CURSOR_SIZES[tonumber(C_CVar.GetCVar("cursorSizePreferred"))] or 32
	local size = cursorSize / UIParent:GetEffectiveScale()
	self:SetSize(size, size)
end

function SCMCursorMixin:UpdatePosition()
	local x, y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

function SCMCursorMixin:OnUpdate(elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed < self.interval then
		return
	end

	self.elapsed = 0
	self:UpdatePosition()
end

function SCM:SetCursorEnabled(enabled)
	if enabled then
		if not cursorFrame then
			cursorFrame = CreateFrame("Frame", "SCM_Cursor", UIParent, "SCMCursorTemplate")
		end

		SCM_Cursor = cursorFrame
		cursorFrame:SetInterval(self.db.profile.options.cursorUpdateInterval)
		cursorFrame.elapsed = 0
		cursorFrame:UpdateSize()
		cursorFrame:UpdatePosition()
		cursorFrame:Show()
	else
		SCM_Cursor = nil
		if cursorFrame then
			cursorFrame:Hide()
		end
	end

	if self.initialized then
		SCM.RefreshCooldownViewerLayout()
	end
end
