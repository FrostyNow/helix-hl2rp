
-- Personally I find this too overbearing, too much info in your face. You can use it if you want.
-- you might have to edit the location of the boxes btw this was made with 1280 x 720 reference
local font = ix.config.Get("font", "Roboto")

surface.CreateFont("HUDSmooth", {
	font = font,
	size = 18,
	antialias = true,
	weight = 350,
	extended,
	outline = true,
})

local weps = { -- this table is for the weapons printnames, to be shown correctly on the armament info.
	["#HL2_Shotgun"] = L("Shotgun"),
	["#HL2_Pistol"] = L("9mm Pistol"),
	["#HL2_Pulse_Rifle"] = L("Standard Issue Pulse Rifle"),
	["Stunstick"] = L("Stunstick"),
	["#HL2_SMG1"] = L("Submachine Gun"),
	["#HL2_357Handgun"] = L(".357 Revolver"),
	["#HL2_Grenade"] = L("Grenade"),
	["arc9_hla_irifle"] = L("Standard Issue Pulse Rifle"),
	["arc9_hl2_pistol"] = L("9mm Pistol"),
	["arc9_hl2_smg1"] = L("Submachine Gun"),
	["weapon_rtbr_flaregun"] = L("Flare Gun"),
	["weapon_rtbr_oicw"] = "OICW",
}

local function GetViewBobMatrix()
	local vbob = ix.plugin.Get("newviewbob")
	if (vbob and vbob.bobData) then
		local data = vbob.bobData
		local w, h = ScrW(), ScrH()
		local matrix = Matrix()

		matrix:Translate(Vector(w / 2, h / 2))
		matrix:Rotate(Angle(0, data.roll, 0))
		matrix:Translate(Vector(-w / 2, -h / 2))
		
		-- Apply translation (shaking and slight pitch tilt for depth)
		matrix:Translate(Vector(data.right * 5, -data.up * 5 + data.pitch * 2))
		
		return matrix
	end
end

function CombHUD()
	if !LocalPlayer():IsValid() or !LocalPlayer():Alive() then return end 
	if !LocalPlayer():GetCharacter() then return end

	if (Schema:CanPlayerSeeCombineOverlay(LocalPlayer())) then
		local matrix = GetViewBobMatrix()
		if (matrix) then
			cam.PushModelMatrix(matrix)
		end

		local tsin = TimedSin(.68, 200, 255, 0)
		local area = LocalPlayer():GetAreaName()
		if (!area or area == "") then
			area = L("Unknown Location")
		end
		local tcolor = team.GetColor(LocalPlayer():Team())
		local w = ScrW() / 2
		local h = ScrH() / 2
		local pos = LocalPlayer():GetPos()
		local grid = math.Round(pos.x / 100).."/"..math.Round(pos.y / 100)
		local weapon = LocalPlayer():GetActiveWeapon()
		local money = LocalPlayer():GetCharacter():GetMoney() or 0
		
		if (IsValid(weapon)) then
			local clip = weapon:Clip1()
			local clipMax = weapon:GetMaxClip1()
			local count = LocalPlayer():GetAmmoCount(weapon:GetPrimaryAmmoType())
			local secondary = LocalPlayer():GetAmmoCount(weapon:GetSecondaryAmmoType())
			local Arm = L("Unknown") 

			for k, v in pairs(weps) do
				if tostring(weapon:GetPrintName()) == k then
					Arm = v or L("Unknown") 
				elseif tostring(weapon:GetClass()) == k then
					Arm = v or L("Unknown") 
				end
			end

			local hpCol = Color(255, 255, 255)
			if LocalPlayer():Health() >= LocalPlayer():GetMaxHealth() then 
				hpCol = Color(18, 196, 18)
			elseif LocalPlayer():Health() >= LocalPlayer():GetMaxHealth() * 8 / 10 then
				hpCol = Color(255,239,17)
			elseif LocalPlayer():Health() < LocalPlayer():GetMaxHealth() * 4 / 10 then
				hpCol = Color(tsin, 20, 20)
			end

			local armCol = Color(255, 255, 255)
			if LocalPlayer():Armor() >= LocalPlayer():GetMaxArmor() then
				armCol = Color(18, 196, 18)
			elseif LocalPlayer():Armor() >= LocalPlayer():GetMaxArmor() * 8 / 10 then
				armCol = Color(255,239,17)
			elseif LocalPlayer():Armor() < LocalPlayer():GetMaxArmor() * 4 / 10 then
				armCol = Color(223,20,20)
			end

			local lA = ""
			if LocalPlayer():Team() == FACTION_MPF then
				lA = "// "..L"PROTECTION TEAM"
			elseif LocalPlayer():Team() == FACTION_OTA then
				lA = "// "..L"STABILIZATION TEAM"
			end
			
			--main square 1 (unit info)
			local ux = cookie.GetNumber("ixHUD_cp_unit_X", (ScrW() - 310) / ScrW()) * ScrW()
			local uy = cookie.GetNumber("ixHUD_cp_unit_Y", 40 / ScrH()) * ScrH()

			surface.SetDrawColor(0, 0, 0, 175)
			surface.DrawRect(ux, uy, 300, 180)
			surface.SetDrawColor(17, 136, 247, 255)
			surface.DrawOutlinedRect(ux, uy, 300, 180)
			draw.SimpleText(lA, "BudgetLabel", ux + 10, uy + 10, tcolor)
			draw.SimpleText("<:: "..L"LOCAL UNIT: "..LocalPlayer():Name(), "BudgetLabel", ux + 10, uy + 30, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
			draw.SimpleText("<:: "..L"ASSET HEALTH: "..LocalPlayer():Health(), "BudgetLabel", ux + 10, uy + 50, hpCol)
			draw.SimpleText("<:: "..L"ASSET ARMOR: "..LocalPlayer():Armor(), "BudgetLabel", ux + 10, uy + 70, armCol)
			draw.SimpleText("<:: "..L"ASSET TOKENS: "..money, "BudgetLabel", ux + 10, uy + 90)
			surface.SetDrawColor(17, 136, 247, 255)
			surface.DrawRect(ux + 2, uy + 115, 296, 1)
			draw.SimpleText("<:: "..L"BIOSIGNAL ZONE: "..L(area), "BudgetLabel", ux + 10, uy + 130)
			draw.SimpleText("<:: "..L"BIOSIGNAL GRID: "..grid, "BudgetLabel", ux + 10, uy + 150)

			--main square 3 (armament info)
			local ga = weapon:GetClass()
			if ga != "ix_hands" and ga != "ix_keys" and ga != "gmod_tool" and ga != "weapon_physgun" then
				local x, y = ScrW() - 310, ScrH() - 65

				surface.SetDrawColor(0, 0, 0, 175)
				surface.DrawRect(x, y, 300, 55)
				surface.SetDrawColor(17, 136, 247, 150)
				surface.DrawOutlinedRect(x, y, 300, 55)
				draw.SimpleText(L"ARM: "..Arm, "BudgetLabel", x + 10, y + 10)
				draw.SimpleText("[ "..clip.." / "..clipMax.." ]", "BudgetLabel", x + 10, y + 30)
				draw.SimpleText("[ "..count.." ]", "BudgetLabel", x + 80, y + 30)
			end
		end

		if (matrix) then
			cam.PopModelMatrix()
		end
	end
end 
local direction = {
	[0] = "[N]",
	[45] = "[NE]",
	[90] = "[E]",
	[135] = "[SE]",
	[180] = "[S]",
	[225] = "[SW]",
	[270] = "[W]",
	[315] = "[NW]",
	[360] = "[N]"
}

local function CombineCompass()
	if !Schema:CanPlayerSeeCombineOverlay(LocalPlayer()) then return end
	
	local matrix = GetViewBobMatrix()
	if (matrix) then
		cam.PushModelMatrix(matrix)
	end

	local ang = LocalPlayer():EyeAngles()
	local width = ScrW() * .23
	local x = cookie.GetNumber("ixHUD_compass_X", (ScrW() / 2 - (width / 2) - 16) / ScrW()) * ScrW()
	local y = cookie.GetNumber("ixHUD_compass_Y", 30 / ScrH()) * ScrH()

	local m = 1
	local spacing = (width * m) / 360
	local lines = width / spacing
	local rang = math.Round(ang.y)

	surface.SetDrawColor(0, 0, 0, 175)
	surface.DrawRect(x, y, width + 32, 35)
	surface.SetDrawColor(17, 136, 247, 150)
	surface.DrawOutlinedRect(x, y, width + 32, 35)

	draw.SimpleText(ang, "BudgetLabel", x + (width + 32) / 2, y + 20, color_white, TEXT_ALIGN_CENTER)

	surface.SetDrawColor(17, 136, 247, 255)
	surface.DrawRect(x + 8, y + 16, width + 16, 1)

	for i = (rang - (lines / 2)) % 360, ((rang - (lines / 2)) % 360) + lines do
		local x2 = (x + (width + 32) / 2) - ((i - ang.y - 180) % 360) * spacing

		if i % 30 == 0 and i > 0 then
			local text = direction[360 - (i % 360)] and direction[360 - (i % 360)] or 360 - (i % 360)

			draw.SimpleText(text, "BudgetLabel", x2, y, color_white, TEXT_ALIGN_CENTER)
		end
	end

	if (matrix) then
		cam.PopModelMatrix()
	end
end
hook.Add("HUDPaint", "CHUD", CombHUD)
hook.Add("HUDPaint", "CComp", CombineCompass)

local nextmessage
local lastmessage
local idlemessages = {
	"cIdleConnection",
	"cPingingLoopback",
	"cUpdatingBiosignal",
	"cEstablishingDC",
	"cCheckingExodus",
	"cSendingCommdata",
	"cCheckingBiosignal",
	"cCheckingBOL",
	"cPurportingDisp",
}

hook.Add("Think", "AmbientMessages", function()
	local lp = LocalPlayer()

	if (Schema:CanPlayerSeeCombineOverlay(lp)) and (nextmessage or 0) < CurTime() then
		local message = L(idlemessages[math.random(1, #idlemessages)])

		if message != (lastmessage or "") then
			Schema:AddCombineDisplayMessage(message)
			lastmessage = message
		end

		nextmessage = CurTime() + math.random(5, 10) 
	end
end)

hook.Add("CanDrawAmmoHUD", "CHUD_HideBaseAmmo", function(weapon)
	if Schema:CanPlayerSeeCombineOverlay(LocalPlayer()) then
		return false
	end
end)

hook.Add("OnContextMenuOpen", "ixCPOverlayLocators", function()
	if (Schema:CanPlayerSeeCombineOverlay(LocalPlayer())) then
		local compass_w = ScrW() * .23
		ix.gui.locators = ix.gui.locators or {}
		
		-- Compass Locator
		local compass_locator = vgui.Create("ixHUDLocator")
		compass_locator:Setup("compass", "Combine Compass", ScrW() / 2 - (compass_w / 2) - 16, 30)
		table.insert(ix.gui.locators, compass_locator)
		
		-- CP Unit info Locator
		local cp_unit_locator = vgui.Create("ixHUDLocator")
		cp_unit_locator:Setup("cp_unit", "Unit Bio-Signals (CP)", ScrW() - 310, 40)
		table.insert(ix.gui.locators, cp_unit_locator)
	end
end)

hook.Add("ixHUDReset", "ixCPOverlayReset", function()
	local elements = {"compass", "cp_unit"}
	for _, v in ipairs(elements) do
		cookie.Set("ixHUD_" .. v .. "_X", nil)
		cookie.Set("ixHUD_" .. v .. "_Y", nil)
	end
end)

