local PLUGIN = PLUGIN

local font = ix.config.Get("font", "Roboto")

surface.CreateFont("ixScannerFont", {
	font = font,
	antialias = false,
	outline = true,
	weight = 800,
	extended = true,
	size = 18
})

local PICTURE_WIDTH = PLUGIN.PICTURE_WIDTH
local PICTURE_HEIGHT = PLUGIN.PICTURE_HEIGHT
local PICTURE_WIDTH2 = PICTURE_WIDTH * 0.5
local PICTURE_HEIGHT2 = PICTURE_HEIGHT * 0.5

PHOTO_CACHE = PHOTO_CACHE or {}
local SURVEILLANCE_WIDTH = 768
local SURVEILLANCE_HEIGHT = 576
local SURVEILLANCE_WIDTH2, SURVEILLANCE_HEIGHT2 = SURVEILLANCE_WIDTH * 0.5, SURVEILLANCE_HEIGHT * 0.5

function PLUGIN:takePicture()
	if ((self.lastPic or 0) < CurTime()) then
		self.lastPic = CurTime() + 15

		net.Start("ixScannerPicture")
		net.SendToServer()

		timer.Simple(0.1, function()
			self.startPicture = true
		end)
	end
end

local function GetAreaAtPos(pos)
	if (!ix.area or !ix.area.stored) then return "OUTSIDE" end

	for id, area in pairs(ix.area.stored) do
		if (pos:WithinAABox(area.startPosition, area.endPosition)) then
			return area.properties.name != "" and area.properties.name or id
		end
	end

	return "OUTSIDE"
end

local surveillanceRT = GetRenderTarget("ixSurveillanceRT" .. SURVEILLANCE_WIDTH .. "_" .. SURVEILLANCE_HEIGHT, SURVEILLANCE_WIDTH, SURVEILLANCE_HEIGHT)



ix.lang.AddTable("english", {
	SurveillanceCapture = "SURVEILLANCE CAPTURE",
	ScannerCapture = "SCANNER CAPTURE",
})

ix.lang.AddTable("korean", {
	SurveillanceCapture = "감시 카메라 촬영",
	ScannerCapture = "스캐너 촬영",
})

local function DrawCombineOverlay(w, h)
	surface.SetDrawColor(255, 255, 255, 100)
	local len = 80
	-- Brackets
	surface.DrawLine(0, 0, len, 0)
	surface.DrawLine(0, 0, 0, len)
	surface.DrawLine(w - 1, 0, w - len, 0)
	surface.DrawLine(w - 1, 0, w - 1, len)
	surface.DrawLine(0, h - 1, len, h - 1)
	surface.DrawLine(0, h - 1, 0, h - len)
	surface.DrawLine(w - 1, h - 1, w - len, h - 1)
	surface.DrawLine(w - 1, h - 1, w - 1, h - len)

	-- Center cross
	surface.SetDrawColor(255, 255, 255, 40)
	surface.DrawLine(w * 0.5 - 10, h * 0.5, w * 0.5 + 10, h * 0.5)
	surface.DrawLine(w * 0.5, h * 0.5 - 10, w * 0.5, h * 0.5 + 10)

	-- Scanlines
	surface.SetDrawColor(0, 0, 0, 50)
	for i = 0, h, 4 do
		surface.DrawRect(0, i, w, 1)
	end

	-- Red Tint
	surface.SetDrawColor(255, 0, 0, 15)
	surface.DrawRect(0, 0, w, h)
end

function PLUGIN:PostRender()
	if (self.surveillanceRequest) then
		local camera = self.surveillanceRequest
		self.surveillanceRequest = nil

		local boneIndex = camera:LookupBone("Combine_Camera.bone1")
		local bonePos, boneAngles
		if (boneIndex and boneIndex != -1) then
			bonePos, boneAngles = camera:GetBonePosition(boneIndex)
		end

		if (not bonePos) then
			bonePos = camera:GetPos()
			boneAngles = camera:GetAngles()
		else
			boneAngles.roll = boneAngles.roll + 90
		end

		local lensIndex = camera:LookupBone("Combine_Camera.Lens")
		local camPos
		if (lensIndex and lensIndex != -1) then
			camPos = camera:GetBonePosition(lensIndex)
		end
		if (not camPos) then
			camPos = bonePos + boneAngles:Forward() * 25
		else
			camPos = camPos + boneAngles:Forward() * 10
		end

		if (bonePos) then
			render.PushRenderTarget(surveillanceRT)
			render.SetViewPort(0, 0, SURVEILLANCE_WIDTH, SURVEILLANCE_HEIGHT)
			render.Clear(0, 0, 0, 255)
			render.RenderView({
				origin = camPos,
				angles = boneAngles,
				fov = 90,
				aspect = SURVEILLANCE_WIDTH / SURVEILLANCE_HEIGHT,
				x = 0,
				y = 0,
				w = SURVEILLANCE_WIDTH,
				h = SURVEILLANCE_HEIGHT,
				drawviewmodel = false
			})

			cam.Start2D()
				DrawCombineOverlay(SURVEILLANCE_WIDTH, SURVEILLANCE_HEIGHT)
			cam.End2D()

			local captured = render.Capture({
				format = "jpeg",
				h = SURVEILLANCE_HEIGHT,
				w = SURVEILLANCE_WIDTH,
				quality = 65,
				x = 0,
				y = 0
			})
			render.PopRenderTarget()

			if (not captured) then 
				return 
			end

			local data = util.Compress(captured)
			if (#data > 65000) then
				-- ErrorNoHalt("[Scanner] Surveillance photo too large to send ("..#data.." bytes)!\n")
				return
			end

			local trace = util.TraceLine({
				start = camPos,
				endpos = camPos + (boneAngles:Forward() * 10000),
				filter = camera
			})
			local target = NULL
			if (trace.Hit) then
				target = trace.Entity
			end

			local zone = GetAreaAtPos(camPos)

			net.Start("ixScannerData")
				net.WriteBool(true) -- Surveillance
				net.WriteUInt(#data, 16)
				net.WriteData(data, #data)
				net.WriteVector(camPos)
				net.WriteAngle(boneAngles)
				net.WriteString("CAM-" .. camera:EntIndex())
				net.WriteEntity(target)
				net.WriteString(zone)
			net.SendToServer()
		end
	end

	if (self.startPicture) then
		local captured = render.Capture({
			format = "jpeg",
			h = PICTURE_HEIGHT,
			w = PICTURE_WIDTH,
			quality = 75,
			x = ScrW() * 0.5 - PICTURE_WIDTH * 0.5,
			y = ScrH() * 0.5 - PICTURE_HEIGHT * 0.5
		})

		if (not captured) then 
			self.startPicture = false
			return 
		end
		local data = util.Compress(captured)

		local scanner = LocalPlayer():GetNetVar("ixScn")
		local pos = IsValid(scanner) and scanner:GetPos() or LocalPlayer():GetPos()
		local ang = IsValid(scanner) and scanner:GetAngles() or LocalPlayer():EyeAngles()
		local id = IsValid(scanner) and scanner:GetNetVar("ixScannerName", "SCN-UNKNOWN") or LocalPlayer():Name()
		
		local trace = util.TraceLine({
			start = pos,
			endpos = pos + (ang:Forward() * 10000),
			filter = {scanner, LocalPlayer()}
		})
		local target = "NONE"

		if (trace.Hit) then
			if (IsValid(trace.Entity)) then
				if (trace.Entity:IsPlayer()) then
					target = trace.Entity:Name()
				else
					target = trace.Entity:GetClass()
				end
			else
				target = "WORLD"
			end
		end

		local zone = GetAreaAtPos(pos)

		net.Start("ixScannerData")
			net.WriteBool(false) -- Regular
			net.WriteUInt(#data, 16)
			net.WriteData(data, #data)
			net.WriteVector(pos)
			net.WriteAngle(ang)
			net.WriteString(id)
			net.WriteString(target)
			net.WriteString(zone)
		net.SendToServer()
		
		self.startPicture = false
	end
end

net.Receive("ixScannerData", function()
	local isSurveillance = net.ReadBool()
	local data = net.ReadData(net.ReadUInt(16))
	data = util.Base64Encode(util.Decompress(data))

	local pos = net.ReadVector() or vector_origin
	local ang = net.ReadAngle() or angle_zero
	local id = net.ReadString() or "UNKNOWN"
	local trg = net.ReadString() or "NONE"
	local zone = net.ReadString() or "OUTSIDE"

	if (not data) then return end

	ix.util.EmitQueuedSounds(LocalPlayer(), {
		"npc/metropolice/vo/on" .. math.random(1, 2) .. ".wav",
		"npc/overwatch/radiovoice/preparevisualdownload.wav",
		"npc/metropolice/vo/off" .. math.random(1, 4) .. ".wav"
	}, 0, 0.1, 0)

	if (IsValid(CURRENT_PHOTO)) then
		local panel = CURRENT_PHOTO

		CURRENT_PHOTO:AlphaTo(0, 0.25, 0, function()
			if (IsValid(panel)) then
				panel:Remove()
			end
		end)
	end

	local displayWidth, displayHeight = 400, 300

	local html = Format([[
		<html>
			<body style="background: black; overflow: hidden; margin: 0; padding: 0;">
				<img src="data:image/jpeg;base64,%s" style="width: 100%%; height: 100%%; object-fit: contain;" />
			</body>
		</html>
	]], data)

	local panel = vgui.Create("DPanel")
	panel:SetSize(displayWidth + 8, displayHeight + 8)
	panel:SetPos(ScrW(), 8)
	panel:SetDrawBackground(true)
	panel:SetAlpha(150)

	panel.body = panel:Add("DHTML")
	panel.body:Dock(FILL)
	panel.body:DockMargin(4, 4, 4, 4)
	panel.body:SetHTML(html)

	local title = isSurveillance and "SurveillanceCapture" or "ScannerCapture"
	panel:MoveTo(ScrW() - (panel:GetWide() + 8), 8, 0.5)

	if (isSurveillance) then
		local function DrawSurveillanceText()
			if (IsValid(panel)) then
				draw.SimpleText(L(title), "ixScannerFont", panel:GetWide() - 4, 4, color_white, TEXT_ALIGN_RIGHT)
				
				local y = 4 + 18
				if (pos) then
					draw.SimpleText(string.format("POS (%.0f, %.0f, %.0f)", pos[1], pos[2], pos[3]), "ixScannerFont", 8, y, color_white)
				end
				y = y + 16
				if (ang) then
					draw.SimpleText(string.format("ANG (%.0f, %.0f, %.0f)", ang[1], ang[2], ang[3]), "ixScannerFont", 8, y, color_white)
				end
				y = y + 16
				draw.SimpleText("ID  ("..tostring(id)..")", "ixScannerFont", 8, y, color_white)
				y = y + 16
				local displayTarget = isSurveillance and L(trg) or trg
				draw.SimpleText("TRG ("..tostring(displayTarget)..")", "ixScannerFont", 8, y, color_white)
				y = y + 16
				draw.SimpleText("ZONE("..tostring(zone)..")", "ixScannerFont", 8, y, color_white)
			end
		end
		panel.PaintOver = DrawSurveillanceText
	end

	timer.Simple(15, function()
		if (IsValid(panel)) then
			panel:MoveTo(ScrW(), 8, 0.5, 0, -1, function()
				panel:Remove()
			end)
		end
	end)

	PHOTO_CACHE[#PHOTO_CACHE + 1] = {
		data = html, 
		time = os.time(),
		pos = pos,
		ang = ang,
		id = id,
		trg = trg,
		zone = zone,
		isSurveillance = isSurveillance
	}
	if (#PHOTO_CACHE > 50) then
		table.remove(PHOTO_CACHE, 1)
	end
	CURRENT_PHOTO = panel
end)

concommand.Add("ix_scanner_photocache", function()
	local bAllowed = false

	if (LocalPlayer():IsCombine() and Schema:CanPlayerSeeCombineOverlay(LocalPlayer())) then
		bAllowed = true
	else
		for _, v in ipairs(ents.FindByClass("ix_ctocameraterminal")) do
			if (v:GetPos():DistToSqr(LocalPlayer():GetPos()) <= 150 * 150) then
				bAllowed = true
				break
			end
		end
	end

	if (bAllowed) then
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L("Photo Cache"))
		frame:SetSize(480, 360)
		frame:MakePopup()
		frame:Center()

		frame.list = frame:Add("DScrollPanel")
		frame.list:Dock(FILL)
		frame.list:SetDrawBackground(true)

		for k, v in ipairs(PHOTO_CACHE) do
			local button = frame.list:Add("DButton")
			button:SetTall(28)
			button:Dock(TOP)
			button:DockMargin(4, 4, 4, 0)
			button:SetText(os.date("%X - %d/%m/%Y", v.time))
			button.DoClick = function()
				local width, height = 580, 420

				local frame2 = vgui.Create("DFrame")
				frame2:SetSize(width + 8, height + 8)
				frame2:SetTitle(button:GetText())
				frame2:MakePopup()
				frame2:Center()

				frame2.body = frame2:Add("DHTML")
				frame2.body:SetHTML(v.data)
				frame2.body:Dock(FILL)
				frame2.body:DockMargin(4, 4, 4, 4)

					if (v.isSurveillance) then
						local function DrawSurveillanceText(panel)
							if (IsValid(frame2)) then
								local y = 4 + 18
								if (v.pos) then
									draw.SimpleText(string.format("POS (%.0f, %.0f, %.0f)", v.pos[1], v.pos[2], v.pos[3]), "ixScannerFont", 8, y, color_white)
								end
								y = y + 16
								if (v.ang) then
									draw.SimpleText(string.format("ANG (%.0f, %.0f, %.0f)", v.ang[1], v.ang[2], v.ang[3]), "ixScannerFont", 8, y, color_white)
								end
								y = y + 16
								draw.SimpleText("ID  ("..tostring(v.id)..")", "ixScannerFont", 8, y, color_white)
								y = y + 16
								local displayTarget = v.isSurveillance and L(v.trg) or v.trg
								draw.SimpleText("TRG ("..tostring(displayTarget)..")", "ixScannerFont", 8, y, color_white)
								y = y + 16
								draw.SimpleText("ZONE("..tostring(v.zone)..")", "ixScannerFont", 8, y, color_white)
							end
						end
						frame2.body.PaintOver = DrawSurveillanceText
					end
			end
		end
	else
		LocalPlayer():NotifyLocalized("cacheCmbOnly")
		return false
	end
end)

net.Receive("ixSurveillancePhotoRequest", function()
	local camera = net.ReadEntity()
	if (!IsValid(camera)) then return end

	local cto = ix.plugin.Get("cto")
	if (cto and cto.terminalsToDraw) then
		for terminal, bDraw in pairs(cto.terminalsToDraw) do
			if (IsValid(terminal) and bDraw and terminal:GetNWEntity("camera") == camera and terminal.tex) then
				render.PushRenderTarget(terminal.tex)
				
				cam.Start2D()
					DrawCombineOverlay(PICTURE_WIDTH, PICTURE_HEIGHT)
				cam.End2D()

				local captured = render.Capture({
					format = "jpeg",
					h = 525,
					w = 700,
					quality = 80,
					x = 0,
					y = 0
				})
				render.PopRenderTarget()

				if (not captured) then return end
				local data = util.Compress(captured)

				if (data) then
					local camPos = camera:GetPos()
					local camAng = camera:GetAngles()
					
					local trace = util.TraceLine({
						start = camPos,
						endpos = camPos + (camAng:Forward() * 10000),
						filter = camera
					})
					local target = NULL
					if (trace.Hit) then
						target = trace.Entity
					end

					local zone = GetAreaAtPos(camPos)

					net.Start("ixScannerData")
						net.WriteBool(true)
						net.WriteUInt(#data, 16)
						net.WriteData(data, #data)
						net.WriteVector(camPos)
						net.WriteAngle(camAng)
						net.WriteString("CAM-" .. camera:EntIndex())
						net.WriteEntity(target)
						net.WriteString(zone)
					net.SendToServer()
					return
				end
			end
		end
	end

	PLUGIN.surveillanceRequest = camera
end)