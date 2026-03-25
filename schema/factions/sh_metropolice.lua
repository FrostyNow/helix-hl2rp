
FACTION.name = "Metropolice Force"
FACTION.description = "A metropolice unit working as Civil Protection."
FACTION.color = Color(43, 64, 116)
FACTION.pay = 60
-- FACTION.models = {"models/dpfilms/metropolice/hdpolice.mdl"}
-- FACTION.weapons = {"ix_stunstick"}
FACTION.models = {}
FACTION.genderModels = {
	male = {
		"models/conceptbine_policeforce/rnd/male_01.mdl",
		"models/conceptbine_policeforce/rnd/male_02.mdl",
		"models/conceptbine_policeforce/rnd/male_03.mdl",
		"models/conceptbine_policeforce/rnd/male_04.mdl",
		"models/conceptbine_policeforce/rnd/male_05.mdl",
		"models/conceptbine_policeforce/rnd/male_06.mdl",
		"models/conceptbine_policeforce/rnd/male_07.mdl",
		"models/conceptbine_policeforce/rnd/male_08.mdl",
		"models/conceptbine_policeforce/rnd/male_09.mdl",
		"models/conceptbine_policeforce/rnd/male_10.mdl",
		"models/conceptbine_policeforce/rnd/male_11.mdl",
		"models/conceptbine_policeforce/rnd/male_15.mdl",
		"models/conceptbine_policeforce/rnd/male_16.mdl"
	},
	female = {
		"models/conceptbine_policeforce/rnd/female_01.mdl",
		"models/conceptbine_policeforce/rnd/female_02.mdl",
		"models/conceptbine_policeforce/rnd/female_03.mdl",
		"models/conceptbine_policeforce/rnd/female_04.mdl",
		"models/conceptbine_policeforce/rnd/female_06.mdl",
		"models/conceptbine_policeforce/rnd/female_07.mdl",
		"models/conceptbine_policeforce/rnd/female_11.mdl",
		"models/conceptbine_policeforce/rnd/female_17.mdl",
		"models/conceptbine_policeforce/rnd/female_18.mdl",
		"models/conceptbine_policeforce/rnd/female_19.mdl",
		"models/conceptbine_policeforce/rnd/female_24.mdl"
	}
}
-- Make model loading deterministic (Alphabetical Keys: female -> male)
for gender, models in SortedPairs(FACTION.genderModels) do
	for _, v in ipairs(models) do
		table.insert(FACTION.models, v)
	end
end

local UNIFORM_STATE_KEY = "mpfUniformState"
local DEFAULT_CITIZEN_FACTION = "citizen"

local function NormalizeModel(model)
	return isstring(model) and model:gsub("\\", "/"):lower() or ""
end

local function GetGenderFromModel(model)
	model = NormalizeModel(model)

	if (model:find("/female_", 1, true)) then
		return "female"
	end

	return "male"
end

function FACTION:GetUniformState(character)
	local state = character:GetData(UNIFORM_STATE_KEY, {})

	if (!istable(state)) then
		return {}
	end

	return table.Copy(state)
end

function FACTION:SetUniformState(character, state)
	character:SetData(UNIFORM_STATE_KEY, state)
end

function FACTION:IsUniformCitizenDuty(character)
	local state = self:GetUniformState(character)

	return state.active == true and (state.originalFaction == nil or state.originalFaction == DEFAULT_CITIZEN_FACTION)
end

function FACTION:ResolveDutyModel(character, citizenModel)
	local state = self:GetUniformState(character)
	local sourceModel = NormalizeModel(citizenModel or state.originalModel or character:GetModel())

	if (sourceModel:find("conceptbine_policeforce/rnd", 1, true) and table.HasValue(self.models, sourceModel)) then
		return sourceModel
	end

	local derivedModel = sourceModel:gsub("humans/pandafishizens", "conceptbine_policeforce/rnd")

	if (derivedModel != sourceModel and table.HasValue(self.models, derivedModel)) then
		return derivedModel
	end

	local gender = GetGenderFromModel(sourceModel)
	return self.genderModels[gender] and self.genderModels[gender][1] or self.models[1]
end

function FACTION:GetUniformReturnFaction(character)
	local state = self:GetUniformState(character)
	local faction = ix.faction.teams[state.originalFaction or DEFAULT_CITIZEN_FACTION]

	return faction and faction.index or FACTION_CITIZEN
end

FACTION.bodyGroups = {
	["facialhair"] = {
		name = "facial_hair",
		min = 0,
		max = 8,
		excludeModels = "female"
	},
	["lower gear"] = {
		name = "cp_belt",
		min = 1,
		max = 1
	}
}

FACTION.isDefault = false
FACTION.isGloballyRecognized = true
FACTION.runSounds = {[0] = "NPC_MetroPolice.RunFootstepLeft", [1] = "NPC_MetroPolice.RunFootstepRight"}

FACTION.canSeeWaypoints = true
FACTION.forcedName = true

function FACTION:OnCharacterCreated(client, character)
	local inventory = character:GetInventory()

	inventory:Add("smg1", 1)
	inventory:Add("smg1ammo", 2)
	inventory:Add("pistol", 1)
	inventory:Add("pistolammo", 2)
	inventory:Add("health_vial", 2)
	inventory:Add("stunstick", 1)
	inventory:Add("cp_vest_mpf", 1)
	inventory:Add("cp_mask", 1)
	inventory:Add("gasmask_filter", 1)
	inventory:Add("handheld_radio", 1)
	inventory:Add("bag", 1)
	inventory:Add("flashlight", 1)
	inventory:Add("zip_tie", 2)

	local groups = character:GetData("groups", {})

	for k, v in pairs({
		["lower gear"] = 1
	}) do
		local index = client:FindBodygroupByName(k)

		if (index > -1) then
			client:SetBodygroup(index, v)
			groups[index] = v
		end
	end

	character:SetData("groups", groups)
end

function FACTION:GetDefaultName(client)
	return Schema:FormatCombineName("MPF", "RCT")
end

function FACTION:OnTransferred(character)
	local state = self:GetUniformState(character)
	local client = character:GetPlayer()
	local name = character:GetName()

	if (!Schema:GetCombineNameInfo(name)) then
		name = self:GetDefaultName(client)
	end

	if (state.active) then
		state.dutyName = Schema:NormalizeCombineName(state.dutyName or name, "MPF")
		state.dutyModel = state.dutyModel or self:ResolveDutyModel(character, state.originalModel)
		state.dutyDescription = state.dutyDescription or self.description or "A metropolice unit working as Civil Protection."
		self:SetUniformState(character, state)

		character:SetName(state.dutyName)
		character:SetModel(state.dutyModel)
		character:SetDescription(state.dutyDescription)
		return
	end

	character:SetName(Schema:NormalizeCombineName(name, "MPF"))
	character:SetModel(self.models[1])
	character:SetDescription(self.description)
end

function FACTION:OnNameChanged(client, oldValue, value)
	local character = client:GetCharacter()
	local state = self:GetUniformState(character)

	if (state.active) then
		state.dutyName = value
		self:SetUniformState(character, state)
	end

	Schema:SyncCombineClass(client, value)
	client:SetArmor(Schema:IsCombineRank(value, "RCT") and 50 or 100)

	if (state.active) then
		state.dutyModel = character:GetModel()
		self:SetUniformState(character, state)
	end
end

function FACTION:OnDescriptionChanged(client, oldValue, value)
	local character = client:GetCharacter()
	local state = self:GetUniformState(character)

	if (state.active) then
		state.dutyDescription = value
		self:SetUniformState(character, state)
	end
end

function FACTION:ModifyPlayerStep(client, data)
	-- Don't replace sounds while climbing ladders or wading through water
	if data.ladder or data.submerged then
		return
	end

	-- Only replace running sounds
	if data.running then
		data.snd = data.foot and "NPC_MetroPolice.RunFootstepRight" or "NPC_MetroPolice.RunFootstepLeft"
		data.volume = data.volume * 0.6 -- Very loud otherwise
	end
end

FACTION_MPF = FACTION.index
