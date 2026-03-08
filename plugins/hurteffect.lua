PLUGIN.name = "More Hurt Effects"
PLUGIN.author = "Pokernut"
PLUGIN.description = "Add more hurt effects."

if (SERVER) then
	function PLUGIN:PlayerHurt(client, attacker, health, damage)
		if (client:IsAdmin() and client:GetMoveType() == MOVETYPE_NOCLIP) then return false end

		if ((client.ixNextPain or 0) < CurTime()) then
			client.ixNextPain = CurTime() + 0.33
			if (damage > 10 and client:Armor() == 0) then
				local endurance = client:GetCharacter():GetAttribute("end", 0)
			local maxAttr = ix.config.Get("maxAttributes", 100)

				if (damage - (endurance / maxAttr * 50) > 10) then
				else
					client:ScreenFade(1, Color(255, 255, 255, 255), 3, 0)
					client:ViewPunch(Angle(-1.3, 1.8, 0))
				end
			end
		end
	end
end