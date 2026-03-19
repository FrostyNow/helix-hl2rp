Schema.npcClassLists = Schema.npcClassLists or {}

Schema.npcClassLists.combine = {
	["npc_combine_s"] = true,
	["npc_helicopter"] = true,
	["npc_metropolice"] = true,
	["npc_manhack"] = true,
	["npc_combinedropship"] = true,
	["npc_rollermine"] = true,
	["npc_stalker"] = true,
	["npc_turret_floor"] = true,
	["npc_combinegunship"] = true,
	["npc_cscanner"] = true,
	["npc_clawscanner"] = true,
	["npc_strider"] = true,
	["npc_hunter"] = true,
	["npc_cremator"] = true,
	["npc_turret_ceiling"] = true,
	["npc_turret_ground"] = true,
	["npc_combine_camera"] = true,
	["combine_mine"] = true,
	["mbn_apc_manager"] = true,
	["hl2van_apcdriver_playermade"] = true,

	["npc_vj_hlvr_suppressor"] = true,
	["npc_vj_hlvr_captain"] = true,
	["npc_vj_hlvr_heavy"] = true,
	["npc_vj_hlvr_grunt"] = true,
	["npc_vj_hlvr_grunt_police"] = true,
	["npc_combine_sniper"] = true,
	["hl2van_apcdriver_playermade"] = true,
	["npc_vj_hlr2_com_civilp"] = true,
	["npc_vj_hlr2b_com_civilp_elite"] = true,
	["npc_vj_hlr2_com_sentry"] = true,
	["npc_vj_hlr2_com_elite"] = true,
	["npc_vj_hlr2_com_engineer"] = true,
	["npc_vj_hlr2_com_medic"] = true,
	["npc_vj_hlr2_com_prospekt"] = true,
	["npc_vj_hlr2_com_prospekt_sg"] = true,
	["npc_vj_hlr2_com_shotgunner"] = true,
	["npc_vj_hlr2_com_sniper"] = true,
	["npc_vj_hlr2b_com_elite_sniper"] = true,
	["npc_vj_hlr2_com_soldier"] = true,
	["npc_vj_hlr2b_com_soldier"] = true,
	["npc_vj_c_officer4"] = true,
	["npc_vj_c_officer6"] = true,
	["npc_vj_medicp"] = true,
	["npc_vj_novap"] = true,
	["npc_vj_c_officer1"] = true,
	["npc_vj_c_officer3"] = true,
	["npc_vj_c_officer"] = true,
	["npc_vj_c_officer2"] = true,
	["npc_vj_c_officer5"] = true
}

Schema.npcClassLists.rebel = {
	["npc_citizen"] = true,
	["npc_vortigaunt"] = true,
	["npc_alyx"] = true,
	["npc_barney"] = true,
	["npc_turret_floor_resistance"] = true,
	["npc_rollermine_hacked"] = true,
	["npc_fisherman"] = true,
	["npc_eli"] = true,
	["npc_odessa"] = true,
	["npc_kleiner"] = true,
	["npc_magnusson"] = true,
	["npc_mossman"] = true,
	["npc_dog"] = true,
	["npc_sniper_rebel"] = true,
	["npc_vj_hlr2_alyx"] = true,
	["npc_vj_hlr2_barney"] = true,
	["npc_vj_hlr2_citizen"] = true,
	["npc_vj_hlr2_father_grigori"] = true,
	["npc_vj_hlr2b_merkava"] = true,
	["npc_vj_hlr2_rebel"] = true,
	["npc_vj_hlr2_rebel_engineer"] = true,
	["npc_vj_hlr2_refugee"] = true,
	["npc_vj_hlr2_res_sentry"] = true
}

Schema.npcClassLists.hostile = {
	["npc_zombie"] = true,
	["npc_zombie_torso"] = true,
	["npc_fastzombie"] = true,
	["npc_fastzombie_torso"] = true,
	["npc_poisonzombie"] = true,
	["npc_headcrab"] = true,
	["npc_headcrab_fast"] = true,
	["npc_headcrab_black"] = true,
	["npc_antlion"] = true,
	["npc_antlionguard"] = true,
	["npc_antlion_template_maker"] = true,
	["npc_antlion_grub"] = true
}

Schema.antiCitizenModelPatterns = {
	"models/humans/group03",
	"models/humans/group03m",
	"models/player/group03",
	"models/player/group03m",
	"models/humans/barney",
	"models/humans/alyx",
	"models/humans/mossman",
	"models/humans/eli",
	"models/monk"
}

function Schema:GetNPCClass(npc)
	if (!IsValid(npc) or !npc:IsNPC()) then
		return ""
	end

	return string.lower(npc:GetClass() or "")
end

function Schema:IsCombineNPC(npc)
	local class = self:GetNPCClass(npc)

	if (!self.npcClassLists.combine[class]) then
		return false
	end

	if (class == "npc_turret_floor" and (npc:GetSkin() == 1 or npc:GetSkin() == 2)) then
		return false
	end

	return true
end

function Schema:IsAntiCitizenModeledNPC(npc)
	local model = string.lower(npc:GetModel() or "")

	for _, pattern in ipairs(self.antiCitizenModelPatterns) do
		if (string.find(model, pattern, 1, true)) then
			return true
		end
	end

	return false
end

function Schema:IsAntiCitizenNPC(npc)
	local class = self:GetNPCClass(npc)

	if (self.npcClassLists.rebel[class]) then
		return true
	end

	if (class == "npc_turret_floor" and (npc:GetSkin() == 1 or npc:GetSkin() == 2)) then
		return true
	end

	return self:IsAntiCitizenModeledNPC(npc)
end

function Schema:IsHostileNPC(npc)
	return self.npcClassLists.hostile[self:GetNPCClass(npc)] or false
end
