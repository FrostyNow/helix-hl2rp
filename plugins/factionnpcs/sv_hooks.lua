local bZBaseLoaded = (ZBaseInstalled == true)

-- Maps ixhl2rp faction to the corresponding ZBase faction string
local function GetZBaseFactionForClient(client)
	if (client:IsCombine() or client:Team() == FACTION_ADMIN or client:Team() == FACTION_CONSCRIPT) then
		return "combine"
	elseif (client:Team() == FACTION_CITIZEN or client:Team() == FACTION_VORTIGAUNT) then
		return "ally"
	end

	return "neutral"
end

-- Called when a player has spawned.
function PLUGIN:PlayerSpawn(client)
	self:UpdateRelations(client)

	if (bZBaseLoaded) then
		ZBaseSetFaction(client, GetZBaseFactionForClient(client))
	end
end

-- Called after a player has spawned an NPC.
function PLUGIN:PlayerSpawnedNPC(client, npc)
	self:UpdateAllRelations()
end

-- Called when an entity is created. Handles relationship setup for all recognized Combine and Rebel entities (NPCs and objects).
function PLUGIN:OnEntityCreated(entity)
	local class = entity:GetClass()

	-- Optimization: Only process entities that are listed in our faction classification tables.
	if (!Schema.npcClassLists.combine[class] and !Schema.npcClassLists.rebel[class] and !Schema.npcClassLists.scared[class]) then
		return
	end

	timer.Simple(0, function()
		if (!IsValid(entity) or !IsValid(self)) then return end

		for _, client in ipairs(player.GetAll()) do
			self:HandleNPCRelations(entity, client)
		end
	end)
end

-- A function to get whether or not an NPC belongs to the rebel faction.
function PLUGIN:IsNPCRebel(npc)
	return Schema:IsAntiCitizenNPC(npc)
end

-- A function to get whether or not an NPC belongs to the Combine faction.
function PLUGIN:IsNPCCombine(npc)
	return Schema:IsCombineNPC(npc)
end

function PLUGIN:HandleNPCRelations(ent, client)
	if (!IsValid(ent) or !IsValid(client)) then
		return
	end

	local bIsNPC = ent:IsNPC()
	local disposition

	if (self:IsNPCCombine(ent)) then
		if (client:IsCombine() or client:Team() == FACTION_ADMIN or client:Team() == FACTION_CONSCRIPT) then
			disposition = D_LI
		else
			disposition = D_HT
		end
	elseif (self:IsNPCRebel(ent)) then
		if (client:IsCombine() or client:Team() == FACTION_ADMIN or client:Team() == FACTION_CONSCRIPT) then
			disposition = D_HT
		else
			disposition = D_LI
		end
	elseif (Schema.npcClassLists.scared[ent:GetClass()]) then
		disposition = D_FR
	end

	if (disposition and bIsNPC) then
		ent:AddEntityRelationship(client, disposition, 99)

		if (ent.SetRelationshipMemory) then
			ent:SetRelationshipMemory(client, "override_disposition", disposition)
		end

		if (bZBaseLoaded and ent.IsZBaseNPC and ent.ZBASE_SetMutualRelationship) then
			ent:ZBASE_SetMutualRelationship(client, disposition)
		end

		local scanner = client:GetNetVar("ixScn")

		if (IsValid(scanner)) then
			ent:AddEntityRelationship(scanner, disposition, 99)

			if (ent.SetRelationshipMemory) then
				ent:SetRelationshipMemory(scanner, "override_disposition", disposition)
			end
		end
	end
end

function PLUGIN:ScannerPilotChanged(client, scanner)
	if (IsValid(client)) then
		self:UpdateRelations(client)
	end

	if (IsValid(scanner) and !IsValid(scanner:GetPilot())) then
		for _, v in ents.Iterator() do
			if (self:IsNPCCombine(v)) then
				if (v:IsNPC()) then
					v:AddEntityRelationship(scanner, D_LI, 99)

					if (v.SetRelationshipMemory) then
						v:SetRelationshipMemory(scanner, "override_disposition", D_LI)
					end
				end
			elseif (self:IsNPCRebel(v)) then
				if (v:IsNPC()) then
					v:AddEntityRelationship(scanner, D_HT, 99)

					if (v.SetRelationshipMemory) then
						v:SetRelationshipMemory(scanner, "override_disposition", D_HT)
					end
				end
			end
		end
	end
end

function PLUGIN:UpdateRelations(client)
	for _, v in ents.Iterator() do
		if (v:IsNPC() or v:GetClass() == "prop_vehicle_apc" or v:GetClass() == "combine_mine") then
			self:HandleNPCRelations(v, client)
		end
	end
end

function PLUGIN:UpdateAllRelations()
	local players = player.GetAll()

	for _, v in ents.Iterator() do
		if (v:IsNPC() or v:GetClass() == "prop_vehicle_apc" or v:GetClass() == "combine_mine") then
			for _, client in ipairs(players) do
				self:HandleNPCRelations(v, client)
			end
		end
	end
end


local nextCheck = 0

function PLUGIN:Think()
	if (nextCheck > CurTime()) then
		return
	end

	nextCheck = CurTime() + 0.5

	local scaredClasses = Schema.npcClassLists.scared
	if (!scaredClasses) then
		return
	end

	local handled = {}

	for _, client in ipairs(player.GetAll()) do
		if (!client:GetCharacter()) then
			continue
		end

		for _, ent in ipairs(ents.FindInSphere(client:GetPos(), 250)) do
			if (!ent:IsNPC() or !scaredClasses[ent:GetClass()] or handled[ent]) then
				continue
			end

			handled[ent] = true

			local class = ent:GetClass()

			if (class:find("pigeon") or class:find("seagull") or class:find("crow")) then
				if (!ent.ixIsFlyingAway) then
					ent:Fire("FlyAway")
					ent.ixIsFlyingAway = CurTime()
				end
			elseif (class:find("rat")) then
				ent:SetEnemy(client)
				ent:SetSchedule(SCHED_RUN_FROM_ENEMY)
				ent.ixIsFleeing = CurTime()
			end
		end
	end

	for _, ent in ents.Iterator() do
		if (!IsValid(ent) or !ent:IsNPC() or ent:Health() <= 0) then continue end

		if (ent.ixIsFlyingAway) then
			if (CurTime() - ent.ixIsFlyingAway > 20) then
				ent.ixIsFlyingAway = nil
				continue
			end

			local vel = ent:GetVelocity()
			local pos = ent:GetPos()

			local tr = util.TraceLine({
				start = pos,
				endpos = pos + vel:GetNormalized() * 20,
				filter = ent,
				mask = MASK_NPCWORLDSTATIC
			})

			if (tr.Hit) then
				ent:Kill()
				ent.ixIsFlyingAway = nil
			elseif (CurTime() - ent.ixIsFlyingAway > 1 and vel:LengthSqr() < 15^2) then
				ent:Kill()
				ent.ixIsFlyingAway = nil
			end
		end

		if (ent.ixIsFleeing and CurTime() - ent.ixIsFleeing > 3) then
			ent.ixIsFleeing = nil
		end
	end
end

hook.Add("UpdateAllRelations", "ixUpdateRelationsFix", function()
    if (PLUGIN) then
        PLUGIN:UpdateAllRelations()
    end
end)
