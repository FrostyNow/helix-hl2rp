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

	local contentWidth = 720
	local modelPanelWidth = 300
	local width = contentWidth + modelPanelWidth
	local height = 600

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
		surface.DrawRect(0, 0, contentWidth, 32)

		draw.SimpleText(L("actMenuDesc"):upper(), "ixMenuButtonFontSmall", 16, 16, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	-- Model preview panel (right side)
	local modelContainer = ix.gui.actMenu:Add("DPanel")
	modelContainer:SetWide(modelPanelWidth)
	modelContainer:Dock(RIGHT)
	modelContainer.Paint = function(_, w, h)
		surface.SetDrawColor(ix.config.Get("color", color_white))
		surface.DrawLine(0, 0, 0, h)
	end

	local actModel = modelContainer:Add("ixModelPanel")
	actModel:Dock(FILL)
	actModel:DockMargin(4, 36, 4, 4)
	actModel:SetFOV(30)

	actModel.currentAngles = Angle(0, -15, 0)
	actModel.isDragging = false
	actModel.lastMouseX = 0
	actModel.actSequenceID = -1

	actModel.LayoutEntity = function(this, entity)
		if (this.actSequenceID and this.actSequenceID >= 0) then
			if (entity:GetSequence() != this.actSequenceID) then
				entity:SetSequence(this.actSequenceID)
				entity:SetCycle(0)
			end
			entity:FrameAdvance(FrameTime())
		else
			this:RunAnimation()
		end

		local head = entity:LookupBone("ValveBiped.Bip01_Head1")
		if (head) then
			local pos = entity:GetBonePosition(head)
			entity:SetEyeTarget(pos + entity:GetForward() * 32)
		end

		entity:SetAngles(this.currentAngles)
	end

	actModel.Paint = function(this, w, h)
		if (!IsValid(this.Entity)) then return end

		local x, y = this:LocalToScreen(0, 0)

		this:LayoutEntity(this.Entity)

		cam.Start3D(this.vCamPos, (this.vLookatPos - this.vCamPos):Angle(), this.fFOV, x, y, w, h)
			render.SuppressEngineLighting(true)
			render.SetLightingOrigin(this.Entity:GetPos())
			render.SetModelLighting(0, 1.5, 1.5, 1.5)
			for i = 1, 4 do render.SetModelLighting(i, 0.4, 0.4, 0.4) end
			render.SetModelLighting(5, 0.04, 0.04, 0.04)
			this.Entity:DrawModel()
			render.SuppressEngineLighting(false)
		cam.End3D()
	end

	actModel.OnMousePressed = function(this, code)
		if (code == MOUSE_LEFT) then
			this.isDragging = true
			this.lastMouseX = gui.MouseX()
			this:SetCursor("sizewe")
		end
	end

	actModel.OnMouseReleased = function(this, code)
		if (code == MOUSE_LEFT) then
			this.isDragging = false
			this:SetCursor("none")
		end
	end

	actModel.OnCursorMoved = function(this, x, y)
		if (this.isDragging) then
			local mouseX = gui.MouseX()
			local delta = mouseX - this.lastMouseX
			this.lastMouseX = mouseX
			this.currentAngles.y = (this.currentAngles.y + delta * 0.5) % 360
		end
	end

	actModel.OnCursorExited = function(this)
		this.isDragging = false
		this:SetCursor("none")
	end

	-- Initialize model from local player
	local function SetupActModel()
		if (!IsValid(actModel)) then return end

		local model = client:GetModel()
		local skin = client:GetSkin()

		actModel:SetModel(model, skin)

		if (IsValid(actModel.Entity)) then
			for i = 0, client:GetNumBodyGroups() - 1 do
				actModel.Entity:SetBodygroup(i, client:GetBodygroup(i))
			end

			local min, max = actModel.Entity:GetRenderBounds()
			local height2 = max.z - min.z
			local sz = math.max(height2, max.x - min.x, max.y - min.y)
			local fov = actModel:GetFOV()
			local dist = (sz * 0.3) / math.tan(math.rad(fov * 0.55))
			local center = (min + max) * 0.65

			actModel:SetCamPos(Vector(dist, 0, center.z + height2 * 0.1))
			actModel:SetLookAt(Vector(center.x, center.y, actModel.vCamPos.z - dist * math.tan(math.rad(10))))
		end
	end

	SetupActModel()

	-- Left content area
	local contentPanel = ix.gui.actMenu:Add("EditablePanel")
	contentPanel:Dock(FILL)
	contentPanel:DockMargin(1, 1, 0, 1)
	contentPanel.Paint = nil

	-- Search Bar
	local search = contentPanel:Add("ixIconTextEntry")
	search:Dock(TOP)
	search:DockMargin(8, 36, 8, 6)
	search:SetTall(32)
	search:SetFont("ixMenuButtonFontSmall")
	if (search.SetPlaceholderText) then
		search:SetPlaceholderText(L("search").."...")
	end

	local scroll = contentPanel:Add("DScrollPanel")
	scroll:Dock(FILL)
	scroll:DockMargin(8, 0, 8, 8)

	local layout = scroll:Add("DIconLayout")
	layout:Dock(TOP)
	layout:SetSpaceX(4)
	layout:SetSpaceY(4)

	local function PreviewAct(actData, variantIndex)
		if (!IsValid(actModel) or !IsValid(actModel.Entity)) then return end

		local sequence = actData.sequence[variantIndex]
		if (istable(sequence)) then
			sequence = sequence[1] or sequence.sequence
		end

		if (isstring(sequence)) then
			local seqID = actModel.Entity:LookupSequence(sequence)
			actModel.actSequenceID = (seqID >= 0) and seqID or -1
		else
			actModel.actSequenceID = -1
		end
	end

	local function ClearPreview()
		if (IsValid(actModel)) then
			actModel.actSequenceID = -1
		end
	end

	scroll.OnCursorExited = function()
		ClearPreview()
	end

	local function RebuildActs(filter)
		layout:Clear()
		filter = (filter or ""):lower()

		local btnW = contentWidth - 16 - 2

		local currentAngle = client:GetNetVar("actEnterAngle")
		if (currentAngle) then
			local btn = layout:Add("DButton")
			btn:SetSize(btnW, 40)
			btn:SetText(L("actExit"):upper())
			btn:SetFont("ixMenuButtonFontSmall")
			btn:SetTextColor(Color(255, 100, 100))
			btn.Paint = function(self, w, h)
				local alpha = 100
				if (self:IsHovered()) then alpha = 180 end
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

				local capturedInfo = actInfo
				local capturedVariant = i

				local btn = layout:Add("DButton")
				btn:SetSize((btnW - 8) / 3, 40)
				btn:SetText(label:upper())
				btn:SetFont("ixMenuButtonFontSmall")
				btn:SetTextColor(color_white)
				btn.Paint = function(self, w, h)
					if (self:IsHovered()) then
						surface.SetDrawColor(ix.config.Get("color", color_white))
						surface.DrawRect(0, 0, w, h)
						self:SetTextColor(color_black)
					else
						surface.SetDrawColor(40, 40, 40, 100)
						surface.DrawRect(0, 0, w, h)
						surface.SetDrawColor(ix.config.Get("color", color_white))
						surface.DrawOutlinedRect(0, 0, w, h)
						self:SetTextColor(color_white)
					end
				end

				btn.DoClick = function()
					ix.command.Send("act" .. capturedInfo.name:lower(), capturedVariant)
					ix.gui.actMenu:Remove()
				end

				btn.OnCursorEntered = function()
					PreviewAct(capturedInfo.data, capturedVariant)
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
	close:SetPos(contentWidth - 32, 0)
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
