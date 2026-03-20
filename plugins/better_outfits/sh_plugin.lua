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

local modelBodygroupNameCache = {}

local function GetModelBodygroupName(model, index)
	model = NormalizeModel(model)

	if (model == "") then
		return nil
	end

	modelBodygroupNameCache[model] = modelBodygroupNameCache[model] or {}

	if (modelBodygroupNameCache[model][index] != nil) then
		return modelBodygroupNameCache[model][index]
	end

	local entity

	if (SERVER) then
		entity = ents.Create("prop_dynamic")
	else
		entity = ClientsideModel(model)
	end

	if (!IsValid(entity)) then
		return nil
	end

	entity:SetModel(model)

	for i = 0, entity:GetNumBodyGroups() - 1 do
		modelBodygroupNameCache[model][i] = entity:GetBodygroupName(i)
	end

	entity:Remove()

	return modelBodygroupNameCache[model][index]
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

local function ResolveCharacterInventory(character)
	if (!character or !character.GetInventory) then
		return nil
	end

	local inventory = character:GetInventory()

	if (isnumber(inventory)) then
		inventory = ix.item.inventories[inventory] or ix.inventory.Get(inventory)
	end

	if (!istable(inventory) or !inventory.GetItems) then
		return nil
	end

	return inventory
end

local function GetCharacterItems(character)
	local items = {}
	local inventory = ResolveCharacterInventory(character)

	if (inventory) then
		for _, item in pairs(inventory:GetItems()) do
			items[#items + 1] = item
		end

		return items
	end

	local charID = character and character.GetID and character:GetID()

	if (!charID) then
		return items
	end

	for _, inv in pairs(ix.item.inventories) do
		if (inv.owner == charID) then
			for _, item in pairs(inv:GetItems()) do
				items[#items + 1] = item
			end
		end
	end

	return items
end

function PLUGIN:HasEquippedModelChangingOutfit(character)
	if (!character) then
		return false
	end

	local inventory = ResolveCharacterInventory(character)

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

function PLUGIN:GetCharacterPreviewAppearance(character, entity)
	if (!character) then
		return nil
	end

	local items = GetCharacterItems(character)
	local stack = table.Copy(character:GetData("appearanceStack", {}))
	local baseModel = character:GetData("oldModelBase", character:GetModel())
	local targetModel = baseModel
	local topSkinItem = nil
	local equippedLookup = {}

	for _, item in ipairs(items) do
		if (item:GetData("equip")) then
			equippedLookup[item.id] = item

			if (IsModelChangingItem(item) and !table.HasValue(stack, item.id)) then
				table.insert(stack, 1, item.id)
			end
		end
	end

	for _, stackID in ipairs(stack) do
		local item = equippedLookup[stackID]

		if (item and IsModelChangingItem(item)) then
			if (isfunction(item.OnGetReplacement)) then
				local resolved = item:OnGetReplacement()

				if (resolved) then
					targetModel = resolved
				end
			elseif (item.replacement) then
				targetModel = item.replacement
			elseif (item.replacements) then
				if (isstring(item.replacements)) then
					targetModel = item.replacements
				elseif (istable(item.replacements)) then
					if (#item.replacements == 2 and isstring(item.replacements[1])) then
						targetModel = targetModel:gsub(item.replacements[1], item.replacements[2])
					else
						for _, replacement in ipairs(item.replacements) do
							if (istable(replacement)) then
								targetModel = targetModel:gsub(replacement[1], replacement[2])
							end
						end
					end
				end
			end

			if (item.newSkin != nil) then
				topSkinItem = item
			end
		end
	end

	local skin = tonumber(character:GetData("skin", 0)) or 0

	if (topSkinItem and topSkinItem.newSkin != nil) then
		skin = tonumber(topSkinItem.newSkin) or skin
	end

	local bodygroups = {}
	local isTopLayerVisible = NormalizeModel(targetModel) != NormalizeModel(baseModel)
	local currentModel = NormalizeModel(targetModel)

	for key, value in pairs(character:GetData("groups", {})) do
		local bodygroupKey = key

		if (isnumber(key) and isTopLayerVisible) then
			bodygroupKey = GetModelBodygroupName(baseModel, key)
		end

		if (bodygroupKey != nil) then
			bodygroups[bodygroupKey] = tonumber(value) or 0
		end
	end

	for _, item in ipairs(items) do
		if (item:GetData("equip") and item.eqBodyGroups) then
			if (item.IsCompatibleWith and !item:IsCompatibleWith(currentModel) and !item:IsCompatibleWith(baseModel) and !IsModelChangingItem(item)) then
				continue
			end

			for bgName, bgValue in pairs(item.eqBodyGroups) do
				bodygroups[bgName] = tonumber(bgValue) or 0
			end
		end
	end

	return {
		model = targetModel,
		skin = skin,
		bodygroups = bodygroups
	}
end

function PLUGIN:ApplyCharacterPreviewAppearance(character, entity)
	if (!character or !IsValid(entity)) then
		return false
	end

	local appearance = self:GetCharacterPreviewAppearance(character, entity)

	if (!appearance or !isstring(appearance.model) or appearance.model == "") then
		return false
	end

	if (NormalizeModel(entity:GetModel()) != NormalizeModel(appearance.model)) then
		entity:SetModel(appearance.model)
	end

	entity:SetSkin(math.max(tonumber(appearance.skin) or 0, 0))

	for i = 0, entity:GetNumBodyGroups() - 1 do
		entity:SetBodygroup(i, 0)
	end

	for key, value in pairs(appearance.bodygroups or {}) do
		local index = tonumber(key) or entity:FindBodygroupByName(key)

		if (index and index > -1) then
			entity:SetBodygroup(index, tonumber(value) or 0)
		end
	end

	return true
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

function PLUGIN:IsModelOverridden(character)
	if (!character) then return false end

	for k, v in pairs(character:GetData()) do
		if (isstring(k) and k:sub(1, 8) == "oldModel" and v != nil) then
			return true
		end
	end

	return false
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

	-- 1. Reset all bodygroups on the CURRENT model
	for i = 0, client:GetNumBodyGroups() - 1 do
		client:SetBodygroup(i, 0)
	end

	local currentModel = NormalizeModel(client:GetModel())
	local isOverridden = self:IsModelOverridden(character)
	local baseGroups = character:GetData("groups", {})

	-- 2. Apply base character bodygroups
	for key, value in pairs(baseGroups) do
		local index = -1

		if (isnumber(key)) then
			-- ONLY apply numeric indices if we are on the base model (not a suit)
			if (!isOverridden) then
				index = key
			else
				-- If hijacked, try to resolve name fallback for character features (facial hair etc)
				-- This is a heuristic: we don't know the base model here, so we hope they used names.
				-- If they used numbers, we skip for safety.
				continue 
			end
		else
			-- ALWAYS try to find by name - this is safe across models
			index = client:FindBodygroupByName(key)
		end

		if (index and index > -1) then
			client:SetBodygroup(index, tonumber(value) or 0)
		end
	end

	local charID = character:GetID()
	local items = {}
	for _, inv in pairs(ix.item.inventories) do
		if (inv.owner == charID) then
			for _, v in pairs(inv:GetItems()) do
				table.insert(items, v)
			end
		end
	end
	for _, item in pairs(items) do
		if (item:GetData("equip") and item.eqBodyGroups) then
			-- Compatibility check: ignore item bodygroups if this item isn't meant for this model
			-- NOTE: We also check IsModelChangingItem because if an item changed the model itself, 
			-- it should be allowed to apply its own bodygroups to the result.
			if (item.IsCompatibleWith and !item:IsCompatibleWith(currentModel) and !IsModelChangingItem(item)) then
				continue
			end

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
	local inventory = ResolveCharacterInventory(character)

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

	if (!self:HasEquippedModelChangingOutfit(character)) then
		self:ClearTemporaryOutfitOverrides(character)
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
		local expectedSkin = self:GetExpectedAppearanceSkin(character, client)
		client:SetSkin(expectedSkin)
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

	local inventory = ResolveCharacterInventory(character)

	if (inventory) then
		local itemCategory = item.outfitCategory or (ix.item.list[item.uniqueID] and ix.item.list[item.uniqueID].outfitCategory)

		for _, equippedItem in pairs(inventory:GetItems()) do
			if (equippedItem.id != item.id and equippedItem:GetData("equip") and IsModelChangingItem(equippedItem)) then
				local equippedCategory = equippedItem.outfitCategory or (ix.item.list[equippedItem.uniqueID] and ix.item.list[equippedItem.uniqueID].outfitCategory)

				if (itemCategory != equippedCategory) then
					continue
				end

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
			local inventory = ResolveCharacterInventory(character)

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
