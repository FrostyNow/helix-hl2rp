
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
	["ix_stunstick"] = L("Stunstick"),
	["#HL2_SMG1"] = L("Submachine Gun"),
	["#HL2_357Handgun"] = L(".357 Revolver"),
	["#HL2_Grenade"] = L("Grenade"),
	["arc9_hla_irifle"] = L("Standard Issue Pulse Rifle"),
	["arc9_hl2_pistol"] = L("9mm Pistol"),
	["arc9_hl2_smg1"] = L("Submachine Gun"),
	["arc9_rtb_oicw"] = "OICW",
	["arc9_l4d2_spas12"] = L("Shotgun"),
	["arc9_l4d2_mp5"] = "MP5K",
	["weapon_rtbr_frag"] = L("Grenade"),
	["weapon_rtbr_oicw"] = "OICW",
	["weapon_rtbr_flaregun"] = L("Flare Gun"),
}


function CombHUD()
	if !LocalPlayer():IsValid() or !LocalPlayer():Alive() then return end 
	if !LocalPlayer():GetCharacter() then return end

	if (Schema:CanPlayerSeeCombineOverlay(LocalPlayer())) then

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
			draw.SimpleText(lA, "BudgetLabel", ux + 10, uy + 10, tcolor)
			draw.SimpleText("<:: "..L"LOCAL UNIT: "..LocalPlayer():Name(), "BudgetLabel", ux + 10, uy + 30, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
			draw.SimpleText("<:: "..L"ASSET HEALTH: "..LocalPlayer():Health(), "BudgetLabel", ux + 10, uy + 50, hpCol)
			draw.SimpleText("<:: "..L"ASSET ARMOR: "..LocalPlayer():Armor(), "BudgetLabel", ux + 10, uy + 70, armCol)
			draw.SimpleText("<:: "..L"ASSET TOKENS: "..money, "BudgetLabel", ux + 10, uy + 90)
			draw.SimpleText("<:: "..L"BIOSIGNAL ZONE: "..L(area), "BudgetLabel", ux + 10, uy + 130)
			draw.SimpleText("<:: "..L"BIOSIGNAL GRID: "..grid, "BudgetLabel", ux + 10, uy + 150)

			--main square 3 (armament info)
			local ga = weapon:GetClass()
			if ga != "ix_hands" and ga != "ix_keys" and ga != "gmod_tool" and ga != "weapon_physgun" then
				local x, y = ScrW() - 310, ScrH() - 65

				surface.SetDrawColor(0, 0, 0, 175)
				surface.DrawRect(x, y, 300, 55)
				draw.SimpleText(L"ARM: "..Arm, "BudgetLabel", x + 10, y + 10)
				draw.SimpleText("[ "..clip.." / "..clipMax.." ]", "BudgetLabel", x + 10, y + 30)
				draw.SimpleText("[ "..count.." ]", "BudgetLabel", x + 80, y + 30)
			end
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
	

	local ang = LocalPlayer():EyeAngles()
	local width = ScrW() * .23
	
	local x = cookie.GetNumber("ixHUD_compass_X", (ScrW() / 2 - (width / 2) - 16) / ScrW()) * ScrW()
	local y = cookie.GetNumber("ixHUD_compass_Y", 30 / ScrH()) * ScrH()

	local visibleDegrees = 180 -- Visible field of view in compass
	local spacing = width / visibleDegrees
	local centerPos = x + (width + 32) / 2
	local heading = math.Round(ang.y % 360)

	surface.SetDrawColor(0, 0, 0, 175)
	surface.DrawRect(x, y, width + 32, 35)
	-- Current heading number
	draw.SimpleText(math.Round(ang.y), "BudgetLabel", centerPos, y + 18, color_white, TEXT_ALIGN_CENTER)

	-- Ticks and Labels
	for i = 0, 359, 15 do
		local diff = math.NormalizeAngle(i - ang.y)
		
		if (math.abs(diff) < visibleDegrees / 2) then
			local tickX = centerPos + diff * spacing
			
			if (i % 30 == 0) then
				local text = direction[i] and direction[i] or tostring(i)
				draw.SimpleText(text, "BudgetLabel", tickX, y + 2, color_white, TEXT_ALIGN_CENTER)
			end

		end
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

hook.Add("ixHUDReset", "ixCPOverlayReset", function()
	local elements = {"compass", "cp_unit"}
	for _, v in ipairs(elements) do
		cookie.Set("ixHUD_" .. v .. "_X", nil)
		cookie.Set("ixHUD_" .. v .. "_Y", nil)
	end
end)

