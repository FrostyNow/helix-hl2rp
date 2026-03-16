local playerMeta = FindMetaTable("Player")
local NON_BINARY_MODEL_CLASSES = {
	overwatch = true,
	player = true,
	vortigaunt = true
}

local function NormalizeModel(model)
	return isstring(model) and model:gsub("\\", "/"):lower() or ""
end

local function GetGenderFromFactionModels(factionTable, model)
	local genderModels = factionTable and factionTable.genderModels

	if (!genderModels) then
		return nil
	end

	for gender, models in pairs(genderModels) do
		for _, factionModel in ipairs(models) do
			if (NormalizeModel(factionModel) == model) then
				return gender
			end
		end
	end
end

local function GetCharacterGender(character)
	if (!character) then
		return nil
	end

	local model = NormalizeModel(character:GetModel())

	if (model == "") then
		return nil
	end

	local modelClass = ix.anim.GetModelClass(model)

	if (NON_BINARY_MODEL_CLASSES[modelClass]) then
		return nil
	end

	local faction = ix.faction.indices[character:GetFaction()]
	local factionGender = GetGenderFromFactionModels(faction, model)

	if (factionGender) then
		return factionGender
	end

	if (model:find("female", 1, true) or model:find("alyx", 1, true) or model:find("mossman", 1, true)
	or modelClass == "citizen_female") then
		return "female"
	end

	if (model:find("male", 1, true) or modelClass == "citizen_male") then
		return "male"
	end

	return nil
end

function Schema:IsPlayerFemale(client)
	local character = client:GetCharacter()
	local gender = GetCharacterGender(character)

	if (gender == "female") then
		return true
	end

	if (gender == "male") then
		return false
	end
end

function playerMeta:IsCombine()
	local character = self:GetCharacter()
	if (character and character:IsCombine()) then
		return true
	end

	local faction = self:Team()
	return faction == FACTION_MPF or faction == FACTION_OTA
end

function playerMeta:IsDispatch()
	local name = self:Name()
	local faction = self:Team()
	local bStatus = (self:IsAdmin() and faction == FACTION_OTA) or faction == FACTION_ADMIN or self:IsAdmin()

	if (!bStatus) then
		for k, v in ipairs({ "OfC", "SCN", "DvL", "SeC", "CmD" }) do
			if (Schema:IsCombineRank(name, v)) then
				bStatus = true

				break
			end
		end
	end

	return bStatus
end

function playerMeta:IsBreencast()
	local name = self:Name()
	local faction = self:Team()
	local bStatus = faction == FACTION_ADMIN or self:IsAdmin()

	return bStatus
end
