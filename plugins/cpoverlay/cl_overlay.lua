
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
function CombHUD()
	
	if !LocalPlayer():IsValid() or !LocalPlayer():Alive() then return end -- you can fix this yourself, it errors and i cba to find the solution because it doesn't really matter since the hud still works
	if !LocalPlayer():GetCharacter() then return end
	if (Schema:CanPlayerSeeCombineOverlay(LocalPlayer())) then
		local tsin = TimedSin(.68, 200, 255, 0)
		local area = LocalPlayer():GetArea()
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
		if !weapon:IsValid() then return end
		local clip = weapon:Clip1()
		local clipMax = weapon:GetMaxClip1()
		local count = LocalPlayer():GetAmmoCount(weapon:GetPrimaryAmmoType())
		local secondary = LocalPlayer():GetAmmoCount(weapon:GetSecondaryAmmoType())
		local Arm = L("Unknown") -- honestly i don't know if this is necessary but /shrug
		for k, v in pairs(weps) do
			if tostring(LocalPlayer():GetActiveWeapon():GetPrintName()) == k then
				Arm = v or L("Unknown") -- honestly i don't know if this is necessary but /shrug
			elseif tostring(LocalPlayer():GetActiveWeapon():GetClass()) == k then
				Arm = v or L("Unknown") -- honestly i don't know if this is necessary but /shrug
			end
		end
		if LocalPlayer():Health() >= LocalPlayer():GetMaxHealth() then -- there's probably a more efficient way to do whatever is below but eh
			hpCol = Color(18, 196, 18)
		elseif LocalPlayer():Health() >= LocalPlayer():GetMaxHealth() * 8 / 10 then
			hpCol = Color(255,239,17)
		else
			if LocalPlayer():Health() < LocalPlayer():GetMaxHealth() * 4 / 10 then
				hpCol = Color(tsin, 20, 20)
			end
		end

		if LocalPlayer():Armor() >= LocalPlayer():GetMaxArmor() then
			armCol = Color(18, 196, 18)
		elseif LocalPlayer():Armor() >= LocalPlayer():GetMaxArmor() * 8 / 10 then
			armCol = Color(255,239,17)
		else
			if LocalPlayer():Armor() < LocalPlayer():GetMaxArmor() * 4 / 10 then
				armCol = Color(223,20,20)
			end
		end
		if LocalPlayer():Team() == FACTION_MPF then
			lA = "// "..L"PROTECTION TEAM"
		else
			if LocalPlayer():Team() == FACTION_OTA then
				lA = "// "..L"STABILIZATION TEAM"
			end
		end
		
		--main square 1 (unit info)
		local ux, uy = ScrW() - 310, 40

		surface.SetDrawColor(0, 0, 0, 175)
		surface.DrawRect(ux, uy, 300, 180)
		surface.SetDrawColor(17, 136, 247, 255)
		surface.DrawOutlinedRect(ux, uy, 300, 180)
		draw.SimpleText(lA, "BudgetLabel", ux + 10, uy + 10, tcolor)
		draw.SimpleText("<::"..L"LOCAL UNIT: "..LocalPlayer():Name(), "BudgetLabel", ux + 10, uy + 30, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
		draw.SimpleText("<::"..L"ASSET HEALTH: "..LocalPlayer():Health(), "BudgetLabel", ux + 10, uy + 50, hpCol)
		draw.SimpleText("<::"..L"ASSET ARMOR: "..LocalPlayer():Armor(), "BudgetLabel", ux + 10, uy + 70, armCol)
		draw.SimpleText("<::"..L"ASSET TOKENS: "..money, "BudgetLabel", ux + 10, uy + 90)
		surface.SetDrawColor(17, 136, 247, 255)
		surface.DrawRect(ux + 2, uy + 115, 296, 1)
		draw.SimpleText("<::"..L"BIOSIGNAL ZONE: "..area, "BudgetLabel", ux + 10, uy + 130)
		draw.SimpleText("<::"..L"BIOSIGNAL GRID: "..grid, "BudgetLabel", ux + 10, uy + 150)
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
		local x, y = ScrW() - 310, ScrH() - 65

		surface.SetDrawColor(17, 136, 247, 150)
		surface.DrawOutlinedRect(x, y, 300, 55)
		surface.SetDrawColor(0, 0, 0, 175)
		surface.DrawRect(x, y, 300, 55)
		draw.SimpleText(L"ARM: "..Arm, "BudgetLabel", x + 10, y + 10)
		draw.SimpleText("[ "..clip.." / "..clipMax.." ]", "BudgetLabel", x + 10, y + 30)
		draw.SimpleText("[ "..count.." ]", "BudgetLabel", x + 80, y + 30)
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
	local m = 1
	local spacing = (width * m) / 360
	local lines = width / spacing
	local rang = math.Round(ang.y)

	surface.SetDrawColor(0, 0, 0, 175)
	surface.DrawRect(ScrW() / 2 - (width / 2) - 16, 30, width + 32, 35)
	surface.SetDrawColor(17, 136, 247, 150)
	surface.DrawOutlinedRect(ScrW() / 2 - (width / 2) - 16, 30, width + 32, 35)

	draw.SimpleText(ang, "BudgetLabel", ScrW() / 2, 50, color_white, TEXT_ALIGN_CENTER)

	surface.SetDrawColor(17, 136, 247, 255)
	surface.DrawRect(ScrW() / 2 - (width / 2) - 8, 46, width + 16, 1)

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

	if (Schema:CanPlayerSeeCombineOverlay(lp)) and (nextmessage or 0) < CurTime() then
		local message = L(idlemessages[math.random(1, #idlemessages)])

		if message != (lastmessage or "") then
			Schema:AddCombineDisplayMessage(message)
			lastmessage = message
		end

		nextmessage = CurTime() + math.random(3, 4) -- this is the timer for when these show, increase numbers for longer times between messages
	end
end)

hook.Add("CanDrawAmmoHUD", "CHUD_HideBaseAmmo", function(weapon)
	if Schema:CanPlayerSeeCombineOverlay(LocalPlayer()) then
		return false
	end
end)
