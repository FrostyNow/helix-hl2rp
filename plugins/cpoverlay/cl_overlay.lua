
-- Personally I find this too overbearing, too much info in your face. You can use it if you want.
-- you might have to edit the location of the boxes btw this was made with 1280 x 720 reference
local font = ix.config.Get("font", "Roboto")

surface.CreateFont("HUDSmooth", {
	font = font,
	size = 18,
	antialias = true,
	weight = 350,
	extended,
})

local weps = { -- this table is for the weapons printnames, to be shown correctly on the armament info.
	["#HL2_Shotgun"] = "Shotgun",
	["#HL2_Pistol"] = "9mm Pistol",
	["#HL2_Pulse_Rifle"] = "Standard Issue Pulse Rifle",
	["Stunstick"] = "Stunstick",
	["#HL2_SMG1"] = "Submachine Gun",
	["#HL2_357Handgun"] = ".357 Revolver",
	["#HL2_Grenade"] = "Grenade"
}
function CombHUD()
	
	if !LocalPlayer():IsValid() or !LocalPlayer():Alive() then return end -- you can fix this yourself, it errors and i cba to find the solution because it doesn't really matter since the hud still works
	if !LocalPlayer():GetCharacter() then return end
	if LocalPlayer():IsCombine() then
		local tsin = TimedSin(.68, 200, 255, 0)
		local area = LocalPlayer():GetArea() or "Unknown" -- fyi if you step out of an area and there's no new area this won't update
		local tcolor = team.GetColor(LocalPlayer():Team())
		local w = ScrW() / 2
		local h = ScrH() / 2
		local pos = LocalPlayer():GetPos()
		local grid = math.Round(pos.x / 100).."/"..math.Round(pos.y / 100)
		local weapon = LocalPlayer():GetActiveWeapon()
		local money = LocalPlayer():GetCharacter():GetMoney() or 0
		if !weapon:IsValid() then return end
		local clip = weapon:Clip1()
		local clipMax = weapon:GetMaxClip1()
		local count = LocalPlayer():GetAmmoCount(weapon:GetPrimaryAmmoType())
		local secondary = LocalPlayer():GetAmmoCount(weapon:GetSecondaryAmmoType())
		local Arm = "Unknown" -- honestly i don't know if this is necessary but /shrug
		for k, v in pairs(weps) do
			if tostring(LocalPlayer():GetActiveWeapon():GetPrintName()) == k then
				Arm = v or "Unknown" -- honestly i don't know if this is necessary but /shrug
			end
		end
		if LocalPlayer():Health() >= 75 then -- there's probably a more efficient way to do whatever is below but eh
			hpCol = Color(18, 196, 18)
		elseif LocalPlayer():Health() >= 40 then
			hpCol = Color(255,239,17)
		else
			if LocalPlayer():Health() < 40 then
				hpCol = Color(tsin, 20, 20)
			end
		end

		if LocalPlayer():Armor() >= 70 then
			armCol = Color(18, 196, 18)
		elseif LocalPlayer():Armor() >= 35 then
			armCol = Color(255,239,17)
		else
			if LocalPlayer():Armor() < 35 then
				armCol = Color(223,20,20)
			end
		end
		if LocalPlayer():Team() == FACTION_MPF then
			lA = "LOCAL ASSET"
		else
			if LocalPlayer():Team() == FACTION_OTA then
				lA = "OVERWATCH ASSET"
			end
		end
		
		--main square 1 (unit info)
		surface.SetDrawColor(17, 136, 247, 150)
		surface.DrawOutlinedRect(w + 500, h - 500, 300, 180, 2)
		surface.SetDrawColor(66, 63, 63, 120)
		surface.DrawRect(w+500, h - 500, 300, 180)
		draw.SimpleText("LOCAL UNIT: "..LocalPlayer():Name(), "HUDSmooth", w+510, h-470, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
		draw.SimpleText(lA, "HUDSmooth", w+510, h-490, tcolor)
		draw.SimpleText("ASSET HEALTH: "..LocalPlayer():Health(), "HUDSmooth", w+510,h-450, hpCol)
		draw.SimpleText("ASSET ARMOR: "..LocalPlayer():Armor(), "HUDSmooth", w+510,h-430, armCol)
		draw.SimpleText("ASSET TOKENS: "..money, "HUDSmooth", w+510, h-410)
		surface.SetDrawColor(17, 136, 247, 150)
		surface.DrawRect(w+502,h-385, 296, 5)
		draw.SimpleText("BIOSIGNAL ZONE: "..area, "HUDSmooth", w+510, h-370)
		draw.SimpleText("BIOSIGNAL GRID: "..grid, "HUDSmooth", w+510, h-350)
		--[[ local gm = LocalPlayer():GetModel() commented out because it looks ugly as hell & is unnecessary
		local gs = LocalPlayer():GetSkin()
		if LocalPlayer():Team() == 3 then
			local mpf = Material("seren/mpf.png", "smooth")......0
			surface.SetDrawColor(255, 255, 255, 150)
			surface.SetMaterial(mpf)
			surface.DrawTexturedRect(w-460, h-290, 64, 64)
		end
		if LocalPlayer():Team() == 4 then
			if gm == "models/combine_super_soldier.mdl" then
				local eow = Material("seren/eow.png", "smooth")
				surface.SetDrawColor(255, 255, 255, 150)
				surface.SetMaterial(eow)
				surface.DrawTexturedRect(w-460, h-290, 64, 64)
			elseif gm == "models/combine_soldier.mdl" and gs == 0 then
				local ows = Material("seren/ows.png", "smooth")
				surface.SetDrawColor(255, 255, 255, 150)
				surface.SetMaterial(ows)
				surface.DrawTexturedRect(w-470, h-290, 96, 63)
			else
				local sgs = Material("seren/sgs.png", "smooth")
				surface.SetDrawColor(255, 255, 255, 180)
				surface.SetMaterial(sgs)
				surface.DrawTexturedRect(w-460, h-290, 64, 64)
			end
		end ]]
		--main square 2 (idle feedback)
		--[[
		surface.DrawOutlinedRect(w + 240, h - 330, 500, 45) -- !!this will be disturbed by health, armor, and stamina bars!!
		surface.SetDrawColor(66, 63, 63, 120)
		surface.DrawRect(w+240, h - 330, 500, 45)]]-- to get the feedback to align with the box requires some schema configurations by the dev. commenting this out

		--main square 3 (armament info)
		local ga = LocalPlayer():GetActiveWeapon():GetClass()
		if ga == "ix_hands" or ga == "ix_keys" or ga == "gmod_tool" or ga == "weapon_physgun" then return end
		surface.SetDrawColor(17, 136, 247, 150)
		surface.DrawOutlinedRect(w+500, h+465, 300, 55)
		surface.SetDrawColor(66, 63, 63, 120)
		surface.DrawRect(w+500, h+465, 300, 55)
		draw.SimpleText("ARM: "..Arm, "HUDSmooth", w+510, h + 475)
		draw.SimpleText("[ "..clip.." / "..clipMax.." ]", "HUDSmooth", w+510, h + 495)
		draw.SimpleText("[ "..count.." ]", "HUDSmooth", w + 580, h + 495)
	end
end 
local direction = {
	[0] = "N",
	[45] = "NE",
	[90] = "E",
	[135] = "SE",
	[180] = "S",
	[225] = "SW",
	[270] = "W",
	[315] = "NW",
	[360] = "N"
}

local function CombineCompass()
	if !LocalPlayer():IsCombine() then return end
	local ang = LocalPlayer():EyeAngles()
	local width = ScrW() * .23
	local m = 1
	local spacing = (width * m) / 360
	local lines = width / spacing
	local rang = math.Round(ang.y)

	surface.SetDrawColor(0, 0, 0, 175)
	surface.DrawRect(ScrW() / 2 - (width / 2) - 8, 30, width + 16, 35)
	surface.SetDrawColor(17, 136, 247, 150)
	surface.DrawOutlinedRect(ScrW() / 2 - (width / 2) - 8, 30, width + 16, 35)

	draw.SimpleText(ang, "BudgetLabel", ScrW() / 2, 50, color_white, TEXT_ALIGN_CENTER)

	for i = (rang - (lines / 2)) % 360, ((rang - (lines / 2)) % 360) + lines do
		local x = (ScrW() / 2 + (width / 2)) - ((i - ang.y - 180) % 360) * spacing

		if i % 30 == 0 and i > 0 then
			local text = direction[360 - (i % 360)] and direction[360 - (i % 360)] or 360 - (i % 360)

			draw.SimpleText(text, "BudgetLabel", x, 30, color_white, TEXT_ALIGN_CENTER)
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

	if (lp:Team() == FACTION_MPF or lp:Team() == FACTION_OTA) and (nextmessage or 0) < CurTime() then
		local message = L(idlemessages[math.random(1, #idlemessages)])

		if message != (lastmessage or "") then
			Schema:AddCombineDisplayMessage(message)
			lastmessage = message
		end

		nextmessage = CurTime() + math.random(3, 4) -- this is the timer for when these show, increase numbers for longer times between messages
	end
end)
