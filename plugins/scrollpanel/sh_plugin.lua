local PLUGIN = PLUGIN

PLUGIN.name = "Scroll Panel"
PLUGIN.description = "Allows admins to place scrollable text panels on surfaces."
PLUGIN.author = "Frosty"

-- Licensed under CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)

ix.lang.AddTable("english", {
	scrollPanelAddDesc = "Place a scrollable text panel on the surface you're looking at.",
	scrollPanelEditDesc = "Edit the text (and optionally resize) the scroll panel you are looking at.",
	scrollPanelRemoveDesc = "Remove the scroll panel you are looking at.",
	scrollPanelNoSurface = "No surface found.",
	scrollPanelFailedCreate = "Failed to create entity.",
	scrollPanelPlaced = "Scroll panel placed (%ix%i). Use /ScrollPanelEdit to add text.",
	scrollPanelLookToEdit = "Look at a scroll panel to edit it.",
	scrollPanelLookToRemove = "Look at a scroll panel to remove it.",
	scrollPanelRemoved = "Scroll panel removed.",
})

ix.lang.AddTable("korean", {
	scrollPanelAddDesc = "조준한 벽면에 스크롤 텍스트 패널을 배치합니다.",
	scrollPanelEditDesc = "조준한 스크롤 패널의 텍스트 및 크기를 수정합니다.",
	scrollPanelRemoveDesc = "조준한 스크롤 패널을 제거합니다.",
	scrollPanelNoSurface = "배치할 표면을 찾을 수 없습니다.",
	scrollPanelFailedCreate = "엔티티 생성에 실패했습니다.",
	scrollPanelPlaced = "스크롤 패널이 배치되었습니다 (%ix%i). /ScrollPanelEdit 으로 텍스트를 추가하세요.",
	scrollPanelLookToEdit = "수정할 스크롤 패널을 조준하세요.",
	scrollPanelLookToRemove = "제거할 스크롤 패널을 조준하세요.",
	scrollPanelRemoved = "스크롤 패널이 제거되었습니다.",
})

local PANEL_SCALE = 0.1
local PANEL_MAX_DIST = 512
local PANEL_MIN_W = 400
local PANEL_MIN_H = 300
local PANEL_SCROLL_STEP = 60
local PANEL_VISIBLE_PADDING = 20
local PANEL_MIN_FONT_SIZE = 16
local PANEL_DEFAULT_FONT_SIZE = 24
local PANEL_MAX_FONT_SIZE = 72
local PANEL_LINE_PADDING = 4

ixScrollPanelAimed = ixScrollPanelAimed or nil
ixScrollPanelOffsets = ixScrollPanelOffsets or {}

local function ClampFontSize(fontSize)
	return math.Clamp(math.floor(tonumber(fontSize) or PANEL_DEFAULT_FONT_SIZE), PANEL_MIN_FONT_SIZE, PANEL_MAX_FONT_SIZE)
end

-- Robust aim detection
local function FindAimedPanel(client)
	if not IsValid(client) then return nil end

	local trace = client:GetEyeTraceNoCursor()
	if IsValid(trace.Entity) and trace.Entity:GetClass() == "ix_scrollpanel" then
		return trace.Entity
	end

	local eyePos = client:EyePos()
	local eyeDir = client:GetAimVector()
	local best, bestDist = nil, PANEL_MAX_DIST

	for _, ent in ipairs(ents.FindByClass("ix_scrollpanel")) do
		if not IsValid(ent) then continue end

		local dist = ent:GetPos():Distance(eyePos)
		if dist > PANEL_MAX_DIST then continue end

		local normal = ent:GetUp()
		local dot = eyeDir:Dot(normal)
		if math.abs(dot) < 0.01 then continue end

		local t = (ent:GetPos() - eyePos):Dot(normal) / dot
		if t < 0 or t > PANEL_MAX_DIST then continue end

		local hitPos = eyePos + eyeDir * t
		local blockTrace = util.TraceLine({
			start = eyePos,
			endpos = hitPos,
			filter = client
		})

		if blockTrace.Hit and blockTrace.Entity ~= ent then continue end

		local localHit = ent:WorldToLocal(hitPos)
		local hw = ent:GetNetVar("panelW", PANEL_MIN_W) * PANEL_SCALE / 2
		local hh = ent:GetNetVar("panelH", PANEL_MIN_H) * PANEL_SCALE / 2

		if math.abs(localHit.x) <= hw and math.abs(localHit.y) <= hh and t < bestDist then
			best = ent
			bestDist = t
		end
	end

	return best
end

local function GetInteractivePanel(client)
	if CLIENT and client == LocalPlayer() and IsValid(ixScrollPanelAimed) then
		return ixScrollPanelAimed
	end

	return FindAimedPanel(client)
end

local function IsBlockedWeaponBind(bind)
	bind = string.lower(bind)

	return bind:find("invnext", 1, true)
		or bind:find("invprev", 1, true)
		or bind:find("slot", 1, true)
		or bind:find("lastinv", 1, true)
end

if SERVER then
	local function SpawnSavedScrollPanel(data)
		if not istable(data) then return end

		local entity = ents.Create("ix_scrollpanel")
		if not IsValid(entity) then return end

		entity:SetPos(data.pos)
		entity:SetAngles(data.angles)
		entity:Spawn()
		entity:Activate()
		entity:SetNetVar("text", data.text or "")
		entity:SetNetVar("panelW", math.Clamp(tonumber(data.panelW) or PANEL_MIN_W, PANEL_MIN_W, 2048))
		entity:SetNetVar("panelH", math.Clamp(tonumber(data.panelH) or PANEL_MIN_H, PANEL_MIN_H, 2048))
		entity:SetNetVar("fontSize", ClampFontSize(data.fontSize))
		entity:UpdateBounds()
	end

	function PLUGIN:SaveData()
		local data = {}

		for _, entity in ipairs(ents.FindByClass("ix_scrollpanel")) do
			if not IsValid(entity) then continue end

			data[#data + 1] = {
				pos = entity:GetPos(),
				angles = entity:GetAngles(),
				text = entity:GetNetVar("text", ""),
				panelW = entity:GetNetVar("panelW", PANEL_MIN_W),
				panelH = entity:GetNetVar("panelH", PANEL_MIN_H),
				fontSize = entity:GetNetVar("fontSize", PANEL_DEFAULT_FONT_SIZE)
			}
		end

		self:SetData(data)
	end

	function PLUGIN:LoadData()
		for _, data in ipairs(self:GetData() or {}) do
			SpawnSavedScrollPanel(data)
		end
	end
end

local function ResetWeaponSelect(client)
	if not CLIENT or not IsValid(client) then return end

	local weaponSelect = ix.plugin.Get("wepselect")
	if not weaponSelect then return end

	local weapons = client:GetWeapons()
	local activeWeapon = client:GetActiveWeapon()
	local activeIndex = 1

	for i = 1, #weapons do
		if weapons[i] == activeWeapon then
			activeIndex = i
			break
		end
	end

	weaponSelect.index = activeIndex
	weaponSelect.deltaIndex = activeIndex
	weaponSelect.alpha = 0
	weaponSelect.alphaDelta = 0
	weaponSelect.fadeTime = 0
	weaponSelect.infoAlpha = 0
	weaponSelect.markup = nil
end

if CLIENT then
	PLUGIN.fontCache = PLUGIN.fontCache or {}
	PLUGIN.lineHeightCache = PLUGIN.lineHeightCache or {}

	surface.CreateFont("ixScrollPanelFont", {
		font = ix.config.Get("font", "Roboto"),
		size = PANEL_DEFAULT_FONT_SIZE,
		weight = 500,
		antialias = true,
		extended = true
	})

	PLUGIN.fontCache["ixScrollPanelFont"] = true

	function PLUGIN:GetFontName(fontSize)
		fontSize = ClampFontSize(fontSize)

		local fontName = "ixScrollPanelFont" .. fontSize
		if not self.fontCache[fontName] then
			surface.CreateFont(fontName, {
				font = ix.config.Get("font", "Roboto"),
				size = fontSize,
				weight = 500,
				antialias = true,
				extended = true
			})

			self.fontCache[fontName] = true
		end

		return fontName, fontSize
	end

	function PLUGIN:GetLineHeight(fontSize)
		fontSize = ClampFontSize(fontSize)

		if not self.lineHeightCache[fontSize] then
			local fontName = self:GetFontName(fontSize)
			surface.SetFont(fontName)
			local _, textHeight = surface.GetTextSize("Wg")
			self.lineHeightCache[fontSize] = textHeight + PANEL_LINE_PADDING
		end

		return self.lineHeightCache[fontSize]
	end

	function PLUGIN:GetTextLayout(fontSize)
		fontSize = ClampFontSize(fontSize)

		return self:GetFontName(fontSize), self:GetLineHeight(fontSize), fontSize
	end

	function PLUGIN:WrapText(text, maxW, font)
		surface.SetFont(font)
		local rawLines = string.Explode("\n", text)
		local result = {}

		for _, raw in ipairs(rawLines) do
			if raw == "" then
				result[#result + 1] = ""
				continue
			end

			local words = string.Explode(" ", raw)
			local current = ""
			for _, word in ipairs(words) do
				local test = current == "" and word or (current .. " " .. word)
				local tw = surface.GetTextSize(test)
				if tw > maxW and current ~= "" then
					result[#result + 1] = current
					current = word
				else
					current = test
				end
			end
			if current ~= "" then
				if surface.GetTextSize(current) > maxW then
					local sub = ""
					for i = 1, current:utf8len() do
						local c = current:utf8sub(i, i)
						if surface.GetTextSize(sub .. c) > maxW then
							result[#result + 1] = sub
							sub = c
						else
							sub = sub .. c
						end
					end
					if sub ~= "" then result[#result + 1] = sub end
				else
					result[#result + 1] = current
				end
			end
		end

		return result
	end
end

hook.Add("PlayerBindPress", "ixScrollPanel_BindPress", function(client, bind, pressed)
	if not IsBlockedWeaponBind(bind) then return end

	local ent = GetInteractivePanel(client)
	if IsValid(ent) then
		if CLIENT and client == LocalPlayer() then
			ResetWeaponSelect(client)
		end

		return true
	end
end)

if CLIENT then
	ixScrollPanelLastWheel = 0
	ixScrollPanelLastWheelFrame = -1

	local function GetPanelLineCount(ent)
		local lineCount = (ent.ixLines and #ent.ixLines) or 0
		if lineCount > 0 then
			return lineCount
		end

		local panelW = ent:GetNetVar("panelW", PANEL_MIN_W)
		local fontName = PLUGIN:GetTextLayout(ent:GetNetVar("fontSize", PANEL_DEFAULT_FONT_SIZE))
		local wrapped = PLUGIN:WrapText(ent:GetNetVar("text", ""), panelW - 30, fontName)

		return #wrapped
	end

	local function GetPanelLineHeight(ent)
		return PLUGIN:GetLineHeight(ent:GetNetVar("fontSize", PANEL_DEFAULT_FONT_SIZE))
	end

	local function CapturePanelWheel(cmd)
		local ply = LocalPlayer()
		if not IsValid(ply) then return false end

		local ent = GetInteractivePanel(ply)
		if not IsValid(ent) then return false end

		local wheel = cmd:GetMouseWheel()
		if wheel == 0 then return false end

		local frameNumber = FrameNumber()
		if ixScrollPanelLastWheelFrame == frameNumber then
			ResetWeaponSelect(ply)
			cmd:SetMouseWheel(0)
			return true
		end

		local idx = ent:EntIndex()
		local panelH = ent:GetNetVar("panelH", PANEL_MIN_H)
		local lineCount = GetPanelLineCount(ent)
		local lineHeight = GetPanelLineHeight(ent)
		local maxScroll = math.max(0, lineCount * lineHeight - (panelH - PANEL_VISIBLE_PADDING))
		local delta = -wheel * PANEL_SCROLL_STEP

		ixScrollPanelOffsets[idx] = math.Clamp((ixScrollPanelOffsets[idx] or 0) + delta, 0, maxScroll)
		ixScrollPanelAimed = ent
		ixScrollPanelLastWheelFrame = frameNumber

		ResetWeaponSelect(ply)
		cmd:SetMouseWheel(0)
		return true
	end

	hook.Add("Think", "ixScrollPanel_Think", function()
		local ply = LocalPlayer()
		if not IsValid(ply) or gui.IsGameUIVisible() or vgui.CursorVisible() then
			ixScrollPanelAimed = nil
			return
		end

		ixScrollPanelAimed = FindAimedPanel(ply)

		if IsValid(ixScrollPanelAimed) then
			ResetWeaponSelect(ply)
		end
	end)

	hook.Add("InputMouseApply", "ixScrollPanel_InputMouseApply", function(cmd)
		CapturePanelWheel(cmd)
	end)

	hook.Add("CreateMove", "ixScrollPanel_ScrollCapture", function(cmd)
		CapturePanelWheel(cmd)
	end)

	hook.Add("HUDShouldDraw", "ixScrollPanel_HideWeaponSelection", function(name)
		if name == "CHudWeaponSelection" and IsValid(GetInteractivePanel(LocalPlayer())) then
			return false
		end
	end)

	net.Receive("ixScrollPanelEditOpen", function()
		local ent = net.ReadEntity()
		local curText = net.ReadString()
		local curW = net.ReadUInt(16)
		local curH = net.ReadUInt(16)
		local curFontSize = net.ReadUInt(8)

		local frame = vgui.Create("DFrame")
		frame:SetTitle(L("scrollPanelEditDesc"))
		frame:SetSize(540, 520)
		frame:Center()
		frame:MakePopup()

		local scroll = vgui.Create("DScrollPanel", frame)
		scroll:Dock(FILL)
		scroll:DockMargin(5, 5, 5, 5)

		local topRow = vgui.Create("Panel", scroll)
		topRow:Dock(TOP)
		topRow:SetHeight(30)
		topRow:DockMargin(0, 0, 0, 10)

		local lblW = vgui.Create("DLabel", topRow)
		lblW:SetText("Width:")
		lblW:Dock(LEFT)
		lblW:SetWide(50)

		local numW = vgui.Create("DTextEntry", topRow)
		numW:Dock(LEFT)
		numW:SetWide(70)
		numW:SetValue(tostring(curW))

		local lblH = vgui.Create("DLabel", topRow)
		lblH:SetText("Height:")
		lblH:Dock(LEFT)
		lblH:DockMargin(15, 0, 0, 0)
		lblH:SetWide(50)

		local numH = vgui.Create("DTextEntry", topRow)
		numH:Dock(LEFT)
		numH:SetWide(70)
		numH:SetValue(tostring(curH))

		local lblSize = vgui.Create("DLabel", topRow)
		lblSize:SetText("Font:")
		lblSize:Dock(LEFT)
		lblSize:DockMargin(15, 0, 0, 0)
		lblSize:SetWide(40)

		local numSize = vgui.Create("DTextEntry", topRow)
		numSize:Dock(LEFT)
		numSize:SetWide(60)
		numSize:SetValue(tostring(curFontSize))

		local entry = vgui.Create("DTextEntry", scroll)
		entry:Dock(TOP)
		entry:SetHeight(380)
		entry:SetMultiline(true)
		entry:SetValue(curText)
		entry:SetFont("ixMediumFont")

		local saveBtn = vgui.Create("DButton", frame)
		saveBtn:Dock(BOTTOM)
		saveBtn:SetText("SAVE")
		saveBtn:SetTall(35)
		saveBtn.DoClick = function()
			if not IsValid(ent) then
				frame:Remove()
				return
			end

			local w = math.Clamp(tonumber(numW:GetValue()) or curW, PANEL_MIN_W, 2048)
			local h = math.Clamp(tonumber(numH:GetValue()) or curH, PANEL_MIN_H, 2048)
			local fontSize = ClampFontSize(numSize:GetValue() or curFontSize)
			net.Start("ixScrollPanelEditSubmit")
				net.WriteEntity(ent)
				net.WriteString(entry:GetValue())
				net.WriteUInt(w, 16)
				net.WriteUInt(h, 16)
				net.WriteUInt(fontSize, 8)
			net.SendToServer()
			frame:Remove()
		end
	end)
end

ix.command.Add("ScrollPanelAdd", {
	description = "@scrollPanelAddDesc",
	adminOnly = true,
	arguments = {
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional),
	},
	OnRun = function(self, client, width, height)
		width = math.Clamp(width or PANEL_MIN_W, PANEL_MIN_W, 2048)
		height = math.Clamp(height or PANEL_MIN_H, PANEL_MIN_H, 2048)

		local trace = client:GetEyeTraceNoCursor()
		if not trace.Hit then
			client:NotifyLocalized("scrollPanelNoSurface")
			return
		end

		local ent = ents.Create("ix_scrollpanel")
		if not IsValid(ent) then
			client:NotifyLocalized("scrollPanelFailedCreate")
			return
		end

		local ang = trace.HitNormal:Angle()
		ang:RotateAroundAxis(ang:Up(), 90)
		ang:RotateAroundAxis(ang:Forward(), 90)

		ent:SetPos(trace.HitPos + ang:Up() * 0.5)
		ent:SetAngles(ang)
		ent:Spawn()
		ent:Activate()
		ent:SetNetVar("panelW", width)
		ent:SetNetVar("panelH", height)
		ent:SetNetVar("fontSize", PANEL_DEFAULT_FONT_SIZE)
		ent:UpdateBounds()

		client:NotifyLocalized("scrollPanelPlaced", width, height)

		if SERVER then
			PLUGIN:SaveData()
		end
	end
})

ix.command.Add("ScrollPanelEdit", {
	description = "@scrollPanelEditDesc",
	adminOnly = true,
	OnRun = function(self, client)
		local ent = FindAimedPanel(client)
		if not IsValid(ent) then
			client:NotifyLocalized("scrollPanelLookToEdit")
			return
		end

		net.Start("ixScrollPanelEditOpen")
			net.WriteEntity(ent)
			net.WriteString(ent:GetNetVar("text", ""))
			net.WriteUInt(ent:GetNetVar("panelW", PANEL_MIN_W), 16)
			net.WriteUInt(ent:GetNetVar("panelH", PANEL_MIN_H), 16)
			net.WriteUInt(ent:GetNetVar("fontSize", PANEL_DEFAULT_FONT_SIZE), 8)
		net.Send(client)
	end
})

ix.command.Add("ScrollPanelRemove", {
	description = "@scrollPanelRemoveDesc",
	adminOnly = true,
	OnRun = function(self, client)
		local ent = FindAimedPanel(client)
		if not IsValid(ent) then
			client:NotifyLocalized("scrollPanelLookToRemove")
			return
		end

		ent:Remove()
		client:NotifyLocalized("scrollPanelRemoved")
		PLUGIN:SaveData()
	end
})

if SERVER then
	util.AddNetworkString("ixScrollPanelEditOpen")
	util.AddNetworkString("ixScrollPanelEditSubmit")

	hook.Add("PlayerSwitchWeapon", "ixScrollPanel_NoSwitch", function(ply)
		if GetInteractivePanel(ply) then
			return true
		end
	end)

	net.Receive("ixScrollPanelEditSubmit", function(len, client)
		if not client:IsAdmin() then return end

		local ent = net.ReadEntity()
		local text = net.ReadString()
		local w = math.Clamp(net.ReadUInt(16), PANEL_MIN_W, 2048)
		local h = math.Clamp(net.ReadUInt(16), PANEL_MIN_H, 2048)
		local fontSize = ClampFontSize(net.ReadUInt(8))

		if IsValid(ent) and ent:GetClass() == "ix_scrollpanel" then
			ent:SetNetVar("text", text)
			ent:SetNetVar("panelW", w)
			ent:SetNetVar("panelH", h)
			ent:SetNetVar("fontSize", fontSize)
			ent:UpdateBounds()
			PLUGIN:SaveData()
		end
	end)
end

