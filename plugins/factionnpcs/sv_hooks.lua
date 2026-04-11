-- Called when a player has spawned.
function PLUGIN:PlayerSpawn(client)
	self:UpdateRelations(client);
end

-- Called after a player has spawned an NPC.
function PLUGIN:PlayerSpawnedNPC(client, npc)
	self:UpdateAllRelations()
end

-- Called when an entity is created. Handles relationship setup for all recognized Combine and Rebel entities (NPCs and objects).
function PLUGIN:OnEntityCreated(entity)
	local class = entity:GetClass()

	-- Optimization: Only process entities that are listed in our faction classification tables.
	if (!Schema.npcClassLists.combine[class] and !Schema.npcClassLists.rebel[class]) then
		return
	end

	timer.Simple(0, function()
		if (IsValid(entity) and IsValid(self)) then
			for _, client in ipairs(player.GetAll()) do
				self:HandleNPCRelations(entity, client)
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
	end

	if (disposition and bIsNPC) then
		ent:AddEntityRelationship(client, disposition, 99)

		if (ent.SetRelationshipMemory) then
			ent:SetRelationshipMemory(client, "override_disposition", disposition)
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

hook.Add("UpdateAllRelations", "ixUpdateRelationsFix", function()
    if (PLUGIN) then
        PLUGIN:UpdateAllRelations()
    end
end)
