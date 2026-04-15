local PLUGIN = PLUGIN

local CATEGORIES_PER_PAGE = 6
local MENU_W = 240
local ENTRY_H = 22
local HEADER_H = 46
local PADDING = 10

local NUM_KEYS = {
	[KEY_1] = 1, [KEY_2] = 2, [KEY_3] = 3,
	[KEY_4] = 4, [KEY_5] = 5, [KEY_6] = 6,
	[KEY_7] = 7, [KEY_8] = 8, [KEY_9] = 9,
	[KEY_PAD_1] = 1, [KEY_PAD_2] = 2, [KEY_PAD_3] = 3,
	[KEY_PAD_4] = 4, [KEY_PAD_5] = 5, [KEY_PAD_6] = 6,
	[KEY_PAD_7] = 7, [KEY_PAD_8] = 8, [KEY_PAD_9] = 9,
}

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

	-- Height: header + N entries + "0. Exit" row + padding
	local menuH = HEADER_H + CATEGORIES_PER_PAGE * ENTRY_H + ENTRY_H + PADDING * 2
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

	local function rebuild()
		local pageItems = getPageCategories()

		panel.Paint = function(self, w, h)
			-- Background
			draw.RoundedBox(0, 0, 0, w, h, Color(12, 12, 12, 220))

			-- Top accent bar
			draw.RoundedBox(0, 0, 0, w, 3, ix.config.Get("color") or Color(160, 50, 50, 255))

			-- Title
			draw.SimpleText(L("calloutMenuTitle"), "DermaDefaultBold", PADDING, 14, Color(230, 230, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			-- Page indicator (only if multi-page)
			if (totalPages > 1) then
				local pageText = L("calloutMenuPage", page, totalPages)
				draw.SimpleText(pageText, "DermaDefault", w - PADDING, 14, Color(130, 130, 130), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			end

			-- Divider
			draw.RoundedBox(0, PADDING, HEADER_H - 6, w - PADDING * 2, 1, Color(50, 50, 50, 255))

			-- Entries
			for i, item in ipairs(pageItems) do
				local entryY = HEADER_H + PADDING + (i - 1) * ENTRY_H
				local label = string.format("%d. %s", i, L(item.data.labelKey))
				draw.SimpleText(label, "DermaDefault", PADDING, entryY, Color(210, 210, 210), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end

			-- Divider above exit
			local exitDivY = HEADER_H + PADDING + CATEGORIES_PER_PAGE * ENTRY_H - 4
			draw.RoundedBox(0, PADDING, exitDivY, w - PADDING * 2, 1, Color(50, 50, 50, 255))

			-- "0. Exit"
			local exitY = HEADER_H + PADDING + CATEGORIES_PER_PAGE * ENTRY_H + 2
			draw.SimpleText("0. " .. L("calloutMenuExit"), "DermaDefault", PADDING, exitY, ix.config.Get("color") or Color(160, 80, 80), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
	end

	rebuild()

	local hookName = "ixCalloutMenu_Input"

	hook.Add("PlayerButtonDown", hookName, function(ply, btn)
		if (!IsValid(panel)) then
			hook.Remove("PlayerButtonDown", hookName)
			return
		end

		-- Close on 0 (regular or numpad)
		if (btn == KEY_0 or btn == KEY_PAD_0) then
			closeMenu()
			hook.Remove("PlayerButtonDown", hookName)
			return
		end

		-- Page navigation via mouse side buttons or arrow keys
		if (btn == MOUSE_4 or btn == KEY_LEFT) then
			page = math.max(1, page - 1)
			rebuild()
			return
		end

		if (btn == MOUSE_5 or btn == KEY_RIGHT) then
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

		net.Start("ixcallout_manual_voice")
			net.WriteUInt(item.index, 8)
		net.SendToServer()

		closeMenu()
		hook.Remove("PlayerButtonDown", hookName)
	end)

	panel.OnRemove = function()
		hook.Remove("PlayerButtonDown", hookName)
		if (activeMenu == panel) then
			activeMenu = nil
		end
	end
end

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

hook.Add("PlayerButtonDown", "ixCalloutMenu_OpenKey", function(ply, btn)
	if (btn != PLUGIN:GetCalloutMenuBindCode()) then return end
	if (btn == KEY_NONE) then return end

	-- Don't open if typing or a UI is focused
	if (gui.IsGameUIVisible() or IsValid(gui.GetActiveInput and gui.GetActiveInput())) then return end

	-- Already open: ignore (close with 0)
	if (IsValid(activeMenu)) then return end

	local cats = getLocalCategories()
	if (!cats or #cats == 0) then return end

	openMenu(cats)
end)
