-- Called when a player has spawned.
function PLUGIN:PlayerSpawn(client)
	self:UpdateRelations(client);
end

-- Called after a player has spawned an NPC.
function PLUGIN:PlayerSpawnedNPC(client, npc)
	self:UpdateAllRelations()
end

-- Called after an NPC has spawned (including those spawned by other NPCs).
function PLUGIN:OnNPCSpawned(npc)
	timer.Simple(0, function()
		if (IsValid(npc) and IsValid(self)) then
			for _, client in ipairs(player.GetAll()) do
				self:HandleNPCRelations(npc, client)
			end
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

function PLUGIN:HandleNPCRelations(npc, client)
	if (!IsValid(npc) or !npc:IsNPC() or !IsValid(client)) then
		return
	end

	if (self:IsNPCCombine(npc)) then
		if (client:IsCombine() or client:Team() == FACTION_ADMIN or client:Team() == FACTION_CONSCRIPT) then
			npc:AddEntityRelationship(client, D_LI, 99)

			if (npc.SetRelationshipMemory) then
				npc:SetRelationshipMemory(client, "override_disposition", D_LI)
			end
		else
			npc:AddEntityRelationship(client, D_HT, 99)

			if (npc.SetRelationshipMemory) then
				npc:SetRelationshipMemory(client, "override_disposition", D_HT)
			end
		end
	elseif (self:IsNPCRebel(npc)) then
		if (client:IsCombine() or client:Team() == FACTION_ADMIN or client:Team() == FACTION_CONSCRIPT) then
			npc:AddEntityRelationship(client, D_HT, 99)

			if (npc.SetRelationshipMemory) then
				npc:SetRelationshipMemory(client, "override_disposition", D_HT)
			end
		else
			npc:AddEntityRelationship(client, D_LI, 99)

			if (npc.SetRelationshipMemory) then
				npc:SetRelationshipMemory(client, "override_disposition", D_LI)
			end
		end
	end
end

function PLUGIN:UpdateRelations(client)
	for _, v in ipairs(ents.GetAll()) do
		if (v:IsNPC()) then
			self:HandleNPCRelations(v, client)
		end
	end
end

function PLUGIN:UpdateAllRelations()
	for k, v in pairs(player.GetAll()) do
		self:UpdateRelations(v)
	end
end

hook.Add("UpdateAllRelations", "ixUpdateRelationsFix", function()
    if (PLUGIN) then
        PLUGIN:UpdateAllRelations()
    end
end)
