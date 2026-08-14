local SCM = select(2, ...)

local S = ElvUI and ElvUI[1]:GetModule('Skins', true)
if not S then return end

local function HandleTabs(tabGroup)
	for _, tab in pairs(tabGroup.tabs) do
		S:HandleTab(tab)
	end
end

-- Fires once per constructed widget, recycled widgets keep their skin
hooksecurefunc(LibStub('AceGUI-3.0'), 'RegisterAsContainer', function(_, widget)
	if widget.type ~= 'SCMHorizontalScrollFrame' then return end

	-- Pre-skin the arrows so they get left/right rotation instead of the up/down default
	S:HandleNextPrevButton(widget.scrollbar.Back, 'left')
	S:HandleNextPrevButton(widget.scrollbar.Forward, 'right')
	S:HandleTrimScrollBar(widget.scrollbar)
end)

function SCM:SkinOptionsFrame(frame, tabGroup)
	local rootFrame = frame.frame
	if not rootFrame.SCMElvUISkinned then
		rootFrame.SCMElvUISkinned = true

		S:HandleFrame(rootFrame, nil, true)
		S:HandleFrame(rootFrame.Inset)
		rootFrame.NineSlice:SetTemplate()
	end

	if not tabGroup.SCMElvUISkinned then
		tabGroup.SCMElvUISkinned = true

		S:HandleFrame(tabGroup.border)
		HandleTabs(tabGroup)
		hooksecurefunc(tabGroup, 'BuildTabs', HandleTabs)
	end
end
