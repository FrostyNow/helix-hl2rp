PLUGIN.name = "Miscellaneous"
PLUGIN.author = "ZeMysticalTaco | Modified by Frosty"
PLUGIN.description = "Cool things."
PLUGIN.SaveEnts = PLUGIN.SaveEnts or {}

function PLUGIN:PlayerHurt(client, attacker, health, damage)
	if attacker:IsPlayer() then
		ix.log.AddRaw(client:Name() .. " has taken " .. damage .. " damage from " .. attacker:Name() .. " using " .. attacker:GetActiveWeapon():GetClass() .. " leaving them at " .. health .. " HP!", nil, Color(255, 200, 0))
	else
		ix.log.AddRaw(client:Name() .. " has taken " .. math.floor(damage) .. " damage from " .. attacker:GetClass() .. " leaving them at " .. math.floor(health) .. " HP!", nil, Color(255, 200, 0))
	end
end

--[[-------------------------------------------------------------------------
	BETTER ADMIN ESP
---------------------------------------------------------------------------]]
local dimDistance = -1
local aimLength = 128

ix.lang.AddTable("english", {
	optItemESP = "Show item ESP",
	optdItemESP = "Shows the names and locations of each item in the server.",
})
ix.lang.AddTable("korean", {
	optItemESP = "아이템 ESP 보기",
	optdItemESP = "서버에 있는 각각의 아이템의 이름과 위치를 표시합니다.",
})

ix.option.Add("itemESP", ix.type.bool, true, {
	category = "observer",
	hidden = function()
		return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Observer", nil)
	end
})

	function PLUGIN:HUDPaint()
		local client = LocalPlayer()

		if (client:IsAdmin() and client:GetMoveType() == MOVETYPE_NOCLIP and not client:InVehicle() and ix.option.Get("observerESP", true)) then
			local scrW, scrH = ScrW(), ScrH()

			if ix.option.Get("itemESP") then
				for k, v in pairs(ents.GetAll()) do
					if v:GetClass() == "ix_item" then
						local espcol = Color(255,255,255,255)
						local screenPosition = v:GetPos():ToScreen()
						local marginX, marginY = scrH * .1, scrH * .1
						local x2, y2 = math.Clamp(screenPosition.x, marginX, scrW - marginX), math.Clamp(screenPosition.y, marginY, scrH - marginY)
						local distance = client:GetPos():Distance(v:GetPos())
						local factor = 1 - math.Clamp(distance / dimDistance, 0, 1)
						local size2 = math.max(10, 32 * factor)
						local alpha2 = math.max(255 * factor, 80)
						local itemTable = v:GetItemTable()
						local espcols = {
							["Weapons"] = Color(255,50,50),
							["Ammo"] = Color(155,50,50),
							["Ammunition"] = Color(155,50,50),
							["Food"] = Color(100,255,100),
							["Alcohol"] = Color(100,255,100),
							["Crafting"] = Color(150,200,50),
							["Clothing"] = Color(65,200,150),
							["Clothes"] = Color(65,200,150),
							["Outfit"] = Color(65,200,150),
							["Attachments"] = Color(50,255,175),
							["Survival"] = Color(50,255,175),
							["Medical"] = Color(29,43,124),
							["Permits"] = Color(163,108,45),
							["Utility"] = Color(116,82,160),
							["Storage"] = Color(116,82,160),
							["Containers"] = Color(116,82,160),
							["Tools"] = Color(116,82,160)
						}

						for k2, v2 in pairs(espcols) do
							if itemTable.category == k2 then
								espcol = v2
							end
						end
						ix.util.DrawText(L(itemTable.name) or itemTable.name, x2, y2 - size2, espcol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, nil, alpha2)
						--ix.util.DrawText(itemTable.category, x2, y2 - size2 + 15, espcol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, nil, alpha2)
					end
				end
			end

			for _, v in ipairs(player.GetAll()) do
				if (v == client or not v:GetCharacter()) then continue end
				local screenPosition = v:GetPos():ToScreen()
				local marginX, marginY = scrH * .1, scrH * .1
				local x, y = math.Clamp(screenPosition.x, marginX, scrW - marginX), math.Clamp(screenPosition.y, marginY, scrH - marginY)
				local teamColor = team.GetColor(v:Team())
				local distance = client:GetPos():Distance(v:GetPos())
				local factor = 1 - math.Clamp(distance / dimDistance, 0, 1)
				local size = math.max(10, 32 * factor)
				local alpha = math.max(255 * factor, 80)
				surface.SetDrawColor(teamColor.r, teamColor.g, teamColor.b, alpha)
				surface.SetFont("ixGenericFont")
				local text = v:Name()
				
				if not v.status then
					v.status = "user"
				elseif v:IsUserGroup("superadmin") then
					v.status = "SA"
				elseif v:IsUserGroup("admin") then
					v.status = "A"
				elseif v:IsUserGroup("operator") then
					v.status = "O"
				elseif v:IsUserGroup("user") then
					v.status = "user"
				elseif v:IsUserGroup("producer") then
					v.status = "producer"
				else
					v.status = v:GetUserGroup()
				end

				local text2 = v:SteamName() .. "[" .. v.status .. "]"
				local text3 = "H: " .. v:Health() .. " A: " .. v:Armor()
				local text4 = v:GetActiveWeapon().PrintName
				surface.SetDrawColor(teamColor.r * 1.6, teamColor.g * 1.6, teamColor.b * 1.6, alpha)
				local col = Color(255, 255, 255, 255)

				if v:IsWepRaised() then
					col = Color(255, 100, 100, 255)
				end

				ix.util.DrawText(text, x, y - size, ColorAlpha(teamColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, nil, alpha)
				ix.util.DrawText(text2, x, y - size + 20, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, nil, alpha)
				ix.util.DrawText(text3, x, y - size + 40, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, nil, alpha)
				ix.util.DrawText(text4, x, y - size + 60, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, nil, alpha)
			end
		end
	end

local playerMeta = FindMetaTable("Player")

--[[-------------------------------------------------------------------------
	playerMeta:GetItemWeapon()

	Purpose: Checks the player's currently equipped weapon and returns the item and weapon.
	Syntax: player:GetItemWeapon()
	Returns: @weapon, @item
---------------------------------------------------------------------------]]

function playerMeta:GetItemWeapon()
	local char = self:GetCharacter()
	local inv = char:GetInventory()
	local items = inv:GetItems()
	local weapon = self:GetActiveWeapon()

	for k, v in pairs(items) do
		if v.class then
			if v.class == weapon:GetClass() then
				if v:GetData("equip", false) then
					return weapon, v
				else
					return false
				end
			end
		end
	end
end
