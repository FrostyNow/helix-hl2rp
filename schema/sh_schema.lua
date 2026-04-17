
Schema.name = "HL2 RP"
Schema.author = "nebulous.cloud"
Schema.description = "schemaDesc"

-- Include netstream
ix.util.Include("libs/thirdparty/sh_netstream2.lua")

ix.util.Include("sh_configs.lua")
ix.util.Include("sh_commands.lua")
ix.util.Include("sh_npcs.lua")

ix.util.Include("cl_schema.lua")
ix.util.Include("cl_hooks.lua")
ix.util.Include("sh_hooks.lua")
ix.util.Include("sh_voices.lua")
ix.util.Include("sv_schema.lua")
ix.util.Include("sv_hooks.lua")

ix.util.Include("meta/sh_player.lua")
ix.util.Include("meta/sv_player.lua")
ix.util.Include("meta/sh_character.lua")

ix.flag.Add("b", "Access to edit your own bodygroups.")
ix.flag.Add("s", "Access to edit your own skin.")
ix.flag.Add("C", "Access to equip gears to transfer to Conscript faction.")
ix.flag.Add("M", "Access to equip gears to transfer to Metropolice faction.")

-- Metrocop
ix.anim.SetModelClass("models/eliteghostcp.mdl", "metrocop")
ix.anim.SetModelClass("models/eliteshockcp.mdl", "metrocop")
ix.anim.SetModelClass("models/leet_police2.mdl", "metrocop")
ix.anim.SetModelClass("models/sect_police2.mdl", "metrocop")
ix.anim.SetModelClass("models/policetrench.mdl", "metrocop")
ix.anim.SetModelClass("models/dpfilms/metropolice/hdpolice.mdl", "metrocop")
ix.anim.SetModelClass("models/dpfilms/metropolice/hl2concept.mdl", "metrocop")
ix.anim.SetModelClass("models/dpfilms/metropolice/policetrench.mdl", "metrocop")
ix.anim.SetModelClass("models/metropolice/leet_police_v2.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/female_01.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/female_02.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/female_03.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/female_04.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/female_06.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/female_07.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/female_11.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/female_17.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/female_18.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/female_19.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/female_24.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/male_01.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/male_02.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/male_03.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/male_04.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/male_05.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/male_06.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/male_07.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/male_08.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/male_09.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/male_10.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/male_11.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/male_15.mdl", "metrocop")
ix.anim.SetModelClass("models/conceptbine_policeforce/rnd/male_16.mdl", "metrocop")

-- Citizen Male
ix.anim.SetModelClass("models/humans/pandafishizens/male_01.mdl", "citizen_male")
ix.anim.SetModelClass("models/humans/pandafishizens/male_02.mdl", "citizen_male")
ix.anim.SetModelClass("models/humans/pandafishizens/male_03.mdl", "citizen_male")
ix.anim.SetModelClass("models/humans/pandafishizens/male_04.mdl", "citizen_male")
ix.anim.SetModelClass("models/humans/pandafishizens/male_05.mdl", "citizen_male")
ix.anim.SetModelClass("models/humans/pandafishizens/male_06.mdl", "citizen_male")
ix.anim.SetModelClass("models/humans/pandafishizens/male_07.mdl", "citizen_male")
ix.anim.SetModelClass("models/humans/pandafishizens/male_08.mdl", "citizen_male")
ix.anim.SetModelClass("models/humans/pandafishizens/male_09.mdl", "citizen_male")
ix.anim.SetModelClass("models/humans/pandafishizens/male_10.mdl", "citizen_male")
ix.anim.SetModelClass("models/humans/pandafishizens/male_11.mdl", "citizen_male")
ix.anim.SetModelClass("models/humans/pandafishizens/male_12.mdl", "citizen_male")
ix.anim.SetModelClass("models/humans/pandafishizens/male_15.mdl", "citizen_male")
ix.anim.SetModelClass("models/humans/pandafishizens/male_16.mdl", "citizen_male")
ix.anim.SetModelClass("models/npc/engineer_male.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/erdimnovest.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/ericnovest.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/joenovest.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/mikenovest.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/sandronovest.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/tednovest.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/vannovest.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/vancenovest.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/erdim.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/eric.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/joe.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/mike.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/sandro.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/ted.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/van.mdl", "citizen_male")
ix.anim.SetModelClass("models/wichacks/vance.mdl", "citizen_male")
ix.anim.SetModelClass("models/ddok1994/1980_hazmat.mdl", "citizen_male")

-- Citizen Female
ix.anim.SetModelClass("models/humans/pandafishizens/female_01.mdl", "citizen_female")
ix.anim.SetModelClass("models/humans/pandafishizens/female_02.mdl", "citizen_female")
ix.anim.SetModelClass("models/humans/pandafishizens/female_03.mdl", "citizen_female")
ix.anim.SetModelClass("models/humans/pandafishizens/female_04.mdl", "citizen_female")
ix.anim.SetModelClass("models/humans/pandafishizens/female_06.mdl", "citizen_female")
ix.anim.SetModelClass("models/humans/pandafishizens/female_07.mdl", "citizen_female")
ix.anim.SetModelClass("models/humans/pandafishizens/female_11.mdl", "citizen_female")
ix.anim.SetModelClass("models/humans/pandafishizens/female_17.mdl", "citizen_female")
ix.anim.SetModelClass("models/humans/pandafishizens/female_18.mdl", "citizen_female")
ix.anim.SetModelClass("models/humans/pandafishizens/female_19.mdl", "citizen_female")
ix.anim.SetModelClass("models/humans/pandafishizens/female_24.mdl", "citizen_female")
ix.anim.SetModelClass("models/models/army/female_01.mdl", "citizen_female")
ix.anim.SetModelClass("models/models/army/female_02.mdl", "citizen_female")
ix.anim.SetModelClass("models/models/army/female_03.mdl", "citizen_female")
ix.anim.SetModelClass("models/models/army/female_04.mdl", "citizen_female")
ix.anim.SetModelClass("models/models/army/female_06.mdl", "citizen_female")
ix.anim.SetModelClass("models/models/army/female_07.mdl", "citizen_female")

-- Overwatch
ix.anim.SetModelClass("models/Combine_Soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/Combine_Soldier_PrisonGuard.mdl", "overwatch")
ix.anim.SetModelClass("models/Combine_Super_Soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/ninja/combine/combine_soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/ninja/combine/combine_soldier_prisonguard.mdl", "overwatch")
ix.anim.SetModelClass("models/ninja/combine/combine_super_soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/characters/combine_soldier/jqblk/combine_s.mdl", "overwatch")
ix.anim.SetModelClass("models/characters/combine_soldier/jqblk/combine_s_super.mdl", "overwatch")
ix.anim.SetModelClass("models/jq/hlvr/characters/combine/combine_captain/combine_captain_hlvr_npc.mdl", "overwatch")
ix.anim.SetModelClass("models/jq/hlvr/characters/combine/grunt/combine_grunt_hlvr_npc.mdl", "overwatch")
ix.anim.SetModelClass("models/jq/hlvr/characters/combine/heavy/combine_heavy_hlvr_npc.mdl", "overwatch")
ix.anim.SetModelClass("models/jq/hlvr/characters/combine/suppressor/combine_suppressor_hlvr_npc.mdl", "overwatch")
ix.anim.SetModelClass("models/nemez/combine_soldiers/combine_soldier_h.mdl", "overwatch")
ix.anim.SetModelClass("models/nemez/combine_soldiers/combine_soldier_nova_h.mdl", "overwatch")
ix.anim.SetModelClass("models/nemez/combine_soldiers/combine_soldier_elite_h.mdl", "overwatch")
ix.anim.SetModelClass("models/nemez/combine_soldiers/combine_soldier_elite_wpu_h.mdl", "overwatch")
ix.anim.SetModelClass("models/nemez/combine_soldiers/combine_soldier_coordinator_h.mdl", "overwatch")
ix.anim.SetModelClass("models/nemez/combine_soldiers/combine_soldier_border_patrol_h.mdl", "overwatch")
ix.anim.SetModelClass("models/nemez/combine_soldiers/combine_soldier_beta_h.mdl", "overwatch")
ix.anim.SetModelClass("models/nemez/combine_soldiers/combine_soldier_recon_h.mdl", "overwatch")
ix.anim.SetModelClass("models/nemez/combine_soldiers/combine_soldier_urban_h.mdl", "overwatch")
ix.anim.SetModelClass("models/nemez/combine_soldiers/combine_soldier_urban_shotgunner_h.mdl", "overwatch")
ix.anim.SetModelClass("models/armacham/security/enemy/guard_1.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_soldierproto.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_soldierproto_drt.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_super_soldierproto.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_super_soldierprotodirt.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_soldiersnow.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_soldieros.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_soldiergrunt.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_soldier2000.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_darkelite_soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_darkelite1_soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/jq/theparrygod/transition_period_overwatch_soldier_npc.mdl", "overwatch")
ix.anim.SetModelClass("models/cultist/hl_a/combine_commander/npc/combine_commander.mdl", "overwatch")
ix.anim.SetModelClass("models/transition/soldiers/ordinal-eow/ordinal-eow.mdl", "overwatch")

-- Player
ix.anim.SetModelClass("models/armacham/scientists/scientists_1.mdl", "player")

ALWAYS_RAISED["gmod_gphone"] = true
ALWAYS_RAISED["weapon_portalgun"] = true
ALWAYS_RAISED["weapon_bmxs_headcrabbed"] = true

game.AddAmmoType({
	name = "5.56x45mm",
	dmgtype = DMG_BULLET,
	tracer = TRACER_LINE_AND_WHIZ,
	maxcarry = 225
})
game.AddAmmoType({
	name = "7.62x51mm",
	dmgtype = DMG_BULLET,
	tracer = TRACER_LINE_AND_WHIZ,
	maxcarry = 225
})
-- game.AddAmmoType({
-- 	name = "9x19mm",
-- 	dmgtype = DMG_BULLET,
-- 	tracer = TRACER_LINE_AND_WHIZ
-- })
game.AddAmmoType({
	name = ".45 ACP",
	dmgtype = DMG_BULLET,
	tracer = TRACER_LINE_AND_WHIZ,
	maxcarry = 150
})
game.AddAmmoType({
	name = "5.45x39mm",
	dmgtype = DMG_BULLET,
	tracer = TRACER_LINE_AND_WHIZ,
	maxcarry = 225
})
game.AddAmmoType({
	name = "7.62x39mm",
	dmgtype = DMG_BULLET,
	tracer = TRACER_LINE_AND_WHIZ,
	maxcarry = 225
})
-- game.AddAmmoType({
-- 	name = "9x18mm",
-- 	dmgtype = DMG_BULLET,
-- 	tracer = TRACER_LINE_AND_WHIZ
-- })
-- game.AddAmmoType({
-- 	name = "12 Gauge",
-- 	dmgtype = DMG_BUCKSHOT,
-- 	tracer = TRACER_LINE_AND_WHIZ
-- })
-- game.AddAmmoType({
-- 	name = ".357 Magnum",
-- 	dmgtype = DMG_BULLET,
-- 	tracer = TRACER_LINE_AND_WHIZ
-- })
game.AddAmmoType({
	name = "7.62x25mm",
	dmgtype = DMG_BULLET,
	tracer = TRACER_LINE_AND_WHIZ,
	maxcarry = 225
})
game.AddAmmoType({
	name = "Flares",
	dmgtype = DMG_BURN,
	tracer = TRACER_NONE,
	maxcarry = 5
})
game.AddAmmoType({
	name = "20x28mm grenade",
	dmgtype = DMG_BLAST,
	tracer = TRACER_NONE,
	maxcarry = 3
})
game.AddAmmoType({
	name = "Combine Battery",
	dmgtype = DMG_BULLET,
	tracer = TRACER_NONE,
	maxcarry = 150
})

ix.ammo.Register("5.56x45mm")
ix.ammo.Register("7.62x51mm")
-- ix.ammo.Register("9x19mm")
ix.ammo.Register(".45 ACP")
ix.ammo.Register("5.45x39mm")
ix.ammo.Register("7.62x39mm")
-- ix.ammo.Register("9x18mm")
-- ix.ammo.Register("12 Gauge")
-- ix.ammo.Register(".357 Magnum")
ix.ammo.Register("7.62x25mm")
ix.ammo.Register("Flares")
ix.ammo.Register("20x28mm grenade")
ix.ammo.Register("Combine Battery")

function Schema:ZeroNumber(number, length)
	local amount = math.max(0, length - string.len(number))
	return string.rep("0", amount)..tostring(number)
end

Schema.combineNameData = Schema.combineNameData or {
	MPF = {
		defaultRank = "RCT",
		pattern = "^([^:]*17):MPF%-([%w]+)%.([A-Z]+):([1-9])$",
		legacyPattern = "^([^:]*17):MPF%-([%w]+)%.([A-Z]+):(%d+)$",
		callsigns = {
			"DEFENDER", "HERO", "JURY", "KING", "LINE", "PATROL", "QUICK", "ROLLER",
			"STICK", "TAP", "UNION", "VICTOR", "XRAY", "YELLOW", "VICE"
		},
		unitRanks = {
			["05"] = true,
			["04"] = true,
			["03"] = true,
			["02"] = true,
			["01"] = true,
			["i5"] = true,
			["i4"] = true,
			["i3"] = true,
			["i2"] = true,
			["i1"] = true
		},
		eliteRanks = {
			EpU = true,
			OfC = true,
			DvL = true,
			SeC = true,
			CmD = true
		},
		orderedRanks = {"RCT", "i5", "i4", "i3", "i2", "i1", "EpU", "OfC", "DvL", "SeC", "CmD"}
	},
	OTA = {
		defaultRank = "OWS",
		pattern = "^OTA%.([%w]+)%-([A-Z]+):([1-9])$",
		legacyPattern = "^OTA%.([%w]+)%-([A-Z]+):(%d+)$",
		callsigns = {
			"LEADER", "FLASH", "RANGER", "HUNTER", "BLADE", "HAMMER", "SWEEPER", "SWIFT",
			"FIST", "SWORD", "SAVAGE", "TRACKER", "SLASH", "RAZOR", "STAB", "SPEAR",
			"STRIKER", "DAGGER"
		},
		randomCallsigns = {
			"FLASH", "RANGER", "HUNTER", "BLADE", "HAMMER", "SWEEPER", "SWIFT",
			"FIST", "SWORD", "SAVAGE", "TRACKER", "SLASH", "RAZOR", "STAB", "SPEAR",
			"STRIKER", "DAGGER"
		},
		orderedRanks = {"OWS", "SGS", "EOW"}
	}
}

local function GetCombineNameData(branch)
	return Schema.combineNameData[branch]
end

function Schema:GetCombineNameInfo(text)
	if (!isstring(text) or text == "") then
		return nil
	end

	for branch, data in pairs(self.combineNameData) do
		local captures = {text:match(data.pattern)}
		local prefix, rank, callsign, number

		if (#captures == 4) then
			prefix, rank, callsign, number = unpack(captures)
		elseif (#captures == 3) then
			rank, callsign, number = unpack(captures)
		end

		if (rank) then
			number = tonumber(number)

			return {
				branch = branch,
				rank = rank,
				callsign = callsign,
				number = number,
				prefix = prefix,
				unitID = string.format("%s-%d", callsign, number),
				isLegacy = false
			}
		end

		captures = {text:match(data.legacyPattern)}

		if (#captures == 4) then
			prefix, rank, callsign, number = unpack(captures)
		elseif (#captures == 3) then
			rank, callsign, number = unpack(captures)
		end

		if (rank) then
			local legacyNumber = tostring(number)
			local collapsed = tonumber(string.sub(legacyNumber, -1)) or 0

			return {
				branch = branch,
				rank = rank,
				callsign = callsign,
				number = collapsed,
				prefix = prefix,
				legacyNumber = legacyNumber,
				unitID = string.format("%s-%s", callsign, legacyNumber),
				isLegacy = true
			}
		end
	end

	return nil
end

function Schema:GetCombineRank(text)
	local info = self:GetCombineNameInfo(text)

	return info and info.rank or nil
end

function Schema:GetCombineUnitID(value)
	local text = value

	if (IsValid(value) and value:IsPlayer()) then
		text = value:Name()
	end

	local info = self:GetCombineNameInfo(text)

	if (info) then
		return info.unitID, info
	end

	if (isstring(text)) then
		return text:match("%d%d%d%d?%d?") or "???", nil
	end

	return "???", nil
end

function Schema:FormatCombineName(branch, rank, callsign, number, prefix)
	local data = GetCombineNameData(branch)

	if (!data) then
		return nil
	end

	rank = rank or data.defaultRank
	callsign = string.upper(callsign or table.Random(data.randomCallsigns or data.callsigns) or "UNKNOWN")
	number = math.Clamp(math.floor(tonumber(number) or math.random(1, 9)), 1, 9)

	if (branch == "MPF") then
		return string.format("%s:MPF-%s.%s:%d", prefix or "c̄17", rank, callsign, number)
	end

	if (branch == "OTA") then
		return string.format("OTA.%s-%s:%d", rank, callsign, number)
	end
end

function Schema:NormalizeCombineName(text, branchOverride)
	local info = self:GetCombineNameInfo(text)

	if (!info) then
		return text
	end

	if (!info.isLegacy and (!branchOverride or branchOverride == info.branch)) then
		return text
	end

	local number = info.number

	if (number == nil or number < 1 or number > 9) then
		local source = tostring(info.legacyNumber or "")
		number = tonumber(string.sub(source, -1)) or math.random(1, 9)
	end

	return self:FormatCombineName(branchOverride or info.branch, info.rank, info.callsign, number, info.prefix)
end

function Schema:IsCombineRank(text, rank)
	local info = self:GetCombineNameInfo(text)

	if (info) then
		return info.rank == rank
	end

	if (!isstring(text) or !isstring(rank)) then
		return false
	end

	return text:find("%f[%w]" .. rank .. "%f[%W]") != nil
end

Schema.conscriptRanks = Schema.conscriptRanks or {
	{
		id = "basic",
		ko = "훈련병",
		en = "Pvt.",
		aliases = {"pvt", "훈련병"}
	},
	{
		id = "private",
		ko = "이병",
		en = "Pv2.",
		aliases = {"secondclass", "pv2", "이병"}
	},
	{
		id = "firstclass",
		ko = "일병",
		en = "Pfc.",
		aliases = {"pfc", "lcpl", "lancecorporal", "일병"}
	},
	{
		id = "corporal",
		ko = "상병",
		en = "Cpl.",
		aliases = {"cpl", "상병"}
	},
	{
		id = "sergeant",
		ko = "병장",
		en = "Sgt.",
		aliases = {"sgt", "병장"}
	},
	{
		id = "staffsergeant",
		ko = "하사",
		en = "SSG.",
		aliases = {"ssgt", "하사"}
	},
	{
		id = "seniorsergeant",
		ko = "중사",
		en = "SFC.",
		aliases = {"sfc", "중사"}
	},
	{
		id = "mastersergeant",
		ko = "상사",
		en = "MSG.",
		aliases = {"msgt", "상사"}
	},
	{
		id = "sergeantmajor",
		ko = "원사",
		en = "SGM.",
		aliases = {"sgm", "원사"}
	},
	{
		id = "2ndlt",
		ko = "소위",
		en = "2Lt.",
		aliases = {"2lt", "2nd lt", "소위"}
	},
	{
		id = "1stlt",
		ko = "중위",
		en = "1Lt.",
		aliases = {"1lt", "1st lt", "중위"}
	},
	{
		id = "capt",
		ko = "대위",
		en = "Capt.",
		aliases = {"cpt", "captain", "대위"}
	}
}

Schema.conscriptRankLookup = Schema.conscriptRankLookup or {}

for _, data in ipairs(Schema.conscriptRanks) do
	Schema.conscriptRankLookup[data.id] = data

	for _, alias in ipairs(data.aliases or {}) do
		Schema.conscriptRankLookup[string.Trim(string.lower(alias:gsub("%.$", "")))] = data
	end
end

function Schema:GetDefaultConscriptRank()
	return self.conscriptRanks[1] and self.conscriptRanks[1].id or "private"
end

function Schema:GetConscriptRankData(value)
	if (istable(value) and value.id) then
		return value
	end

	local key = isstring(value) and string.Trim(string.lower(value:gsub("%.$", ""))) or nil

	if (key and key != "") then
		return self.conscriptRankLookup[key] or self.conscriptRankLookup[value]
	end

	return self.conscriptRanks[1]
end

function Schema:GetConscriptRankDataFromText(text)
	if (!isstring(text)) then
		return nil
	end

	local trimmed = string.Trim(text)
	local firstWord = trimmed:match("^([^%.]+%.?)")

	if (firstWord) then
		local key = string.lower(string.Trim(firstWord:gsub("%.", "")))
		return self.conscriptRankLookup[key]
	end

	return nil
end

function Schema:IsEnglishPersonalName(name)
	if (!isstring(name)) then
		return false
	end

	name = string.Trim(name)

	if (name == "") then
		return false
	end

	-- Added quotes and parentheses commonly used in RP names
	return name:find("[A-Za-z]") != nil and name:find("^[A-Za-z%s%-%.'`\"%(%)]+$") != nil
end

function Schema:ExtractConscriptBaseName(text)
	if (!isstring(text)) then
		return ""
	end

	local trimmed = string.Trim(text)
	local firstWord = trimmed:match("^([^%.]+%.?)")

	if (firstWord) then
		local rankData = self:GetConscriptRankDataFromText(firstWord)

		if (rankData) then
			local result = string.Trim(trimmed:sub(#firstWord + 1))

			if (result != "") then
				return result
			end
		end
	end

	return trimmed
end

function Schema:FormatConscriptName(baseName, rank)
	local rankData = self:GetConscriptRankData(rank) or self.conscriptRanks[1]
	baseName = self:ExtractConscriptBaseName(baseName or "")

	if (baseName == "") then
		-- Default to the Rank Name if it's the only thing present.
		-- We use rankData.en as a safe default for internal name storage unless it looks like Korean.
		return rankData.en
	end

	if (self:IsEnglishPersonalName(baseName)) then
		-- English names use a space after the rank (which usually includes a dot)
		return string.format("%s %s", rankData.en, baseName)
	end

	-- Korean names use a dot and space after the rank
	return string.format("%s. %s", rankData.ko, baseName)
end

function Schema:CanPromote(client)
	if (client:IsAdmin()) then return true end

	local character = client:GetCharacter()
	if (!character) then return false end

	local faction = client:Team()

	if (faction == FACTION_ADMIN) then return true end

	if (faction == FACTION_MPF) then
		local rank = self:GetCombineRank(client:Name())
		if (rank and self.combineNameData.MPF.eliteRanks[rank]) then
			return true
		end
	end

	if (faction == FACTION_OTA) then
		local rank = self:GetCombineRank(client:Name())
		if (rank == "EOW") then
			return true
		end
	end

	if (faction == FACTION_CONSCRIPT) then
		local rank = character:GetData("conscriptRank")
		if (rank == "2ndlt" or rank == "1stlt" or rank == "capt") then
			return true
		end
	end

	return false
end

function Schema:Promote(targetChar, client)
	local faction = targetChar:GetFaction()

	if (faction == FACTION_MPF or faction == FACTION_OTA) then
		local branch = (faction == FACTION_MPF) and "MPF" or "OTA"
		local data = self.combineNameData[branch]
		local info = self:GetCombineNameInfo(targetChar:GetName())

		if (info) then
			local currentRank = info.rank
			local index = 0

			for k, v in ipairs(data.orderedRanks) do
				-- Support legacy 05-01 ranks by treating them as i5-i1 during promotion lookup
				if (v == currentRank or v:gsub("^i", "0") == currentRank) then
					index = k
					break
				end
			end

			if (index > 0 and index < #data.orderedRanks) then
				local newRank = data.orderedRanks[index + 1]
				local newName = self:FormatCombineName(branch, newRank, info.callsign, info.number)

				targetChar:SetName(newName)
				self:SyncCombineClass(targetChar, newName)
				return true, newRank
			end
		end
	elseif (faction == FACTION_CONSCRIPT) then
		local currentRank = targetChar:GetData("conscriptRank") or self:GetDefaultConscriptRank()
		local index = 0

		for k, v in ipairs(self.conscriptRanks) do
			if (v.id == currentRank) then
				index = k
				break
			end
		end

		if (index > 0 and index < #self.conscriptRanks) then
			local rankData = self.conscriptRanks[index + 1]
			local conscriptFaction = ix.faction.indices[FACTION_CONSCRIPT]

			if (conscriptFaction) then
				conscriptFaction:SetConscriptRank(targetChar, rankData.id)
				conscriptFaction:SetDisplayedName(targetChar, conscriptFaction:GetBaseName(targetChar))

				local player = targetChar:GetPlayer()
				if (IsValid(player)) then
					local state = conscriptFaction:GetUniformState(targetChar)
					if (state.active) then
						state.dutyName = conscriptFaction:GetFormattedName(targetChar, state.originalName)
						conscriptFaction:SetUniformState(targetChar, state)
					end
				end

				return true, rankData.ko
			end
		end
	end

	return false
end

function Schema:Demote(targetChar, client)
	local faction = targetChar:GetFaction()

	if (faction == FACTION_MPF or faction == FACTION_OTA) then
		local branch = (faction == FACTION_MPF) and "MPF" or "OTA"
		local data = self.combineNameData[branch]
		local info = self:GetCombineNameInfo(targetChar:GetName())

		if (info) then
			local currentRank = info.rank
			local index = 0

			for k, v in ipairs(data.orderedRanks) do
				-- Support legacy 05-01 ranks by treating them as i5-i1 during demotion lookup
				if (v == currentRank or v:gsub("^i", "0") == currentRank) then
					index = k
					break
				end
			end

			if (index > 1) then
				local newRank = data.orderedRanks[index - 1]
				local newName = self:FormatCombineName(branch, newRank, info.callsign, info.number)

				targetChar:SetName(newName)
				self:SyncCombineClass(targetChar, newName)
				return true, newRank
			end
		end
	elseif (faction == FACTION_CONSCRIPT) then
		local currentRank = targetChar:GetData("conscriptRank") or self:GetDefaultConscriptRank()
		local index = 0

		for k, v in ipairs(self.conscriptRanks) do
			if (v.id == currentRank) then
				index = k
				break
			end
		end

		if (index > 1) then
			local rankData = self.conscriptRanks[index - 1]
			local conscriptFaction = ix.faction.indices[FACTION_CONSCRIPT]

			if (conscriptFaction) then
				conscriptFaction:SetConscriptRank(targetChar, rankData.id)
				conscriptFaction:SetDisplayedName(targetChar, conscriptFaction:GetBaseName(targetChar))

				local player = targetChar:GetPlayer()
				if (IsValid(player)) then
					local state = conscriptFaction:GetUniformState(targetChar)
					if (state.active) then
						state.dutyName = conscriptFaction:GetFormattedName(targetChar, state.originalName)
						conscriptFaction:SetUniformState(targetChar, state)
					end
				end

				return true, rankData.ko
			end
		end
	end

	return false
end

function Schema:GetCombineClassFromRank(branch, rank)
	if (branch == FACTION_MPF) then
		branch = "MPF"
	elseif (branch == FACTION_OTA) then
		branch = "OTA"
	end

	if (branch == "MPF") then
		local data = GetCombineNameData("MPF")

		if (rank == "RCT") then
			return CLASS_MPR
		elseif (data and data.unitRanks[rank]) then
			return CLASS_MPU
		elseif (data and data.eliteRanks[rank]) then
			return CLASS_EMP
		end
	elseif (branch == "OTA") then
		if (rank == "OWS") then
			return CLASS_OWS
		elseif (rank == "SGS") then
			return CLASS_SGS or CLASS_OWS
		elseif (rank == "EOW") then
			return CLASS_EOW
		end
	end
end

function Schema:SyncCombineClass(target, name)
	local client = target
	local character = target

	if (IsValid(target) and target:IsPlayer()) then
		client = target
		character = target:GetCharacter()
	elseif (target and target.GetPlayer) then
		client = target:GetPlayer()
	end

	if (!character) then
		return
	end

	local info = self:GetCombineNameInfo(name or character:GetName())

	if (!info) then
		return
	end

	local class = self:GetCombineClassFromRank(info.branch, info.rank)

	if (class and character:GetClass() != class and IsValid(client)) then
		character:JoinClass(class)
	end
end

function Schema:GetCitizenID(target)
	local client = target
	local character = target

	if (IsValid(target) and target:IsPlayer()) then
		client = target
		character = target:GetCharacter()
	end

	if (IsValid(client)) then
		local cid = client:GetNetVar("cid")

		if (cid != nil and cid != "") then
			return tostring(cid)
		end
	end

	if (character and character.GetData) then
		local cid = character:GetData("cid")

		if (cid != nil and cid != "") then
			return tostring(cid)
		end
	end
end

function Schema:GetIdentificationItem(character)
	if (!character or !character.GetInventory) then
		return false
	end

	local inventory = character:GetInventory()

	if (!inventory or !inventory.GetItems) then
		return false
	end

	local item = inventory:HasItem("cid")

	if (item != false and item != nil) then
		return item
	end

	return false
end

function Schema:GetIdentificationData(character)
	if (!character) then
		return nil
	end

	local item = self:GetIdentificationItem(character)

	if (item) then
		return {
			name = item:GetData("name", character:GetName()),
			id = item:GetData("id", character:GetData("cid", "00000")),
			class = item:GetData("class", "Second Class Citizen"),
			title = item:GetData("title", "cidTitle"),
			item = item
		}
	end

	local implicitData = hook.Run("GetCharacterIdentificationData", character)

	if (istable(implicitData)) then
		implicitData.name = implicitData.name or character:GetName()
		implicitData.id = tostring(implicitData.id or character:GetData("cid", "00000"))
		implicitData.class = implicitData.class or "Second Class Citizen"
		implicitData.title = implicitData.title or "cidTitle"
		return implicitData
	end
end

function Schema:HasCharacterIdentification(character)
	return self:GetIdentificationData(character) != nil
end

function Schema:IsConceptCombine(client)
	if (!IsValid(client)) then return false end
	local model = client:GetModel():lower()
	return model:find("conceptbine_policeforce", 1, true)
end

local function IsUsableInventory(inventory)
	return istable(inventory) and inventory.GetItems and inventory.HasItem
end

function Schema:PlayerHasEquippedFlashlightBlocker(client)
	if (!IsValid(client)) then
		return false
	end

	local character = client:GetCharacter()
	local inventory = character and character:GetInventory()

	if (!IsUsableInventory(inventory)) then
		return false
	end

	for _, item in pairs(inventory:GetItems()) do
		if (item:GetData("equip") and item.blocksFlashlight) then
			return true, item
		end
	end

	return false
end

function Schema:CanPlayerUseFlashlight(client)
	if (!IsValid(client) or client:IsRagdoll()) then
		return false
	end

	local character = client:GetCharacter()
	local inventory = character and character:GetInventory()

	if (!character or !IsUsableInventory(inventory)) then
		return false
	end

	if (IsValid(client.ixScn)) then
		return false
	end

	if (self:PlayerHasEquippedFlashlightBlocker(client)) then
		return false
	end

	if (client:Team() == FACTION_OTA) then
		return true
	end

	if (ix.item.list["flashlight"] == nil) then
		return true
	end

	return inventory:HasItem("flashlight")
end

if (SERVER) then
	function Schema:SyncCitizenID(client, character)
		if (!IsValid(client)) then
			return
		end

		character = character or client:GetCharacter()

		if (!character) then
			client:SetNetVar("cid", "")
			return
		end

		client:SetNetVar("cid", tostring(character:GetData("cid", "")))
	end

	function Schema:ForceFlashlightOff(client)
		if (!IsValid(client)) then
			return
		end

		if (client.GetNetVar and client:GetNetVar("flashlight", false)) then
			client:SetNetVar("flashlight", false)
		end

		client:Flashlight(false)
	end

	function Schema:RefreshFlashlight(client)
		if (!IsValid(client) or self:CanPlayerUseFlashlight(client)) then
			return
		end

		self:ForceFlashlightOff(client)
	end
end

function Schema:CanPlayerSeeCombineOverlay(client)
	if (!IsValid(client)) then
		return false
	end

	if (IsValid(client.ixScn)) then
		return true
	end

	if (!client:IsCombine()) then
		return false
	end

	local faction = client:Team()
	if (faction != FACTION_MPF and faction != FACTION_OTA) then
		return false
	end

	if (self:IsConceptCombine(client)) then
		local index = client:FindBodygroupByName("mask")

		return index != -1 and client:GetBodygroup(index) >= 1
	end

	return true
end

function Schema:IsCombineChatWrapped(text)
	if (!isstring(text)) then
		return false
	end

	text = string.Trim(text)

	return text:find("^<::%s*.-%s*::>$") != nil
end

function Schema:WrapCombineChatText(text)
	text = string.Trim(tostring(text or ""))

	if (self:IsCombineChatWrapped(text)) then
		return text
	end

	return string.format("<:: %s ::>", text)
end

function Schema:AppendCombineChatPunctuation(text)
	if (!isstring(text)) then
		return text
	end

	local inner = string.Trim(text):match("^<::%s*(.-)%s*::>$")

	if (!inner) then
		return text
	end

	local last = inner:sub(-1)

	if (last != "." and last != "!" and last != "?" and last != "-" and last != "\"") then
		inner = inner .. "."
	end

	return self:WrapCombineChatText(inner)
end

local function addNameColoredMessage(color, speaker, formatted)
	if (!IsValid(speaker)) then
		chat.AddText(color, formatted)
		return
	end

	local name = speaker:Name()
	local nameStart, nameEnd = formatted:find(name, 1, true)

	if (nameStart and nameEnd) then
		local beforeName = formatted:sub(1, nameStart - 1)
		local afterName = formatted:sub(nameEnd + 1)
		local classColor = speaker:GetClassColor()

		if (classColor) then
			chat.AddText(color, beforeName, classColor, name, color, afterName)
		else
			chat.AddText(color, beforeName, speaker, color, afterName)
		end
		
		return
	end

	chat.AddText(color, formatted)
end

do
	local CLASS = {}
	CLASS.color = Color(150, 100, 100)
	CLASS.format = "chatDispatchFormat"

	function CLASS:CanSay(speaker, text)
		if (!IsValid(speaker)) then
			return true
		end

		if (!speaker:IsDispatch()) then
			speaker:NotifyLocalized("notAllowed")

			return false
		end
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, L(self.format, text))
	end

	ix.chat.Register("dispatch", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(75, 150, 50)
	CLASS.format = "chatRadioFormat"

	function CLASS:CanHear(speaker, listener)
		local character = listener:GetCharacter()
		local inventory = character and character:GetInventory()
		local bHasRadio = false

		if (!character or !IsUsableInventory(inventory)) then
			return false
		end

		local speakerCharacter = IsValid(speaker) and speaker:GetCharacter() or nil

		if (!speakerCharacter) then
			return false
		end

		for k, v in pairs(inventory:GetItemsByUniqueID("handheld_radio", true)) do
			if (v:GetData("enabled", false) and speakerCharacter:GetData("frequency") == character:GetData("frequency")) then
				bHasRadio = true
				break
			end
		end

		return bHasRadio
	end

	function CLASS:OnChatAdd(speaker, text)
		local name = IsValid(speaker) and speaker:Name() or "Console"
		text = Schema:CanPlayerSeeCombineOverlay(speaker) and Schema:WrapCombineChatText(text) or text

		addNameColoredMessage(self.color, speaker, L(self.format, name, text))
	end

	ix.chat.Register("radio", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(255, 255, 175)
	CLASS.format = "chatRadioFormat"

	function CLASS:GetColor(speaker, text)
		if (LocalPlayer():GetEyeTrace().Entity == speaker) then
			return Color(175, 255, 175)
		end

		return self.color
	end

	function CLASS:CanHear(speaker, listener)
		if (ix.chat.classes.radio:CanHear(speaker, listener)) then
			return false
		end

		local chatRange = ix.config.Get("chatRange", 280)

		return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
	end

	function CLASS:OnChatAdd(speaker, text)
		local name = IsValid(speaker) and speaker:Name() or "Console"
		text = Schema:CanPlayerSeeCombineOverlay(speaker) and Schema:WrapCombineChatText(text) or text

		chat.AddText(self.color, L(self.format, name, text))
	end

	ix.chat.Register("radio_eavesdrop", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(175, 125, 100)
	CLASS.format = "chatRequestFormat"

	function CLASS:CanHear(speaker, listener)
		return listener:IsCombine() or speaker:Team() == FACTION_ADMIN
	end

	function CLASS:OnChatAdd(speaker, text)
		local name = hook.Run("GetCharacterName", speaker, "request") or (IsValid(speaker) and speaker:Name() or "Console")
		chat.AddText(self.color, L(self.format, name, text))
	end

	ix.chat.Register("request", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(175, 125, 100)
	CLASS.format = "chatRequestFormat"

	function CLASS:CanHear(speaker, listener)
		if (ix.chat.classes.request:CanHear(speaker, listener)) then
			return false
		end

		local chatRange = ix.config.Get("chatRange", 280)

		return (speaker:Team() == FACTION_CITIZEN and !listener:IsCombine())
		and (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
	end

	function CLASS:OnChatAdd(speaker, text)
		local name = hook.Run("GetCharacterName", speaker, "request_eavesdrop") or (IsValid(speaker) and speaker:Name() or "Console")
		chat.AddText(self.color, L(self.format, name, text))
	end

	ix.chat.Register("request_eavesdrop", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(150, 125, 175)
	CLASS.format = "chatBroadcastFormat"
	CLASS.prefix = {"/Broadcast", "/B"}

	function CLASS:CanSay(speaker, text)
		if (!IsValid(speaker)) then
			return true
		end

		if (speaker:IsRestricted()) then
			speaker:NotifyLocalized("notNow")

			return false
		end

		local address = "ix_broadcast_console"
		local range = 120 * 120
		local bCanBroadcast = false

		if (speaker:Team() == FACTION_ADMIN) then
			bCanBroadcast = true
		else
			for k, v in ipairs(ents.FindByClass(address)) do
				if (v:GetPos():DistToSqr(speaker:GetPos()) <= range) then
					bCanBroadcast = true
					break
				end
			end
		end

		if (!bCanBroadcast) then
			speaker:NotifyLocalized("notAllowed")

			return false
		end
	end

	function CLASS:OnChatAdd(speaker, text)
		local name = IsValid(speaker) and speaker:Name() or "Console"
		chat.AddText(self.color, L(self.format, name, text))
	end

	ix.chat.Register("broadcast", CLASS)
end

function ix.date.GetLocalizedTime(client)
	local langKey = SERVER and ix.option.Get(client, "language", "english") or ix.option.Get("language", "english")
	local langTable = ix.lang.stored[langKey] or ix.lang.stored["english"]

	local formatStr24 = (langTable and langTable["dateFormat24"]) or (ix.lang.stored["english"] and ix.lang.stored["english"]["dateFormat24"]) or "%A, %B %d, %Y. %H:%M"
	local formatStr12 = (langTable and langTable["dateFormat12"]) or (ix.lang.stored["english"] and ix.lang.stored["english"]["dateFormat12"]) or "%A, %B %d, %Y. %I:%M %p"

	local is24Hour
	if SERVER then
		is24Hour = ix.option.Get(client, "24hourTime", false)
	else
		is24Hour = ix.option.Get("24hourTime", false)
	end
	
	local formatStr = is24Hour and formatStr24 or formatStr12
	local formatted = ix.date.GetFormatted(formatStr)

	local days = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
	local months = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}

	local translate = SERVER and function(key) return L(key, client) end or function(key) return L(key) end

	for i = 1, #days do
		local localizedDay = translate(days[i])
		if localizedDay != days[i] then formatted = string.gsub(formatted, days[i], localizedDay) end
	end
	for i = 1, #months do
		local localizedMonth = translate(months[i])
		if localizedMonth != months[i] then formatted = string.gsub(formatted, months[i], localizedMonth) end
	end

	local localizedAM = translate("AM")
	if localizedAM != "AM" then formatted = string.gsub(formatted, "AM", localizedAM) end
	
	local localizedPM = translate("PM")
	if localizedPM != "PM" then formatted = string.gsub(formatted, "PM", localizedPM) end

	return formatted
end

function Schema:CanPlayerHoldObject(ply, ent)
	if IsValid(ent) and ent:GetClass() == "npc_turret_floor" then
		return true
	end
end