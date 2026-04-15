local PLUGIN = PLUGIN

local CATEGORIES_PER_PAGE = 6
local MENU_W = 220
local ENTRY_H = 36
local HEADER_H = 32
local FOOTER_H = 24
local PADDING = 8

local NUM_KEYS = {
	[KEY_1] = 1, [KEY_2] = 2, [KEY_3] = 3,
	[KEY_4] = 4, [KEY_5] = 5, [KEY_6] = 6,
	[KEY_7] = 7, [KEY_8] = 8, [KEY_9] = 9,
}

-- Active menu panel handle
local activeMenu = nil

local function closeMenu()
	if (IsValid(activeMenu)) then
		activeMenu:Remove()
	end
	activeMenu = nil
end

local function openMenu(categories)
	closeMenu()

	local totalPages = math.ceil(#categories / CATEGORIES_PER_PAGE)
	local page = 1

	local function getPageCategories()
		local startIdx = (page - 1) * CATEGORIES_PER_PAGE + 1
		local endIdx   = math.min(page * CATEGORIES_PER_PAGE, #categories)
		local result = {}
		for i = startIdx, endIdx do
			result[#result + 1] = { index = i, data = categories[i] }
		end
		return result
	end

	local menuH = HEADER_H + CATEGORIES_PER_PAGE * ENTRY_H + FOOTER_H + PADDING * 2
	local scrW, scrH = ScrW(), ScrH()
	local posX = PADDING * 3
	local posY = scrH / 2 - menuH / 2

	local panel = vgui.Create("DPanel")
	panel:SetPos(posX, posY)
	panel:SetSize(MENU_W, menuH)
	panel:SetMouseInputEnabled(false)
	panel:MakePopup()
	panel:SetKeyboardInputEnabled(false)
	activeMenu = panel

	-- Rebuild the visible entries (called on page change too)
	local function rebuild()
		panel:Clear()

		local pageItems = getPageCategories()

		panel.Paint = function(self, w, h)
			-- Background
			draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 210))
			-- Header bar
			draw.RoundedBoxEx(4, 0, 0, w, HEADER_H, Color(40, 40, 40, 230), true, true, false, false)

			local title = L("calloutMenuTitle")
			draw.SimpleText(title, "DermaDefaultBold", w / 2, HEADER_H / 2, Color(220, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			-- Entries
			for i, item in ipairs(pageItems) do
				local entryY = HEADER_H + PADDING + (i - 1) * ENTRY_H
				local isHovered = (self.hoveredIndex == i)
				local bg = isHovered and Color(70, 100, 140, 200) or Color(30, 30, 30, 160)
				draw.RoundedBox(3, PADDING, entryY, w - PADDING * 2, ENTRY_H - 2, bg)

				-- Number badge
				draw.RoundedBox(3, PADDING + 4, entryY + 6, 22, ENTRY_H - 14, Color(60, 120, 200, 220))
				draw.SimpleText(tostring(i), "DermaDefaultBold", PADDING + 15, entryY + ENTRY_H / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				-- Category label
				draw.SimpleText(L(item.data.labelKey), "DermaDefault", PADDING + 34, entryY + ENTRY_H / 2, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

			-- Footer: page indicator + mouse button hints (only if multi-page)
			if (totalPages > 1) then
				local footerY = h - FOOTER_H - PADDING / 2
				local pageText = L("calloutMenuPage", page, totalPages)
				draw.SimpleText(pageText, "DermaDefault", w / 2, footerY + FOOTER_H / 2, Color(160, 160, 160), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				draw.SimpleText("M4/M5: 페이지 전환", "DermaDefault", w / 2, footerY + FOOTER_H / 2 + 13, Color(110, 110, 110), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end

	rebuild()

	-- Key / mouse input hook (while menu is open)
	local hookName = "ixCalloutMenu_Input"

	hook.Add("PlayerButtonDown", hookName, function(ply, btn)
		if (!IsValid(panel)) then
			hook.Remove("PlayerButtonDown", hookName)
			return
		end

		-- Close on menu key press again or ESC
		local menuKey = PLUGIN:GetCalloutMenuBindCode()
		if (btn == menuKey or btn == KEY_ESCAPE) then
			closeMenu()
			hook.Remove("PlayerButtonDown", hookName)
			return
		end

		-- Page navigation via mouse side buttons
		if (btn == MOUSE_4) then
			page = math.max(1, page - 1)
			rebuild()
			return
		end

		if (btn == MOUSE_5) then
			page = math.min(totalPages, page + 1)
			rebuild()
			return
		end

		-- Number key selection
		local choice = NUM_KEYS[btn]
		if (!choice) then return end

		local pageItems = getPageCategories()
		local item = pageItems[choice]
		if (!item) then return end

		-- Send to server
		net.Start("ixcallout_manual_voice")
			net.WriteUInt(item.index, 8)
		net.SendToServer()

		closeMenu()
		hook.Remove("PlayerButtonDown", hookName)
	end)

	-- Also clean up if panel gets externally removed
	panel.OnRemove = function()
		hook.Remove("PlayerButtonDown", hookName)
		if (activeMenu == panel) then
			activeMenu = nil
		end
	end
end

-- Returns the shared category list if the local player is in a supported faction.
local function getLocalCategories()
	local client = LocalPlayer()
	if (!IsValid(client) or !client:GetCharacter()) then return nil end

	for _, data in pairs(PLUGIN.voiceTypes or {}) do
		if (data.factions and data.factions[client:Team()]) then
			return PLUGIN.MANUAL_CATEGORIES
		end
	end

	return nil
end

-- Main key-press handler to open the menu
hook.Add("PlayerButtonDown", "ixCalloutMenu_OpenKey", function(ply, btn)
	if (btn != PLUGIN:GetCalloutMenuBindCode()) then return end
	if (btn == KEY_NONE) then return end

	-- Don't open if typing or a UI is focused
	if (vgui.IsGameUIVisible() or IsValid(gui.GetActiveInput and gui.GetActiveInput())) then return end

	if (IsValid(activeMenu)) then
		closeMenu()
		return
	end

	local cats = getLocalCategories()
	if (!cats or #cats == 0) then return end

	openMenu(cats)
end)
