PLUGIN.name = "Legs wyjebnik"
PLUGIN.author = "Lechu2375"
PLUGIN.description = "Now hitting right in the legs causes injures."
PLUGIN.license =  "MIT not for use on Kaktusownia opensource.org/licenses/MIT"

ix.config.Add("legShootChance", 40, "Default chance to fall when shot in the leg.", nil, {
	data = {min = 0, max = 100},
	category = "Leg Shoot"
})
ix.config.Add("luckMultiplier", 1, "Luck multiplier to reduce the chance of falling.", nil, {
	data = {min = 0, max = 10},
	category = "Leg Shoot"
})
ix.config.Add("enduranceMultiplier", 0.5, "Endurance multiplier to reduce the chance of falling.", nil, {
	data = {min = 0, max = 10},
	category = "Leg Shoot"
})

if SERVER then
	local legs = {
		[HITGROUP_LEFTLEG] = true,
		[HITGROUP_RIGHTLEG] = true
	}
	function PLUGIN:ScalePlayerDamage(ply, hitgroup, dmginfo)
		if (ply:IsAdmin() and ply:GetMoveType() == MOVETYPE_NOCLIP) then return end
		
		local char = ply:GetCharacter()
		if not char then return end
		if (FACTION_OTA and char:GetFaction() == FACTION_OTA) then return end
		
		if legs[hitgroup] then
			local luck = char:GetAttribute("lck", 0)
			local luckMlt = ix.config.Get("luckMultiplier", 1)
			local endurance = char:GetAttribute("end", 0)
			local endMlt = ix.config.Get("enduranceMultiplier", 0.5)
			local maxAttr = ix.config.Get("maxAttributes", 100)
			local normFactor = 100 / maxAttr

			local baseChance = ix.config.Get("legShootChance", 40)

			local threshold = baseChance - (luck * normFactor * luckMlt) - (endurance * normFactor * endMlt)

			if ply:Armor() > 0 then
				threshold = threshold * 0.5
			end
			if (math.random(1, 100) <= threshold) then
				local duration = math.max(math.random(2, 4) - (luck * normFactor * 0.1), 1)
				ply:SetRagdolled(true, duration)
			end
		end
	end
end