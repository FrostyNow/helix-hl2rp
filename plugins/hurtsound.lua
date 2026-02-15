
PLUGIN.name = "Pain Sounds"
PLUGIN.author = "Germanium"
PLUGIN.description = "scream louder mother."

local painSounds = {
	Sound("vo/npc/male01/pain01.wav"),
	Sound("vo/npc/male01/pain02.wav"),
	Sound("vo/npc/male01/pain03.wav"),
	Sound("vo/npc/male01/pain04.wav"),
	Sound("vo/npc/male01/pain05.wav"),
	Sound("vo/npc/male01/pain06.wav")
}

local metrocopPainSounds = {
	Sound("npc/metropolice/knockout2.wav"),
	Sound("npc/metropolice/pain1.wav"),
	Sound("npc/metropolice/pain2.wav"),
	Sound("npc/metropolice/pain3.wav"),
	Sound("npc/metropolice/pain1.wav")
}

local combinePainSounds = {
	Sound("npc/combine_soldier/pain1.wav"),
	Sound("npc/combine_soldier/pain2.wav"),
	Sound("npc/combine_soldier/pain3.wav")
}

local drownSounds = {
	Sound("player/pl_drown1.wav"),
	Sound("player/pl_drown2.wav"),
	Sound("player/pl_drown3.wav"),
}

function PLUGIN:GetPlayerPainSound(client)
	local char = client:GetCharacter()
	local model = client:GetModel():lower()
	
	if (client:IsAdmin() and client:GetMoveType() == MOVETYPE_NOCLIP) then return false end
	
	if (client:IsCombine()) then
		if (Schema:IsCombineRank(client:Name(), "SCN") or Schema:IsCombineRank(client:Name(), "SHEILD")) then 
			return false 
		end

		if (client:Team() == FACTION_MPF or model:find("police") or model:find("metrocop")) then
			return metrocopPainSounds[math.random(1, #metrocopPainSounds)]
		elseif (client:Team() == FACTION_OTA or model:find("combine")) then
			return combinePainSounds[math.random(1, #combinePainSounds)]
		end
	end

	if (char and char:IsVortigaunt()) then return false end

	if (client:WaterLevel() >= 3) then
		return drownSounds[math.random(1, #drownSounds)]
	end
end

function PLUGIN:PlayerHurt(client, attacker, health, damage)
	ix.log.Add(client, "playerHurt", damage, attacker:GetName() ~= "" and attacker:GetName() or attacker:GetClass())

	local char = client:GetCharacter()
	
	if (client:IsAdmin() and client:GetMoveType() == MOVETYPE_NOCLIP) then return false end

	if (char and char:IsVortigaunt()) then return false end

	if ((client.ixNextPain or 0) < CurTime() and health > 0) then
		local painSound = hook.Run("GetPlayerPainSound", client) or painSounds[math.random(1, #painSounds)]

		if (client:IsFemale() and !painSound:find("female")) then
			painSound = painSound:gsub("male", "female")
		end

		client:EmitSound(painSound)
		client.ixNextPain = CurTime() + 0.33
	end

end