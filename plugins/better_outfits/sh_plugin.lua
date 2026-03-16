local PLUGIN = PLUGIN
PLUGIN.name = "Helios Outfits"
PLUGIN.author = "Helios | Modified by Frosty"
PLUGIN.desc = "Fixes some issues with Helix's builtin outfit system."

local DEFAULT_ALLOWED_BASE_MODEL_CLASSES = {
	citizen_female = true,
	citizen_male = true,
	metrocop = true
}
local TEMP_OUTFIT_MODEL_OVERRIDE = "tempOutfitModelOverride"
local TEMP_OUTFIT_SKIN_OVERRIDE = "tempOutfitSkinOverride"

local function NormalizeModel(model)
	return isstring(model) and model:gsub("\\", "/"):lower() or ""
end

local function BuildLookup(values, normalizeKey)
	if (!istable(values)) then
		return nil
	end

	local lookup = {}
	local hasValues = false

	for key, value in pairs(values) do
		if (isnumber(key)) then
			local normalized = normalizeKey and normalizeKey(value) or value

			if (normalized != nil) then
				lookup[normalized] = true
				hasValues = true
			end
		elseif (value) then
			local normalized = normalizeKey and normalizeKey(key) or key

			if (normalized != nil) then
				lookup[normalized] = true
				hasValues = true
			end
		end
	end

	return hasValues and lookup or nil
end

local function GetBaseAppearanceContext(character)
	if (!character) then
		return nil
	end

	local factionID = character:GetFaction()
	local model = NormalizeModel(character:GetModel())
	local faction = ix.faction.indices[factionID]
	local factionUniqueID = faction and faction.uniqueID or nil

	if (faction and faction.IsUniformCitizenDuty and faction.GetUniformReturnFaction and faction:IsUniformCitizenDuty(character)) then
		local state = faction:GetUniformState(character)
		local returnFaction = faction:GetUniformReturnFaction(character)

		factionID = returnFaction or factionID
		faction = ix.faction.indices[factionID]
		factionUniqueID = faction and faction.uniqueID or factionUniqueID
		model = NormalizeModel(state.originalModel or model)
	end

	return {
		faction = factionID,
		factionUniqueID = factionUniqueID,
		model = model,
		modelClass = ix.anim.GetModelClass(model)
	}
end

local function IsModelChangingItem(item)
	local itemTable = ix.item.list[item.uniqueID]
	local category = item.outfitCategory or (itemTable and itemTable.outfitCategory)

	return category == "suit"
		or category == "model"
		or item.replacement != nil
		or item.replacements != nil
		or (itemTable and (itemTable.replacement != nil or itemTable.replacements != nil))
		or isfunction(item.OnGetReplacement)
		or (itemTable and isfunction(itemTable.OnGetReplacement))
end

local function GetAllowedBaseModelClasses(item)
	return BuildLookup(item.allowedBaseModelClasses, function(value)
		return isstring(value) and value:lower() or nil
	end)
end

local function GetAllowedBaseFactions(item)
	return BuildLookup(item.allowedBaseFactions)
end

local function GetAllowedBaseModels(item)
	return BuildLookup(item.allowedBaseModels, NormalizeModel)
end

function PLUGIN:HasEquippedModelChangingOutfit(character)
	if (!character) then
		return false
	end

	local inventory = character:GetInventory()

	if (!inventory) then
		return false
	end

	for _, item in pairs(inventory:GetItems()) do
		if (item:GetData("equip") and IsModelChangingItem(item)) then
			return true
		end
	end

	return false
end

function PLUGIN:SetTemporaryOutfitModelOverride(character, model)
	if (!character) then
		return
	end

	model = isstring(model) and model or nil
	character:SetVar(TEMP_OUTFIT_MODEL_OVERRIDE, model, true)
end

function PLUGIN:GetTemporaryOutfitModelOverride(character)
	return character and character:GetVar(TEMP_OUTFIT_MODEL_OVERRIDE)
end

function PLUGIN:SetTemporaryOutfitSkinOverride(character, skin)
	if (!character) then
		return
	end

	skin = skin == nil and nil or math.max(tonumber(skin) or 0, 0)
	character:SetVar(TEMP_OUTFIT_SKIN_OVERRIDE, skin, true)
end

function PLUGIN:GetTemporaryOutfitSkinOverride(character)
	return character and character:GetVar(TEMP_OUTFIT_SKIN_OVERRIDE)
end

function PLUGIN:ClearTemporaryOutfitOverrides(character)
	if (!character) then
		return
	end

	character:SetVar(TEMP_OUTFIT_MODEL_OVERRIDE, nil, true)
	character:SetVar(TEMP_OUTFIT_SKIN_OVERRIDE, nil, true)
end

function PLUGIN:ReapplyBodygroupAppearance(client, character)
	if (!IsValid(client) or !character) then
		return
	end

	for i = 0, client:GetNumBodyGroups() - 1 do
		client:SetBodygroup(i, 0)
	end

	local baseGroups = character:GetData("groups", {})

	for key, value in pairs(baseGroups) do
		local index = isnumber(key) and key or client:FindBodygroupByName(key)

		if (index and index > -1) then
			client:SetBodygroup(index, tonumber(value) or 0)
		end
	end

	local inventory = character:GetInventory()

	if (!inventory) then
		return
	end

	for _, item in pairs(inventory:GetItems()) do
		if (item:GetData("equip") and item.eqBodyGroups) then
			for bgName, bgValue in pairs(item.eqBodyGroups) do
				local index = client:FindBodygroupByName(bgName)

				if (index > -1) then
					client:SetBodygroup(index, bgValue)
				end
			end
		end
	end
end

function PLUGIN:GetExpectedAppearanceSkin(character, client)
	if (!character) then
		return 0
	end

	local skin = tonumber(character:GetData("skin", IsValid(client) and client:GetSkin() or 0)) or 0
	local inventory = character:GetInventory()

	if (!inventory) then
		return skin
	end

	for _, item in pairs(inventory:GetItems()) do
		if (!item:GetData("equip") or item.newSkin == nil or !IsModelChangingItem(item)) then
			continue
		end

		local itemTable = ix.item.list[item.uniqueID]
		local category = item.outfitCategory or (itemTable and itemTable.outfitCategory)

		if (category and character:GetData("oldSkin" .. category) != nil) then
			skin = tonumber(item.newSkin) or skin
		end
	end

	return skin
end

function PLUGIN:ApplyTemporaryOutfitOverrides(client, character)
	if (!IsValid(client) or !character) then
		return false
	end

	local model = self:GetTemporaryOutfitModelOverride(character)
	local skin = self:GetTemporaryOutfitSkinOverride(character)
	local changed = false

	if (isstring(model) and model != "" and NormalizeModel(client:GetModel()) != NormalizeModel(model)) then
		client:SetModel(model)
		client:SetupHands()
		self:ReapplyBodygroupAppearance(client, character)
		changed = true
	end

	if (skin != nil) then
		client:SetSkin(math.max(tonumber(skin) or 0, 0))
		changed = true
	elseif (changed) then
		client:SetSkin(self:GetExpectedAppearanceSkin(character, client))
	end

	return changed
end

function PLUGIN:CanPlayerEquipItem(client, item)
	if (!IsValid(client) or !item or !IsModelChangingItem(item)) then
		return
	end

	local character = client:GetCharacter()

	if (!character) then
		return false
	end

	local inventory = character:GetInventory()

	if (inventory) then
		for _, equippedItem in pairs(inventory:GetItems()) do
			if (equippedItem.id != item.id and equippedItem:GetData("equip") and IsModelChangingItem(equippedItem)) then
				client:NotifyLocalized(item.equippedNotify or "outfitAlreadyEquipped")
				return false
			end
		end
	end

	if (item.ignoreBaseModelGuard or item.allowAnyBaseModel) then
		return
	end

	local context = GetBaseAppearanceContext(character)

	if (!context) then
		return false
	end

	local allowedBaseModels = GetAllowedBaseModels(item)

	if (allowedBaseModels) then
		if (!allowedBaseModels[context.model]) then
			client:NotifyLocalized("outfitUnsupportedBaseIdentity")
			return false
		end

		return
	end

	local allowedBaseFactions = GetAllowedBaseFactions(item)

	if (allowedBaseFactions) then
		if (!allowedBaseFactions[context.faction] and !allowedBaseFactions[context.factionUniqueID]) then
			client:NotifyLocalized("outfitUnsupportedBaseIdentity")
			return false
		end

		return
	end

	local allowedBaseModelClasses = GetAllowedBaseModelClasses(item) or DEFAULT_ALLOWED_BASE_MODEL_CLASSES

	if (!allowedBaseModelClasses[context.modelClass]) then
		client:NotifyLocalized("outfitUnsupportedBaseIdentity")
		return false
	end
end

function PLUGIN:CharacterVarChanged(character, key, oldValue, value)
	if (key == "model") then
		local client = character:GetPlayer()

		if (IsValid(client)) then
			local inventory = character:GetInventory()

			if (inventory) then
				local items = inventory:GetItems()

				-- Check if any equipped item is currently overriding the model.
				-- If so, we skip the allowedModels check because the player is "disguised" or in a suit.
				for _, item in pairs(items) do
					if (item:GetData("equip") and item.outfitCategory) then
						if (character:GetData("oldModel" .. item.outfitCategory)) then
							return
						end
					end
				end

				for _, item in pairs(items) do
					if (item:GetData("equip") and item.outfitCategory and item.allowedModels) then
						if (!table.HasValue(item.allowedModels, value)) then
							item:RemoveOutfit(client)
						end
					end
				end
			end
		end
	end
end
