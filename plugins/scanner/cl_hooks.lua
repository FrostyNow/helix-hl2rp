local PLUGIN = PLUGIN

local PICTURE_WIDTH = PLUGIN.PICTURE_WIDTH
local PICTURE_HEIGHT = PLUGIN.PICTURE_HEIGHT
local PICTURE_WIDTH2 = PICTURE_WIDTH * 0.5
local PICTURE_HEIGHT2 = PICTURE_HEIGHT * 0.5



local view = {}
local zoom = 2
local deltaZoom = zoom
local nextClick = 0
local hidden = false
local data = {}

local function ResetWeaponSelect(client)
	if not IsValid(client) then return end

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

local function IsBlockedWeaponBind(bind)
	bind = string.lower(bind)

	return bind:find("invnext", 1, true)
		or bind:find("invprev", 1, true)
		or bind:find("slot", 1, true)
		or bind:find("lastinv", 1, true)
end

local CLICK = "buttons/lightswitch2.wav"

local blackAndWhite = {
	["$pp_colour_addr"] = 0, 
	["$pp_colour_addg"] = 0, 
	["$pp_colour_addb"] = 0, 
	["$pp_colour_brightness"] = 0, 
	["$pp_colour_contrast"] = 1.5, 
	["$pp_colour_colour"] = 0, 
	["$pp_colour_mulr"] = 4, 
	["$pp_colour_mulg"] = 0, 
	["$pp_colour_mulb"] = 0
}

function PLUGIN:CalcView(ply, origin, angles, fov)
	if not ix then return end

	if (IsValid(ix.gui.menu) or IsValid(ix.gui.characterMenu)) then return false end
	if (LocalPlayer():GetNetVar("curCamera", false) or LocalPlayer():GetNetVar("curVisor", false)) then return end

	local scanner = ply:GetNetVar("ixScn")

	if (IsValid(scanner)) then
		if (ply:GetViewEntity() != scanner) then
			local aimAngles = ply:GetAimVector():Angle()
			local targetPos = scanner:GetPos() - aimAngles:Forward() * 100 + aimAngles:Up() * 5
			local tr = util.TraceLine({
				start = scanner:GetPos(),
				endpos = targetPos,
				filter = {scanner, ply}
			})

			view.origin = tr.HitPos + tr.HitNormal * 5
			view.angles = aimAngles
			view.fov = fov

			return view
		elseif not (input.IsKeyDown(KEY_C)) then
			view.origin = scanner:GetPos()
			view.angles = ply:GetAimVector():Angle()

			if (hidden) then
				view.fov = fov - deltaZoom

				if (math.abs(deltaZoom - zoom) > 5 and nextClick < RealTime()) then
					nextClick = RealTime() + 0.05
					ply:EmitSound("common/talk.wav", 50, 180)
				end
			else
				view.fov = fov
			end

			return view
		end
	end
end

function PLUGIN:InputMouseApply(command, x, y, angle)
	if (hidden) then
		local wheel = command:GetMouseWheel()
		if (wheel ~= 0) then
			zoom = math.Clamp(zoom + wheel * 1.5, 0, 40)
			deltaZoom = Lerp(FrameTime() * 2, deltaZoom, zoom)

			ResetWeaponSelect(LocalPlayer())
		end
	end
end

function PLUGIN:PreDrawOpaqueRenderables()
	local client = LocalPlayer()
	local viewEntity = client:GetViewEntity()

	if (IsValid(self.lastViewEntity) and self.lastViewEntity != viewEntity) then
		self.lastViewEntity:SetNoDraw(false)
		self.lastViewEntity = nil
		client:EmitSound(CLICK, 50, 120)
	end

	local scanner = client:GetNetVar("ixScn")

	if (IsValid(scanner) and IsValid(viewEntity) and viewEntity == scanner) then
		viewEntity:SetNoDraw(true)

		if (self.lastViewEntity ~= viewEntity) then
			viewEntity:EmitSound(CLICK, 50, 140)
		end

		self.lastViewEntity = viewEntity

		hidden = true
	elseif (hidden) then
		hidden = false
	end
end

function PLUGIN:Think()
	local client = LocalPlayer()

	if (IsValid(client:GetNetVar("ixScn"))) then
		ResetWeaponSelect(client)
	end
end

function PLUGIN:HUDShouldDraw(name)
	if (name == "CHudWeaponSelection" and IsValid(LocalPlayer():GetNetVar("ixScn"))) then
		return false
	end
end

function PLUGIN:ShouldDrawCrosshair()
	if (hidden) then
		return false
	end
end

function PLUGIN:AdjustMouseSensitivity()
	if (hidden) then
		return 0.8
	end
end

function PLUGIN:HUDPaint()
	if (not hidden) then return end

	local scrW, scrH = surface.ScreenWidth() * 0.5, surface.ScreenHeight() * 0.5
	local x, y = scrW - PICTURE_WIDTH2, scrH - PICTURE_HEIGHT2

	if (self.lastPic and self.lastPic >= CurTime()) then
		local delay = 15
		local percent = math.Round(math.TimeFraction(self.lastPic - delay, self.lastPic, CurTime()), 2) * 100
		local glow = math.sin(RealTime() * 15) * 25

		draw.SimpleText("RE-CHARGING: "..percent.."%", "ixScannerFont", x, y - 24, Color(255 + glow, 100 + glow, 25, 250))
	end

	local scanner = LocalPlayer():GetNetVar("ixScn")
	local position = IsValid(scanner) and scanner:GetPos() or LocalPlayer():GetPos()
	local angle = IsValid(scanner) and scanner:GetAngles() or LocalPlayer():GetAimVector():Angle()
	local scannerName = IsValid(scanner) and scanner:GetNetVar("ixScannerName", L("scannerName")) or LocalPlayer():Name()
	local zone = LocalPlayer():GetAreaName() != "" and LocalPlayer():GetAreaName() or "unknown"

	draw.SimpleText("POS ("..math.floor(position[1])..", "..math.floor(position[2])..", "..math.floor(position[3])..")", "ixScannerFont", x + 8, y + 8, color_white)
	draw.SimpleText("ANG ("..math.floor(angle[1])..", "..math.floor(angle[2])..", "..math.floor(angle[3])..")", "ixScannerFont", x + 8, y + 24, color_white)
	draw.SimpleText("ID  ("..scannerName..")", "ixScannerFont", x + 8, y + 40, color_white)
	draw.SimpleText("ZM  ("..(math.Round(zoom / 40, 2) * 100).."%)", "ixScannerFont", x + 8, y + 56, color_white)
	draw.SimpleText("ZONE("..(zone)..")", "ixScannerFont", x + 8, y + 88, color_white)

	if (IsValid(self.lastViewEntity)) then
		data.start = self.lastViewEntity:GetPos()
		data.endpos = data.start + LocalPlayer():GetAimVector() * 500
		data.filter = self.lastViewEntity

		local entity = util.TraceLine(data).Entity

		if (IsValid(entity) and entity:IsPlayer()) then
			entity = entity:Name()
		else
			entity = "NULL"
		end

		draw.SimpleText("TRG ("..entity..")", "ixScannerFont", x + 8, y + 72, color_white)
	end

	surface.SetDrawColor(235, 235, 235, 230)

	surface.DrawLine(0, scrH, x - 128, scrH)
	surface.DrawLine(scrW + PICTURE_WIDTH2 + 128, scrH, ScrW(), scrH)
	surface.DrawLine(scrW, 0, scrW, y - 128)
	surface.DrawLine(scrW, scrH + PICTURE_HEIGHT2 + 128, scrW, ScrH())

	surface.DrawLine(x, y, x + 128, y)
	surface.DrawLine(x, y, x, y + 128)

	x = scrW + PICTURE_WIDTH2

	surface.DrawLine(x, y, x - 128, y)
	surface.DrawLine(x, y, x, y + 128)

	x = scrW - PICTURE_WIDTH2
	y = scrH + PICTURE_HEIGHT2

	surface.DrawLine(x, y, x + 128, y)
	surface.DrawLine(x, y, x, y - 128)

	x = scrW + PICTURE_WIDTH2

	surface.DrawLine(x, y, x - 128, y)
	surface.DrawLine(x, y, x, y - 128)

	surface.DrawLine(scrW - 48, scrH, scrW - 8, scrH)
	surface.DrawLine(scrW + 48, scrH, scrW + 8, scrH)
	surface.DrawLine(scrW, scrH - 48, scrW, scrH - 8)
	surface.DrawLine(scrW, scrH + 48, scrW, scrH + 8)
end

function PLUGIN:RenderScreenspaceEffects()
	if (not hidden) then return end
	blackAndWhite["$pp_colour_mulr"] = 1 + math.sin(RealTime() * 5) * 0.1
	blackAndWhite["$pp_colour_brightness"] = -0.05 + math.sin(RealTime() * 5) * 0.01
	DrawColorModify(blackAndWhite)
end

function PLUGIN:PlayerBindPress(ply, bind, pressed)
	bind = bind:lower()

	if (IsValid(ply:GetNetVar("ixScn"))) then
		if (bind:find("impulse 100") and pressed) then
			net.Start("ixScannerToggleFlashlight")
			net.SendToServer()
			return true
		end

		if (IsBlockedWeaponBind(bind)) then
			ResetWeaponSelect(ply)
			return true
		end

		if (bind:find("attack") and
			pressed and
			hidden and
			IsValid(self.lastViewEntity)) then
			self:takePicture()
			return true
		end
	end
end

function PLUGIN:PopulateCharacterInfo(client, character, tooltip)
	if IsValid(client) and IsValid(character) and client:GetNetVar("ixScanning") then
		local panel = tooltip:AddRowAfter("name", "scanner")
		panel:SetBackgroundColor(Color(43, 64, 116, 220))
		panel:SetText(L("scanning"))
		panel:SizeToContents()
	end
end
function PLUGIN:ShouldDrawLocalPlayer(ply)
	if (IsValid(ply:GetNetVar("ixScn"))) then
		return true
	end
end

function PLUGIN:PrePlayerDraw(ply)
	if (IsValid(ply:GetNetVar("ixScn"))) then
		ply:SetPoseParameter("aim_yaw", 0)
		ply:SetPoseParameter("aim_pitch", 0)
		ply:SetPoseParameter("head_yaw", 0)
		ply:SetPoseParameter("head_pitch", 0)
		ply:SetPoseParameter("body_yaw", 0)
		ply:SetPoseParameter("spine_yaw", 0)
	end
end

function PLUGIN:GetChatSpeakPos(speaker, chatType)
	local scanner = speaker:GetNetVar("ixScn")

	if (IsValid(scanner)) then
		return scanner:GetPos()
	end
end
