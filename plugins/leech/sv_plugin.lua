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

function PLUGIN:GetEntityArea(entity)
	local position = entity:GetPos() + entity:OBBCenter()

	for id, info in pairs(ix.area.stored) do
		if (position:WithinAABox(info.startPosition, info.endPosition)) then
			return id
		end
	end

	return ""
end

function PLUGIN:SpawnLeechSwarm(entity)
	entity.ixLeechSwarm = entity.ixLeechSwarm or {}

	-- Clean up dead/invalid NPCs in the swarm
	for i = #entity.ixLeechSwarm, 1, -1 do
		local npc = entity.ixLeechSwarm[i]
		if (!IsValid(npc) or !npc:Alive()) then
			table.remove(entity.ixLeechSwarm, i)
		end
	end

	-- Spawn up to 10 NPCs around the target
	if (#entity.ixLeechSwarm < 10) then
		local pos = entity:GetPos() + VectorRand(-50, 50)
		pos.z = pos.z - 10 -- Spawn slightly below

		local npc = ents.Create("npc_vj_hlr1_leech")
		if (IsValid(npc)) then
			npc.ixIgnoreSpawner = true
			npc:SetPos(pos)
			npc:SetAngles(Angle(0, math.random(0, 360), 0))
			npc:Spawn()
			npc:Activate()
			
			-- Force attack the target
			if (npc.VJ_AddEntityRelationship) then
				npc:VJ_AddEntityRelationship(entity, D_HT, 99)
			end
			npc:SetEnemy(entity)

			table.insert(entity.ixLeechSwarm, npc)
		end
	end
end

function PLUGIN:RemoveLeechSwarm(entity)
	if (entity.ixLeechSwarm) then
		for _, npc in pairs(entity.ixLeechSwarm) do
			if (IsValid(npc)) then
				npc:Remove()
			end
		end
		entity.ixLeechSwarm = {}
	end
end

function PLUGIN:InitializedPlugins()
	self.bHasVJLeech = list.Get("NPC")["npc_vj_hlr1_leech"] != nil

	timer.Create("ixLeechTick", 0.5, 0, function()
		local targets = {}

		for _, v in player.Iterator() do
			targets[#targets + 1] = v
		end

		for _, v in ipairs(ents.GetAll()) do
			if (v:IsNPC() and v:GetClass() != "npc_vj_hlr1_leech" and v:GetClass() != "npc_leech") then
				targets[#targets + 1] = v
			end
		end

		for _, entity in ipairs(targets) do
			if (!IsValid(entity)) then
				continue
			end

			local isPlayer = entity:IsPlayer()
			local isAlive = entity:Alive()

			if (isPlayer) then
				if (!entity:GetCharacter()) then continue end
				if (entity:GetMoveType() == MOVETYPE_NOCLIP) then continue end
			end

			local waterLevel = entity:WaterLevel()
			local areaID = isPlayer and entity:GetArea() or self:GetEntityArea(entity)
			local isLeechArea = false
			local inLeechWarningZone = false

			if (areaID and areaID != "") then
				local area = ix.area.stored[areaID]
				if (area and area.properties and area.properties.leeches) then
					if (waterLevel >= 1) then
						inLeechWarningZone = true
					end

					-- Smart attack logic
					if (isAlive) then
						if (!entity:IsOnGround() and waterLevel >= 2) then
							isLeechArea = true
						elseif (entity:IsOnGround() and waterLevel >= 3) then
							if (isPlayer and entity:Crouching()) then
								if (self:IsPointInWater(entity:GetPos() + Vector(0, 0, 72))) then
									isLeechArea = true
								end
							else
								isLeechArea = true
							end
						end
					end
				end
			end

			-- Warn the player
			if (isPlayer and isAlive) then
				local wasInLeechWarningZone = entity.ixInLeechWarningZone or false
				if (inLeechWarningZone and !wasInLeechWarningZone) then
					entity.ixInLeechWarningZone = true
					if ((entity.ixNextLeechWarning or 0) < CurTime()) then
						local msg = table.Random(leechWarnings)
						ix.chat.Send(entity, "it", L(msg, entity), false, {entity})
						entity.ixNextLeechWarning = CurTime() + 15
					end
				elseif (!inLeechWarningZone and wasInLeechWarningZone) then
					entity.ixInLeechWarningZone = false
				end
			end

			-- Handle attack/NPC spawning
			if (isLeechArea and isAlive) then
				if (self.bHasVJLeech) then
					self:SpawnLeechSwarm(entity)
				else
					self:HurtByLeeches(entity)
				end
			else
				-- Not in leech area or dead, clean up NPCs if no one else is near
				if (entity.ixLeechSwarm and #entity.ixLeechSwarm > 0) then
					local bKeepActive = false
					
					-- Check if any other living target (player or NPC) is close enough to keep these NPCs
					for _, other in ipairs(ents.FindInSphere(entity:GetPos(), 300)) do
						if (other == entity or !other:Alive()) then continue end
						
						if (other:IsPlayer()) then
							if (other:GetMoveType() != MOVETYPE_NOCLIP) then
								bKeepActive = true
								break
							end
						elseif (other:IsNPC()) then
							local class = other:GetClass()
							if (class != "npc_vj_hlr1_leech" and class != "npc_leech") then
								bKeepActive = true
								break
							end
						end
					end

					if (!bKeepActive) then
						self:RemoveLeechSwarm(entity)
					end
				end
			end
		end
	end)
end

function PLUGIN:HurtByLeeches(entity)
	local damageInfo = DamageInfo()
	damageInfo:SetDamage(1)
	damageInfo:SetDamageType(DMG_SLASH)
	damageInfo:SetAttacker(game.GetWorld())
	damageInfo:SetInflictor(game.GetWorld())
	
	entity:TakeDamageInfo(damageInfo)
	entity:EmitSound(leechSounds[math.random(#leechSounds)])
	
	-- Visual punch (players only)
	if (entity:IsPlayer()) then
		entity:ViewPunch(Angle(math.Rand(-5, 5), math.Rand(-5, 5), math.Rand(-5, 5)))
	end
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

function PLUGIN:EntityRemoved(entity)
	if (entity.ixLeechSwarm) then
		self:RemoveLeechSwarm(entity)
	end
end

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
