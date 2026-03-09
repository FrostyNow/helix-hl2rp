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

local combineNPCs = {
	"npc_combine_s",
	"npc_helicopter",
	"npc_metropolice",
	"npc_manhack",
	"npc_combinedropship",
	"npc_rollermine",
	"npc_stalker",
	"npc_turret_floor",
	"npc_combinegunship",
	"npc_cscanner",
	"npc_clawscanner",
	"npc_strider",
	"npc_hunter",
	"npc_cremator",
	"npc_turret_ceiling",
	"npc_turret_ground",
	"npc_combine_camera",
	"combine_mine",

	-- custom
	"npc_vj_hlvr_suppressor",
	"npc_vj_hlvr_captain",
	"npc_vj_hlvr_heavy",
	"npc_vj_hlvr_grunt",
	"npc_vj_hlvr_grunt_police",
	"npc_combine_sniper",
	"hl2van_apcdriver_playermade",
	"npc_vj_hlr2_com_civilp",
	"npc_vj_hlr2b_com_civilp_elite",
	"npc_vj_hlr2_com_sentry",
	"npc_vj_hlr2_com_elite",
	"npc_vj_hlr2_com_engineer",
	"npc_vj_hlr2_com_medic",
	"npc_vj_hlr2_com_prospekt",
	"npc_vj_hlr2_com_prospekt_sg",
	"npc_vj_hlr2_com_shotgunner",
	"npc_vj_hlr2_com_sniper",
	"npc_vj_hlr2b_com_elite_sniper",
	"npc_vj_hlr2_com_soldier",
	"npc_vj_hlr2b_com_soldier",
	"npc_vj_c_officer4",
	"npc_vj_c_officer6",
	"npc_vj_medicp",
	"npc_vj_novap",
	"npc_vj_c_officer1",
	"npc_vj_c_officer3",
	"npc_vj_c_officer",
	"npc_vj_c_officer2",
	"npc_vj_c_officer5",
	"npc_vj_hlvr_heavy",
	"npc_vj_hlvr_grunt",
	"npc_vj_hlvr_grunt_police",
	"npc_vj_hlvr_captain",
	"npc_vj_hlvr_suppressor",
}

local rebelNPCs = {
	"npc_citizen",
	"npc_vortigaunt",
	"npc_alyx",
	"npc_barney",
	"npc_turret_floor_resistance",
	"npc_rollermine_hacked",
	"npc_fisherman",
	"npc_eli",
	"npc_odessa",
	"npc_kleiner",
	"npc_magnusson",
	"npc_mossman",
	"npc_dog",

	--custom
	"npc_sniper_rebel",
	"npc_vj_hlr2_alyx",
	"npc_vj_hlr2_barney",
	"npc_vj_hlr2_citizen",
	"npc_vj_hlr2_father_grigori",
	"npc_vj_hlr2b_merkava",
	"npc_vj_hlr2_rebel",
	"npc_vj_hlr2_rebel_engineer",
	"npc_vj_hlr2_refugee",
	"npc_vj_hlr2_res_sentry"
}

-- A function to get whether or not an NPC belongs to the rebel faction.
function PLUGIN:IsNPCRebel(npc)
	if (table.HasValue(rebelNPCs, string.lower(npc:GetClass()))) then
		return true;
	else
		if (npc:GetClass() == "npc_turret_floor") and (npc:GetSkin() == 1 or npc:GetSkin() == 2) then
			return true;
		else
			return false;
		end
	end
end

-- A function to get whether or not an NPC belongs to the Combine faction.
function PLUGIN:IsNPCCombine(npc)
	if(table.HasValue(combineNPCs, string.lower(npc:GetClass()))) then
		if (npc:GetClass() == "npc_turret_floor") and (npc:GetSkin() == 1 or npc:GetSkin() == 2) then
			return false;
		else
			return true;
		end
	else
		return false;
	end
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