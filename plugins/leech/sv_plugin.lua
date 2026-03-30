local PLUGIN = PLUGIN

local leechSounds = {
	"npc/leech/leech_bite1.wav",
	"npc/leech/leech_bite2.wav",
	"npc/leech/leech_bite3.wav"
}

local leechWarnings = {
	"leechWarning1",
	"leechWarning2",
	"leechWarning3"
}

function PLUGIN:IsPointInWater(pos)
	return bit.band(util.PointContents(pos), CONTENTS_WATER) != 0
end

function PLUGIN:SpawnLeechSwarm(client)
	client.ixLeechSwarm = client.ixLeechSwarm or {}

	-- Clean up dead/invalid NPCs in the swarm
	for i = #client.ixLeechSwarm, 1, -1 do
		local npc = client.ixLeechSwarm[i]
		if (!IsValid(npc) or !npc:Alive()) then
			table.remove(client.ixLeechSwarm, i)
		end
	end

	-- Spawn up to 10 NPCs around the player
	if (#client.ixLeechSwarm < 10) then
		local pos = client:GetPos() + VectorRand(-50, 50)
		pos.z = pos.z - 10 -- Spawn slightly below

		local npc = ents.Create("npc_vj_hlr1_leech")
		if (IsValid(npc)) then
			npc:SetPos(pos)
			npc:SetAngles(Angle(0, math.random(0, 360), 0))
			npc:Spawn()
			npc:Activate()
			
			-- Force attack the player
			if (npc.VJ_AddEntityRelationship) then
				npc:VJ_AddEntityRelationship(client, D_HT, 99)
			end
			npc:SetEnemy(client)

			table.insert(client.ixLeechSwarm, npc)
		end
	end
end

function PLUGIN:RemoveLeechSwarm(client)
	if (client.ixLeechSwarm) then
		for _, npc in pairs(client.ixLeechSwarm) do
			if (IsValid(npc)) then
				npc:Remove()
			end
		end
		client.ixLeechSwarm = {}
	end
end

function PLUGIN:InitializedPlugins()
	local bHasVJLeech = list.Get("NPC")["npc_vj_hlr1_leech"] != nil

	timer.Create("ixLeechTick", 0.5, 0, function()
		for _, client in player.Iterator() do
			local character = client:GetCharacter()
			if (!character) then continue end
			if (client:GetMoveType() == MOVETYPE_NOCLIP) then continue end
			
			local waterLevel = client:WaterLevel()
			local areaID = client:GetArea()
			local isLeechArea = false
			local inLeechWarningZone = false

			if (areaID and areaID != "") then
				local area = ix.area.stored[areaID]
				if (area and area.properties and area.properties.leeches) then
					if (waterLevel >= 1) then
						inLeechWarningZone = true
					end

					-- Smart attack logic
					if (!client:IsOnGround() and waterLevel >= 2) then
						isLeechArea = true
					elseif (client:IsOnGround() and waterLevel >= 3) then
						if (client:Crouching()) then
							if (self:IsPointInWater(client:GetPos() + Vector(0, 0, 72))) then
								isLeechArea = true
							end
						else
							isLeechArea = true
						end
					end
				end
			end

			-- Warn the player
			local wasInLeechWarningZone = client.ixInLeechWarningZone or false
			if (inLeechWarningZone and !wasInLeechWarningZone and client:Alive()) then
				client.ixInLeechWarningZone = true
				if ((client.ixNextLeechWarning or 0) < CurTime()) then
					local msg = table.Random(leechWarnings)
					ix.chat.Send(client, "it", L(msg, client), false, {client})
					client.ixNextLeechWarning = CurTime() + 15
				end
			elseif (!inLeechWarningZone and wasInLeechWarningZone) then
				client.ixInLeechWarningZone = false
			end

			-- Handle attack/NPC spawning
			if (isLeechArea and client:Alive()) then
				if (bHasVJLeech) then
					self:SpawnLeechSwarm(client)
				else
					self:HurtByLeeches(client)
				end
			else
				-- Not in leech area or dead, clean up NPCs if no one else is near
				if (client.ixLeechSwarm and #client.ixLeechSwarm > 0) then
					local bKeepActive = false
					
					-- Check if any other living player is close enough to keep these NPCs
					if (!client:Alive()) then
						for _, other in ipairs(ents.FindInSphere(client:GetPos(), 300)) do
							if (other:IsPlayer() and other:Alive() and other != client) then
								bKeepActive = true
								break
							end
						end
					end

					if (!bKeepActive) then
						self:RemoveLeechSwarm(client)
					end
				end
			end
		end
	end)
end

function PLUGIN:HurtByLeeches(client)
	local damageInfo = DamageInfo()
	damageInfo:SetDamage(1)
	damageInfo:SetDamageType(DMG_SLASH)
	damageInfo:SetAttacker(game.GetWorld())
	damageInfo:SetInflictor(game.GetWorld())
	
	client:TakeDamageInfo(damageInfo)
	client:EmitSound(leechSounds[math.random(#leechSounds)])
	
	-- Visual punch
	client:ViewPunch(Angle(math.Rand(-5, 5), math.Rand(-5, 5), math.Rand(-5, 5)))
end

ix.command.Add("DebugLeech", {
	description = "Check current leech status.",
	adminOnly = true,
	OnRun = function(self, client)
		local areaID = client:GetArea()
		local waterLevel = client:WaterLevel()
		local area = ix.area.stored[areaID]
		local hasLeeches = area and area.properties and area.properties.leeches or false

		client:ChatPrint("--- Leech Debug ---")
		client:ChatPrint("Current Area: " .. tostring(areaID))
		client:ChatPrint("Water Level: " .. tostring(waterLevel) .. " (Need >= 2)")
		client:ChatPrint("Area has Leeches: " .. tostring(hasLeeches))
		client:ChatPrint("In Noclip: " .. tostring(client:GetMoveType() == MOVETYPE_NOCLIP))
		client:ChatPrint("-------------------")
	end
})

ix.command.Add("AreaLeech", {
	description = "Toggle leeches in the current area.",
	adminOnly = true,
	OnRun = function(self, client)
		local areaID = client:GetArea()

		if (!client:IsInArea() or !areaID or areaID == "") then
			return "You are not in a valid area!"
		end

		local areaInfo = ix.area.stored[areaID]
		if (!areaInfo) then
			return "Area info not found!"
		end

		areaInfo.properties.leeches = not areaInfo.properties.leeches

		-- Network the change to all clients
		net.Start("ixAreaAdd")
			net.WriteString(areaID)
			net.WriteString(areaInfo.type)
			net.WriteVector(areaInfo.startPosition)
			net.WriteVector(areaInfo.endPosition)
			net.WriteTable(areaInfo.properties)
		net.Broadcast()

		-- Save the area plugin data
		local areaPlugin = ix.plugin.list["area"]
		if (areaPlugin) then
			areaPlugin:SaveData()
		end

		if (areaInfo.properties.leeches) then
			return "Leeches enabled in area: " .. areaID
		else
			return "Leeches disabled in area: " .. areaID
		end
	end
})
