FACTION.name = "Conscript"
FACTION.description = "A regular human citizen enlisted as a soldier to Combine Overwatch."
FACTION.color = Color(77, 93, 83, 255)
FACTION.pay = 15
FACTION.isDefault = false
FACTION.isGloballyRecognized = false
FACTION.runSounds = {[0] = "NPC_MetroPolice.RunFootstepLeft", [1] = "NPC_MetroPolice.RunFootstepRight"}
FACTION.canSeeWaypoints = true
FACTION.models = {}
FACTION.genderModels = {
	male = {
		"models/wichacks/erdimnovest.mdl",
		"models/wichacks/ericnovest.mdl",
		"models/wichacks/joenovest.mdl",
		"models/wichacks/mikenovest.mdl",
		"models/wichacks/sandronovest.mdl",
		"models/wichacks/tednovest.mdl",
		"models/wichacks/vannovest.mdl",
		"models/wichacks/vancenovest.mdl",
	},
	female = {
		"models/models/army/female_01.mdl",
		"models/models/army/female_02.mdl",
		"models/models/army/female_03.mdl",
		"models/models/army/female_04.mdl",
		"models/models/army/female_06.mdl",
		"models/models/army/female_07.mdl"
	}
}

for _, models in SortedPairs(FACTION.genderModels) do
	for _, model in ipairs(models) do
		table.insert(FACTION.models, model)
	end
end

local UNIFORM_STATE_KEY = "conscriptUniformState"
local CONSCRIPT_RANK_KEY = "conscriptRank"
local DEFAULT_CITIZEN_FACTION = "citizen"
local nameSyncLocks = {}
local dutyModelFallbacks = {
	["models/humans/pandafishizens/male_01.mdl"] = "models/wichacks/vannovest.mdl",
	["models/humans/pandafishizens/male_02.mdl"] = "models/wichacks/tednovest.mdl",
	["models/humans/pandafishizens/male_03.mdl"] = "models/wichacks/joenovest.mdl",
	["models/humans/pandafishizens/male_04.mdl"] = "models/wichacks/ericnovest.mdl",
	["models/humans/pandafishizens/male_05.mdl"] = "models/wichacks/vancenovest.mdl",
	["models/humans/pandafishizens/male_06.mdl"] = "models/wichacks/sandronovest.mdl",
	["models/humans/pandafishizens/male_07.mdl"] = "models/wichacks/mikenovest.mdl",
	["models/humans/pandafishizens/male_09.mdl"] = "models/wichacks/erdimnovest.mdl",
	["models/humans/pandafishizens/female_01.mdl"] = "models/models/army/female_01.mdl",
	["models/humans/pandafishizens/female_02.mdl"] = "models/models/army/female_02.mdl",
	["models/humans/pandafishizens/female_03.mdl"] = "models/models/army/female_03.mdl",
	["models/humans/pandafishizens/female_04.mdl"] = "models/models/army/female_04.mdl",
	["models/humans/pandafishizens/female_06.mdl"] = "models/models/army/female_06.mdl",
	["models/humans/pandafishizens/female_07.mdl"] = "models/models/army/female_07.mdl"
}

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

function FACTION:GetUniformReturnFaction(character)
	local state = self:GetUniformState(character)
	local faction = ix.faction.teams[state.originalFaction or DEFAULT_CITIZEN_FACTION]

	return faction and faction.index or FACTION_CITIZEN
end

function FACTION:GetConscriptRank(character)
	local rankData = Schema:GetConscriptRankData(character and character:GetData(CONSCRIPT_RANK_KEY))

	return rankData and rankData.id or Schema:GetDefaultConscriptRank()
end

function FACTION:SetConscriptRank(character, rank)
	local rankData = Schema:GetConscriptRankData(rank) or Schema:GetConscriptRankData(Schema:GetDefaultConscriptRank())

	character:SetData(CONSCRIPT_RANK_KEY, rankData.id)

	return rankData
end

function FACTION:GetBaseName(character)
	local state = self:GetUniformState(character)

	if (state.active and isstring(state.originalName) and state.originalName != "") then
		return Schema:ExtractConscriptBaseName(state.originalName)
	end

	return Schema:ExtractConscriptBaseName(character:GetName())
end

function FACTION:GetFormattedName(character, baseName)
	return Schema:FormatConscriptName(baseName or self:GetBaseName(character), self:GetConscriptRank(character))
end

function FACTION:SetDisplayedName(character, baseName)
	local formatted = self:GetFormattedName(character, baseName)
	local charID = character:GetID()

	if (character:GetName() == formatted) then
		return formatted
	end

	nameSyncLocks[charID] = true
	character:SetName(formatted)
	nameSyncLocks[charID] = nil

	return formatted
end

function FACTION:ResolveDutyModel(character, sourceModel)
	sourceModel = NormalizeModel(sourceModel or character:GetModel())

	if (table.HasValue(self.models, sourceModel)) then
		return sourceModel
	end

	local mappedModel = dutyModelFallbacks[sourceModel]

	if (mappedModel and table.HasValue(self.models, mappedModel)) then
		return mappedModel
	end

	local gender = GetGenderFromModel(sourceModel)
	return self.genderModels[gender] and self.genderModels[gender][1] or self.models[1]
end

function FACTION:AssignDefaultClass(character)
	if (CLASS_CONSCRIPT and character:GetClass() != CLASS_CONSCRIPT) then
		local client = character:GetPlayer()

		if (IsValid(client)) then
			character:JoinClass(CLASS_CONSCRIPT)
		else
			character:SetClass(CLASS_CONSCRIPT)
		end
	end
end

function FACTION:OnCharacterCreated(client, character)
	local inventory = character:GetInventory()

	self:SetConscriptRank(character, character:GetData(CONSCRIPT_RANK_KEY))

	inventory:Add("smg1", 1)
	inventory:Add("smg1ammo", 2)
	inventory:Add("pistol", 1)
	inventory:Add("pistolammo", 2)
	inventory:Add("handheld_radio", 1)
	inventory:Add("hat", 1)
	inventory:Add("pasgt_helmet", 1)
	inventory:Add("pasgt_body_armor", 1)
	inventory:Add("grenade", 1)
	inventory:Add("bandage", 2)
	inventory:Add("health_vial", 1)
	inventory:Add("flashlight", 1)
	inventory:Add("stunstick", 1)
	inventory:Add("comkey", 1)
	inventory:Add("bag", 1)
	inventory:Add("zip_tie", 2)

	character:SetModel(self:ResolveDutyModel(character, character:GetModel()))
	self:SetDisplayedName(character, character:GetName())
	self:AssignDefaultClass(character)
end

function FACTION:GetDefaultName(client)
	local character = IsValid(client) and client:GetCharacter()

	if (!character) then
		return nil
	end

	return self:GetFormattedName(character, self:GetBaseName(character))
end

function FACTION:OnTransferred(character)
	local state = self:GetUniformState(character)
	local baseName = self:GetBaseName(character)
	local model = state.active and (state.dutyModel or self:ResolveDutyModel(character, state.originalModel)) or self:ResolveDutyModel(character, character:GetModel())

	if (state.active) then
		state.originalName = baseName
		state.dutyName = self:GetFormattedName(character, baseName)
		state.dutyModel = model
		state.dutyDescription = state.dutyDescription or self.description or "A regular human citizen enlisted as a soldier to Combine Overwatch."
		self:SetUniformState(character, state)
	end

	character:SetModel(model)
	self:SetDisplayedName(character, baseName)
	self:AssignDefaultClass(character)

	if (state.active and state.dutyDescription) then
		character:SetDescription(state.dutyDescription)
	else
		character:SetDescription(self.description)
	end
end

function FACTION:OnNameChanged(client, oldValue, value)
	local character = client:GetCharacter()

	if (!character or nameSyncLocks[character:GetID()]) then
		return
	end

	local state = self:GetUniformState(character)
	local baseName = Schema:ExtractConscriptBaseName(value)

	if (baseName == "") then
		baseName = Schema:ExtractConscriptBaseName(oldValue or "")
	end

	if (baseName == "") then
		baseName = "Conscript"
	end

	if (state.active) then
		local rankData = Schema:GetConscriptRankDataFromText(value)

		if (rankData) then
			self:SetConscriptRank(character, rankData.id)
		end

		state.originalName = baseName
		state.dutyName = self:GetFormattedName(character, baseName)
		state.dutyModel = character:GetModel()
		self:SetUniformState(character, state)
	end

	self:SetDisplayedName(character, baseName)
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
	if (data.ladder or data.submerged) then
		return
	end

	if (data.running) then
		data.snd = data.foot and "NPC_MetroPolice.RunFootstepRight" or "NPC_MetroPolice.RunFootstepLeft"
		data.volume = data.volume * 0.6
	end
end

FACTION_CONSCRIPT = FACTION.index
