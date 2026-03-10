local PLUGIN = PLUGIN

local DEFAULT_ACT_MENU_BIND = "NONE"

local INVALID_BIND_CODES = {
	[KEY_ESCAPE] = true,
	[KEY_TAB] = true
}
local BIND_ALIASES = {
	[""] = "NONE",
	OFF = "NONE",
	DISABLE = "NONE",
	DISABLED = "NONE",
	ESC = "ESCAPE",
	RETURN = "ENTER"
}
local bUpdatingBindOption = false

local function TL(key, fallback, ...)
	local value = L(key, ...)

	if (value == key) then
		return fallback or key
	end

	return value
end

local function resolveBindCode(bindText)
	local normalized = string.upper(string.Trim(tostring(bindText or "")))
	normalized = normalized:gsub("^KEY_", "")
	normalized = normalized:gsub("[%s%-]+", "_")
	normalized = BIND_ALIASES[normalized] or normalized

	if (normalized == "NONE") then
		return KEY_NONE, normalized
	end

	local keyCode = input.GetKeyCode and input.GetKeyCode(normalized) or nil

	if (isnumber(keyCode) and keyCode != KEY_NONE) then
		return keyCode, normalized
	end

	keyCode = _G[normalized]

	if (isnumber(keyCode)) then
		return keyCode, normalized
	end

	keyCode = _G["KEY_" .. normalized]

	if (isnumber(keyCode)) then
		return keyCode, normalized
	end
end

local function normalizeBindText(bindText)
	local keyCode, normalized = resolveBindCode(bindText)

	if (!isnumber(keyCode) or INVALID_BIND_CODES[keyCode]) then
		return nil
	end

	if (keyCode == KEY_NONE) then
		return "NONE", keyCode
	end

	local keyName = input.GetKeyName and input.GetKeyName(keyCode) or normalized

	if (!isstring(keyName) or keyName == "") then
		keyName = normalized
	end

	return string.upper(keyName), keyCode
end

local function applyActMenuBind(bindText, bNotify)
	local normalized, keyCode = normalizeBindText(bindText)

	if (!normalized) then
		if (bNotify and IsValid(LocalPlayer())) then
			LocalPlayer():Notify(TL("actMenuBindInvalid", "Invalid act menu bind. Use values like N, F6, KP_ENTER, or NONE."))
		end

		return false
	end

	if (ix.option.Get("actMenuBind", DEFAULT_ACT_MENU_BIND) != normalized) then
		bUpdatingBindOption = true
		ix.option.Set("actMenuBind", normalized)
		bUpdatingBindOption = false
	end

	if (bNotify and IsValid(LocalPlayer())) then
		if (keyCode == KEY_NONE) then
			LocalPlayer():Notify(TL("actMenuBindDisabled", "Act menu bind disabled."))
		else
			LocalPlayer():Notify(TL("actMenuBindUpdated", "Act menu bind set to %s.", normalized))
		end
	end

	return true, keyCode, normalized
end

local function getActMenuBindName()
	local normalized = normalizeBindText(ix.option.Get("actMenuBind", DEFAULT_ACT_MENU_BIND))

	return normalized or DEFAULT_ACT_MENU_BIND
end

local function getActMenuBindCode()
	local _, keyCode = normalizeBindText(ix.option.Get("actMenuBind", DEFAULT_ACT_MENU_BIND))

	if (isnumber(keyCode)) then
		return keyCode
	end

	return KEY_NONE
end

ix.option.Add("actMenuBind", ix.type.string, DEFAULT_ACT_MENU_BIND, {
	category = "general",
	OnChanged = function(_, value)
		if (bUpdatingBindOption) then
			return
		end

		local normalized = normalizeBindText(value)
		local nextValue = normalized or DEFAULT_ACT_MENU_BIND

		if (nextValue != value) then
			bUpdatingBindOption = true
			ix.option.Set("actMenuBind", nextValue)
			bUpdatingBindOption = false
		end
	end
})

function PLUGIN:OpenActMenu()
	if (IsValid(ix.gui.actMenu)) then
		ix.gui.actMenu:Remove()
	end

	local client = LocalPlayer()
	local modelClass = ix.anim.GetModelClass(client:GetModel())
	local availableActs = {}

	-- Get all acts available for the current model class
	for name, classes in pairs(ix.act.stored) do
		if (classes[modelClass]) then
			local data = classes[modelClass]
			local variants = #data.sequence
			
			table.insert(availableActs, {
				name = name,
				variants = variants,
				data = data
			})
		end
	end

	if (#availableActs == 0) then
		client:NotifyLocalized("modelNoSeq")
		return
	end

	table.SortByMember(availableActs, "name", true)

	local width, height = 720, 600
	ix.gui.actMenu = vgui.Create("EditablePanel")
	ix.gui.actMenu:SetSize(width, height)
	ix.gui.actMenu:Center()
	ix.gui.actMenu:MakePopup()
	ix.gui.actMenu.Paint = function(self, w, h)
		Derma_DrawBackgroundBlur(self, self.m_fCreateTime)
		
		surface.SetDrawColor(0, 0, 0, 220)
		surface.DrawRect(0, 0, w, h)
		
		surface.SetDrawColor(ix.config.Get("color", color_white))
		surface.DrawOutlinedRect(0, 0, w, h)
		
		surface.SetDrawColor(ix.config.Get("color", color_white))
		surface.DrawRect(0, 0, w, 32)
		
		draw.SimpleText(L("actMenuDesc"):upper(), "ixMenuButtonFontSmall", 16, 16, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	-- Search Bar
	local search = ix.gui.actMenu:Add("ixIconTextEntry")
	search:Dock(TOP)
	search:DockMargin(16, 40, 16, 8)
	search:SetTall(32)
	search:SetFont("ixMenuButtonFontSmall")
	if (search.SetPlaceholderText) then
		search:SetPlaceholderText(L("search").."...")
	end

	local scroll = ix.gui.actMenu:Add("DScrollPanel")
	scroll:Dock(FILL)
	scroll:DockMargin(16, 0, 16, 16)

	local layout = scroll:Add("DIconLayout")
	layout:Dock(TOP)
	layout:SetSpaceX(4)
	layout:SetSpaceY(4)

	local function RebuildActs(filter)
		layout:Clear()
		filter = (filter or ""):lower()

		local currentAngle = client:GetNetVar("actEnterAngle")
		if (currentAngle) then
			local btn = layout:Add("DButton")
			btn:SetSize(width - 32 - 16, 40)
			btn:SetText(L("actExit"):upper())
			btn:SetFont("ixMenuButtonFontSmall")
			btn:SetTextColor(Color(255, 100, 100))
			btn.Paint = function(self, w, h)
				local alpha = 100
				if (self:IsHovered()) then
					alpha = 180
				end
				surface.SetDrawColor(80, 20, 20, alpha)
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(255, 100, 100)
				surface.DrawOutlinedRect(0, 0, w, h)
			end
			btn.DoClick = function()
				ix.command.Send("ExitAct")
				ix.gui.actMenu:Remove()
			end
		end

		for _, actInfo in ipairs(availableActs) do
			if (filter != "" and !actInfo.name:lower():find(filter, 1, true)) then
				continue
			end

			local variants = actInfo.variants
			for i = 1, variants do
				local label = actInfo.name
				if (variants > 1) then
					label = label .. " (" .. i .. ")"
				end

				local btn = layout:Add("DButton")
				btn:SetSize((width - 32 - 16 - 8) / 3, 40)
				btn:SetText(label:upper())
				btn:SetFont("ixMenuButtonFontSmall")
				btn:SetTextColor(color_white)
				btn.Paint = function(self, w, h)
					local alpha = 100
					if (self:IsHovered()) then
						alpha = 200
						surface.SetDrawColor(ix.config.Get("color", color_white))
					else
						surface.SetDrawColor(40, 40, 40, alpha)
					end
					
					surface.DrawRect(0, 0, w, h)
					
					if (self:IsHovered()) then
						self:SetTextColor(color_black)
					else
						self:SetTextColor(color_white)
						surface.SetDrawColor(ix.config.Get("color", color_white))
						surface.DrawOutlinedRect(0, 0, w, h)
					end
				end

				btn.DoClick = function()
					ix.command.Send("act" .. actInfo.name:lower(), i)
					ix.gui.actMenu:Remove()
				end
			end
		end
	end

	search.OnValueChange = function(this, value)
		RebuildActs(value)
	end

	RebuildActs("")

	-- Close button
	local close = ix.gui.actMenu:Add("DButton")
	close:SetSize(32, 32)
	close:SetPos(width - 32, 0)
	close:SetText("✕")
	close:SetFont("ixMenuButtonFontSmall")
	close:SetTextColor(color_black)
	close.Paint = nil
	close.DoClick = function()
		ix.gui.actMenu:Remove()
	end
	
	ix.gui.actMenu:SetAlpha(0)
	ix.gui.actMenu:AlphaTo(255, 0.2)
end

concommand.Add("ix_actmenu", function()
	PLUGIN:OpenActMenu()
end)

concommand.Add("+actmenu", function()
	PLUGIN:OpenActMenu()
end)

concommand.Add("-actmenu", function()
	if (IsValid(ix.gui.actMenu)) then
		ix.gui.actMenu:Remove()
	end
end)

concommand.Add("ix_actmenu_bind", function(_, _, arguments)
	local bindText = string.Trim(table.concat(arguments or {}, " "))

	if (bindText == "") then
		LocalPlayer():Notify(TL("actMenuBindCurrent", "Current act menu bind: %s.", getActMenuBindName()))
		return
	end

	applyActMenuBind(bindText, true)
end)

function PLUGIN:PlayerButtonDown(client, button)
	local curTime = CurTime()
	local bindCode = getActMenuBindCode()

	if (bindCode != KEY_NONE and button == bindCode) then
		if (IsValid(ix.gui.actMenu)) then
			return
		end

		if ((client.nextActMenuBindOpen or 0) > curTime) then
			return
		end

		self:OpenActMenu()
		client.nextActMenuBindOpen = curTime + 0.2
		return
	end
end
