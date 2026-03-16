
local PLUGIN = PLUGIN

PLUGIN.name = "Bodygroup Manager"
PLUGIN.author = "Gary Tate | Modified by Frosty"
PLUGIN.description = "Allows players and administration to have an easier time customising bodygroups."

ix.lang.AddTable("english", {
	cmdEditBodygroup = "Customise the bodygroups of a target.",
	cmdBodygroup = "Customise your own bodygroups (requires the b flag).",
	cmdSkin = "Customise your own skin (requires the s flag).",
	bodygroupManager = "Bodygroup Manager",
	saveChanges = "Save Changes",
	skin = "Skin",
	next = "Next",
	previous = "Previous",
	cmdCharResetBodygroups = "Reset the bodygroups of a target character and unequip related items.",
	cmdCharResetModel = "Reset the model of a target character and unequip related appearance items.",
	cmdCharResetSkin = "Reset the skin of a target character and unequip related appearance items.",
	cmdCharForceResetBodygroups = "Force reset a loaded character by exact name, unequip appearance items, and delete saved bodygroup/skin data.",
	resetBodygroupsTarget = "Your bodygroups have been reset by an administrator.",
	resetBodygroupsClient = "You have reset the bodygroups of %s.",
	resetModelTarget = "Your character model has been reset by an administrator.",
	resetModelClient = "You have reset %s's model.",
	resetSkinTarget = "Your character skin has been reset by an administrator.",
	resetSkinClient = "You have reset %s's skin.",
	resetBodygroupsOnlineOnly = "This command only works on online characters.",
	forceResetBodygroupsTarget = "Your bodygroups and saved appearance data have been force-reset by an administrator.",
	forceResetBodygroupsClient = "You have force-reset %s and deleted saved appearance data.",
	forceResetBodygroupsNameMismatch = "The provided name must match the target's exact current name.",
	forceResetBodygroupsConfirm = "You must pass true as the second argument to force reset bodygroups.",
	forceResetBodygroupsNotFound = "No online character matches that exact name.",
	warnEquippedOutfit = "Warning: Modifying bodygroups/skin while wearing an outfit may cause unexpected behavior!",
	temporaryBodygroupChanges = "While wearing a model-changing outfit, only base appearance bodygroups are applied temporarily and skin changes are ignored."
})

ix.lang.AddTable("korean", {
	cmdEditBodygroup = "대상의 바디그룹/스킨을 수정합니다.",
	cmdBodygroup = "자신의 바디그룹을 수정합니다. (b 플래그 필요)",
	cmdSkin = "자신의 스킨을 수정합니다. (s 플래그 필요)",
	bodygroupManager = "바디그룹 매니저",
	saveChanges = "변경사항 저장",
	skin = "스킨",
	next = "다음",
	previous = "이전",
	cmdCharResetBodygroups = "대상의 바디그룹을 초기화하고 관련 아이템을 장착 해제합니다.",
	cmdCharResetModel = "대상의 모델을 초기화하고 관련 외형 아이템을 장착 해제합니다.",
	cmdCharResetSkin = "대상의 스킨을 초기화하고 관련 외형 아이템을 장착 해제합니다.",
	cmdCharForceResetBodygroups = "정확한 이름과 true 확인값으로 로드된 대상의 바디그룹과 저장 외형 데이터를 강제 초기화합니다.",
	resetBodygroupsTarget = "관리자에 의해 바디그룹이 초기화되었습니다.",
	resetBodygroupsClient = "%s의 바디그룹을 초기화했습니다.",
	resetModelTarget = "관리자에 의해 캐릭터 모델이 초기화되었습니다.",
	resetModelClient = "%s의 모델을 초기화했습니다.",
	resetSkinTarget = "관리자에 의해 캐릭터 스킨이 초기화되었습니다.",
	resetSkinClient = "%s의 스킨을 초기화했습니다.",
	resetBodygroupsOnlineOnly = "이 명령어는 온라인 상태의 캐릭터에게만 사용할 수 있습니다.",
	forceResetBodygroupsTarget = "관리자에 의해 바디그룹과 저장 외형 데이터가 강제 초기화되었습니다.",
	forceResetBodygroupsClient = "%s의 바디그룹과 저장 외형 데이터를 강제 초기화했습니다.",
	forceResetBodygroupsNameMismatch = "입력한 이름이 대상의 현재 정확한 이름과 일치해야 합니다.",
	forceResetBodygroupsConfirm = "강제 초기화를 실행하려면 두 번째 인자로 true를 넣어야 합니다.",
	forceResetBodygroupsNotFound = "해당 정확한 이름의 온라인 캐릭터를 찾을 수 없습니다.",
	warnEquippedOutfit = "경고: 대상을 의상으로 장착한 상태에서 바디그룹/스킨을 수정하면 데이터가 얽혀 문제가 발생할 수 있습니다!",
	temporaryBodygroupChanges = "모델이 바뀌는 의상 착용 중에는 기본 외형용 바디그룹만 일시 적용되며, 스킨 변경은 저장되지 않습니다."
})

local function HasEquippedOutfit(character)
	if (!character) then return false end
	
	local inventory = character:GetInventory()
	if (inventory) then
		for _, item in pairs(inventory:GetItems()) do
			if (item:GetData("equip") and (item.outfitCategory or item.eqBodyGroups or item.bodyGroups)) then
				return true
			end
		end
	end
	return false
end

local ORIGINAL_GROUPS_KEY = "originalAppearanceGroups"
local ORIGINAL_SKIN_KEY = "originalAppearanceSkin"

local function NormalizeBodygroupName(name)
	if (!isstring(name)) then
		return ""
	end

	return name:gsub("[%s_%-]", ""):lower()
end

local function NormalizeModelPath(model)
	return isstring(model) and model:gsub("\\", "/"):lower() or ""
end

local function IsFemaleModel(model)
	model = NormalizeModelPath(model)

	return model:find("female", 1, true) != nil
		or model:find("alyx", 1, true) != nil
		or model:find("mossman", 1, true) != nil
		or ix.anim.GetModelClass(model) == "citizen_female"
end

local function ResolveOriginalSkin(character, player)
	local fallbackSkin = IsValid(player) and player:GetSkin() or 0
	local skin = tonumber(character:GetData("skin", fallbackSkin)) or 0
	local inventory = character:GetInventory()
	local fallbackOldSkin

	if (!inventory) then
		return skin
	end

	for _, item in pairs(inventory:GetItems()) do
		if (!item:GetData("equip")) then
			continue
		end

		local itemTable = ix.item.list[item.uniqueID]
		local category = item.outfitCategory or (itemTable and itemTable.outfitCategory)

		if (!category) then
			continue
		end

		local oldSkin = character:GetData("oldSkin" .. category)

		if (oldSkin != nil) then
			if (category == "suit" or category == "model") then
				return tonumber(oldSkin) or skin
			end

			fallbackOldSkin = fallbackOldSkin or oldSkin
		end
	end

	return tonumber(fallbackOldSkin) or skin
end

function PLUGIN:HasEquippedSuit(character)
	if (!character) then return false end

	local inventory = character:GetInventory()

	if (!inventory) then return false end

	for _, item in pairs(inventory:GetItems()) do
		if (!item:GetData("equip")) then
			continue
		end

		local itemTable = ix.item.list[item.uniqueID]
		local category = item.outfitCategory or (itemTable and itemTable.outfitCategory)

		if (category == "suit") then
			return true
		end
	end

	return false
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
		if (!item:GetData("equip")) then
			continue
		end

		local itemTable = ix.item.list[item.uniqueID]
		local category = item.outfitCategory or (itemTable and itemTable.outfitCategory)
		local hasReplacement = item.replacement or item.replacements
			or (itemTable and (itemTable.replacement or itemTable.replacements))
			or isfunction(item.OnGetReplacement) or (itemTable and isfunction(itemTable.OnGetReplacement))

		if (category == "suit" or category == "model" or hasReplacement) then
			return true
		end
	end

	return false
end

function PLUGIN:GetBaseAppearanceFaction(character)
	if (!character) then
		return nil
	end

	local faction = ix.faction.indices[character:GetFaction()]

	if (!faction) then
		return nil
	end

	if (faction.IsUniformCitizenDuty and faction.GetUniformReturnFaction and faction:IsUniformCitizenDuty(character)) then
		return ix.faction.indices[faction:GetUniformReturnFaction(character)] or faction
	end

	return faction
end

function PLUGIN:GetRestorableBodygroupWhitelist(character)
	local whitelist = {}
	local faction = self:GetBaseAppearanceFaction(character)

	if (!faction or !istable(faction.bodyGroups)) then
		return whitelist
	end

	for key, data in pairs(faction.bodyGroups) do
		whitelist[NormalizeBodygroupName(key)] = true

		if (istable(data) and isstring(data.name)) then
			whitelist[NormalizeBodygroupName(data.name)] = true
		end
	end

	return whitelist
end

function PLUGIN:FilterRestorableGroups(character, player, groups)
	if (!istable(groups)) then
		return {}
	end

	local whitelist = self:GetRestorableBodygroupWhitelist(character)

	if (table.IsEmpty(whitelist) or !IsValid(player)) then
		return table.Copy(groups)
	end

	local groupNames = {}

	for _, bodygroup in ipairs(player:GetBodyGroups()) do
		groupNames[bodygroup.id] = NormalizeBodygroupName(bodygroup.name)
	end

	local filtered = {}

	for index, value in pairs(groups) do
		if (isnumber(index) and whitelist[groupNames[index] or ""]) then
			filtered[index] = tonumber(value) or 0
		end
	end

	return filtered
end

function PLUGIN:GetEditableBodygroupValues(character, player, values)
	if (!istable(values)) then
		return {}
	end

	if (!self:HasEquippedModelChangingOutfit(character) or !IsValid(player)) then
		return table.Copy(values)
	end

	local whitelist = self:GetRestorableBodygroupWhitelist(character)
	local allowed = {}

	if (table.IsEmpty(whitelist)) then
		return allowed
	end

	local groupNames = {}

	for _, bodygroup in ipairs(player:GetBodyGroups()) do
		groupNames[bodygroup.id] = NormalizeBodygroupName(bodygroup.name)
	end

	for index, value in pairs(values) do
		index = tonumber(index)

		if (index and whitelist[groupNames[index] or ""]) then
			allowed[index] = tonumber(value) or 0
		end
	end

	return allowed
end

function PLUGIN:SetPersistentAppearance(character, groups, skin)
	if (!character) then
		return
	end

	if (groups != nil) then
		local cleanGroups = istable(groups) and table.Copy(groups) or {}
		character:SetData("groups", cleanGroups)
		character:SetData(ORIGINAL_GROUPS_KEY, table.Copy(cleanGroups))
	end

	if (skin != nil) then
		local cleanSkin = tonumber(skin) or 0
		character:SetData("skin", cleanSkin)
		character:SetData(ORIGINAL_SKIN_KEY, cleanSkin)
	end
end

function PLUGIN:EnsureOriginalAppearance(character, player)
	if (CLIENT or !character) then
		return
	end

	if (istable(character:GetData(ORIGINAL_GROUPS_KEY)) and character:GetData(ORIGINAL_SKIN_KEY) != nil) then
		return true
	end

	if (!istable(character:GetData(ORIGINAL_GROUPS_KEY))) then
		local groups = character:GetData("groups", {})
		character:SetData(ORIGINAL_GROUPS_KEY, istable(groups) and table.Copy(groups) or {})
	end

	if (character:GetData(ORIGINAL_SKIN_KEY) == nil) then
		character:SetData(ORIGINAL_SKIN_KEY, ResolveOriginalSkin(character, player))
	end

	return true
end

function PLUGIN:GetOriginalAppearance(character, player)
	if (!self:EnsureOriginalAppearance(character, player)) then
		return nil, nil
	end

	local groups = character:GetData(ORIGINAL_GROUPS_KEY, {})
	local skin = tonumber(character:GetData(ORIGINAL_SKIN_KEY, IsValid(player) and player:GetSkin() or 0)) or 0

	return istable(groups) and table.Copy(groups) or {}, skin
end

local function GetAppearanceCategory(item)
	local itemTable = ix.item.list[item.uniqueID]
	return item.outfitCategory or (itemTable and itemTable.outfitCategory)
end

local function GetAppearanceCategories(character)
	local categories = {
		model = true,
		suit = true
	}

	if (ix.item and ix.item.list) then
		for _, itemTable in pairs(ix.item.list) do
			if (isstring(itemTable.outfitCategory) and itemTable.outfitCategory != "") then
				categories[itemTable.outfitCategory] = true
			end
		end
	end

	local inventory = character and character:GetInventory()

	if (inventory) then
		for _, item in pairs(inventory:GetItems()) do
			local category = GetAppearanceCategory(item)

			if (isstring(category) and category != "") then
				categories[category] = true
			end
		end
	end

	return categories
end

function PLUGIN:GetEquippedAppearanceItems(character)
	local inventory = character and character:GetInventory()
	local equipped = {}

	if (!inventory) then
		return equipped
	end

	for _, item in pairs(inventory:GetItems()) do
		if (!item:GetData("equip")) then
			continue
		end

		if (item.RemoveOutfit or item.RemovePart or item.eqBodyGroups or item.bodyGroups or item.outfitCategory) then
			equipped[#equipped + 1] = item
		end
	end

	table.sort(equipped, function(a, b)
		local categoryA = GetAppearanceCategory(a)
		local categoryB = GetAppearanceCategory(b)

		if ((categoryA == "suit") ~= (categoryB == "suit")) then
			return categoryA != "suit"
		end

		return (a.id or 0) < (b.id or 0)
	end)

	return equipped
end

function PLUGIN:ForceUnequipAppearanceItem(item, player)
	if (item.RemoveOutfit and IsValid(player)) then
		item:RemoveOutfit(player)
	elseif (item.RemovePart and IsValid(player)) then
		item:RemovePart(player)
	else
		item:SetData("equip", false)
	end
end

function PLUGIN:StripEquippedAppearanceItems(character, player)
	local equippedItems = self:GetEquippedAppearanceItems(character)

	for _, item in ipairs(equippedItems) do
		self:ForceUnequipAppearanceItem(item, player)
	end

	return equippedItems
end

function PLUGIN:ApplyStoredAppearance(character, player)
	if (!character or !IsValid(player)) then
		return
	end

	local groups = self:FilterRestorableGroups(character, player, character:GetData("groups", {}))
	local skin = tonumber(character:GetData("skin", 0)) or 0

	player:ResetBodygroups()
	player:SetSkin(skin)

	for key, value in pairs(groups) do
		local index = isnumber(key) and key or player:FindBodygroupByName(key)

		if (index and index > -1) then
			player:SetBodygroup(index, tonumber(value) or 0)
		end
	end
end

function PLUGIN:GetResetModel(character, player)
	local faction = self:GetBaseAppearanceFaction(character)
	local currentModel = NormalizeModelPath(character and character:GetModel() or "")
	local wantsFemale = IsFemaleModel(currentModel)

	if (!faction) then
		return currentModel
	end

	if (istable(faction.genderModels)) then
		local genderKey = wantsFemale and "female" or "male"
		local models = faction.genderModels[genderKey]

		if (istable(models) and models[1]) then
			return models[1]
		end

		for _, fallbackKey in ipairs({"female", "male"}) do
			models = faction.genderModels[fallbackKey]

			if (istable(models) and models[1]) then
				return models[1]
			end
		end
	end

	if (istable(faction.models) and faction.models[1]) then
		if (wantsFemale) then
			for _, model in ipairs(faction.models) do
				if (IsFemaleModel(model)) then
					return model
				end
			end
		else
			for _, model in ipairs(faction.models) do
				if (!IsFemaleModel(model)) then
					return model
				end
			end
		end

		return faction.models[1]
	end

	return currentModel
end

function PLUGIN:ResetCharacterModel(target, client)
	local player = target:GetPlayer()

	if (!IsValid(player)) then
		client:NotifyLocalized("resetBodygroupsOnlineOnly")
		return false
	end

	local outfitsPlugin = ix.plugin.Get("better_outfits")

	self:StripEquippedAppearanceItems(target, player)

	if (outfitsPlugin) then
		outfitsPlugin:SetTemporaryOutfitModelOverride(target, nil)
	end

	local model = self:GetResetModel(target, player)

	if (isstring(model) and model != "") then
		target:SetModel(model)
		player:SetupHands()
	end

	self:ApplyStoredAppearance(target, player)
	target:Save()

	player:NotifyLocalized("resetModelTarget")
	client:NotifyLocalized("resetModelClient", target:GetName())
	return true
end

function PLUGIN:ResetCharacterSkin(target, client)
	local player = target:GetPlayer()

	if (!IsValid(player)) then
		client:NotifyLocalized("resetBodygroupsOnlineOnly")
		return false
	end

	local outfitsPlugin = ix.plugin.Get("better_outfits")

	self:StripEquippedAppearanceItems(target, player)
	target:SetData("skin", 0)
	target:SetData(ORIGINAL_SKIN_KEY, 0)

	if (outfitsPlugin) then
		outfitsPlugin:SetTemporaryOutfitSkinOverride(target, nil)
	end

	player:SetSkin(0)
	self:ApplyStoredAppearance(target, player)
	target:Save()

	player:NotifyLocalized("resetSkinTarget")
	client:NotifyLocalized("resetSkinClient", target:GetName())
	return true
end

function PLUGIN:ClearAppearanceStorage(character)
	if (!character) then
		return
	end

	character:SetData("groups", {})
	character:SetData("skin", 0)
	character:SetData(ORIGINAL_GROUPS_KEY, nil)
	character:SetData(ORIGINAL_SKIN_KEY, nil)

	for category in pairs(GetAppearanceCategories(character)) do
		character:SetData("oldGroups" .. category, nil)
		character:SetData("oldSkin" .. category, nil)
		character:SetData("oldModel" .. category, nil)
	end
end

function PLUGIN:ResetCharacterAppearance(target, client, forceClear)
	local player = target:GetPlayer()

	if (!IsValid(player)) then
		client:NotifyLocalized("resetBodygroupsOnlineOnly")
		return false
	end

	local hadOriginalAppearance = (target:GetData(ORIGINAL_GROUPS_KEY) != nil and target:GetData(ORIGINAL_SKIN_KEY) != nil)

	self:StripEquippedAppearanceItems(target, player)

	if (forceClear) then
		self:ClearAppearanceStorage(target)
	else
		target:SetData("groups", {})
		target:SetData("oldGroupsmodel", nil)
		target:SetData("oldGroupskevlar", nil)

		if (!hadOriginalAppearance) then
			self:EnsureOriginalAppearance(target, player)
		end
	end

	player:ResetBodygroups()
	player:SetSkin(0)

	if (!forceClear and !self:RestoreOriginalAppearance(target, player)) then
		player:SetSkin(tonumber(target:GetData("skin", player:GetSkin())) or 0)
	end

	player:NotifyLocalized(forceClear and "forceResetBodygroupsTarget" or "resetBodygroupsTarget")

	target:Save()
	client:NotifyLocalized(forceClear and "forceResetBodygroupsClient" or "resetBodygroupsClient", target:GetName())
	return true
end

function PLUGIN:FindOnlineCharacterByName(name)
	if (!isstring(name) or name == "" or !ix.char or !ix.char.loaded) then
		return nil
	end

	for _, character in pairs(ix.char.loaded) do
		if (character and character.GetName and character:GetName() == name and IsValid(character:GetPlayer())) then
			return character
		end
	end

	return nil
end

function PLUGIN:RestoreOriginalAppearance(character, player)
	local groups, skin = self:GetOriginalAppearance(character, player)

	if (groups == nil or skin == nil) then
		return false
	end

	groups = self:FilterRestorableGroups(character, player, groups)
	self:SetPersistentAppearance(character, groups, skin)

	if (!IsValid(player)) then
		return
	end

	player:ResetBodygroups()
	player:SetSkin(skin)

	for k, v in pairs(groups) do
		local index = isnumber(k) and k or player:FindBodygroupByName(k)

		if (index and index > -1) then
			player:SetBodygroup(index, tonumber(v) or 0)
		end
	end

	return true
end

function PLUGIN:CharacterLoaded(character)
	self:EnsureOriginalAppearance(character, character:GetPlayer())
end

ix.command.Add("CharEditBodygroup", {
	description = "@cmdEditBodygroup",
	adminOnly = true,
	arguments = {
		bit.bor(ix.type.player, ix.type.optional)
	},
	OnRun = function(self, client, target)
		target = target or client
	if (SERVER) then
			PLUGIN:EnsureOriginalAppearance(target:GetCharacter(), target)
		end

		if (HasEquippedOutfit(target:GetCharacter())) then
			client:NotifyLocalized("warnEquippedOutfit")
		end

		if (PLUGIN:HasEquippedModelChangingOutfit(target:GetCharacter())) then
			client:NotifyLocalized("temporaryBodygroupChanges")
		end

		net.Start("ixBodygroupView")
			net.WriteEntity(target)
		net.Send(client)
	end
})

ix.command.Add("CharResetBodygroups", {
	description = "@cmdCharResetBodygroups",
	adminOnly = true,
	arguments = {
		ix.type.character
	},
	OnRun = function(self, client, target)
		if (!IsValid(target:GetPlayer())) then
			client:NotifyLocalized("resetBodygroupsOnlineOnly")
			return
		end

		PLUGIN:ResetCharacterAppearance(target, client, false)
	end
})

ix.command.Add("CharResetModel", {
	description = "@cmdCharResetModel",
	adminOnly = true,
	arguments = {
		ix.type.character
	},
	OnRun = function(self, client, target)
		if (!IsValid(target:GetPlayer())) then
			client:NotifyLocalized("resetBodygroupsOnlineOnly")
			return
		end

		PLUGIN:ResetCharacterModel(target, client)
	end
})

ix.command.Add("CharResetSkin", {
	description = "@cmdCharResetSkin",
	adminOnly = true,
	arguments = {
		ix.type.character
	},
	OnRun = function(self, client, target)
		if (!IsValid(target:GetPlayer())) then
			client:NotifyLocalized("resetBodygroupsOnlineOnly")
			return
		end

		PLUGIN:ResetCharacterSkin(target, client)
	end
})

ix.command.Add("CharForceResetBodygroups", {
	description = "@cmdCharForceResetBodygroups",
	adminOnly = true,
	arguments = {
		ix.type.string,
		ix.type.bool
	},
	syntax = "\"<exact name>\" true",
	OnRun = function(self, client, targetName, bConfirm)
		if (!bConfirm) then
			client:NotifyLocalized("forceResetBodygroupsConfirm")
			return
		end

		local target = PLUGIN:FindOnlineCharacterByName(targetName)

		if (!target) then
			client:NotifyLocalized("forceResetBodygroupsNotFound")
			return
		end

		if (target:GetName() != targetName) then
			client:NotifyLocalized("forceResetBodygroupsNameMismatch")
			return
		end

		PLUGIN:ResetCharacterAppearance(target, client, true)
	end
})

ix.command.Add("Bodygroup", {
	description = "@cmdBodygroup",
	OnRun = function(self, client)
		local character = client:GetCharacter()

		if (!character or !character:HasFlags("b")) then
			return "@flagNoMatch", "b"
		end

		if (SERVER) then
			PLUGIN:EnsureOriginalAppearance(character, client)
		end

		if (HasEquippedOutfit(character)) then
			client:NotifyLocalized("warnEquippedOutfit")
		end

		if (PLUGIN:HasEquippedModelChangingOutfit(character)) then
			client:NotifyLocalized("temporaryBodygroupChanges")
		end

		net.Start("ixBodygroupView")
			net.WriteEntity(client)
		net.Send(client)
	end
})

ix.command.Add("Skin", {
	description = "@cmdSkin",
	OnRun = function(self, client)
		local character = client:GetCharacter()

		if (!character or !character:HasFlags("s")) then
			return "@flagNoMatch", "s"
		end

		if (SERVER) then
			PLUGIN:EnsureOriginalAppearance(character, client)
		end

		if (HasEquippedOutfit(character)) then
			client:NotifyLocalized("warnEquippedOutfit")
		end

		if (PLUGIN:HasEquippedModelChangingOutfit(character)) then
			client:NotifyLocalized("temporaryBodygroupChanges")
		end

		net.Start("ixBodygroupView")
			net.WriteEntity(client)
		net.Send(client)
	end
})

properties.Add("ixEditBodygroups", {
	MenuLabel = "#Edit Bodygroups",
	Order = 10,
	MenuIcon = "icon16/user_edit.png",

	Filter = function(self, entity, client)
		if (!entity:IsPlayer() or !entity:GetCharacter()) then return false end

		if (ix.command.HasAccess(client, "CharEditBodygroup")) then
			return true
		end

		if (entity == client) then
			local character = client:GetCharacter()
			return character:HasFlags("b") or character:HasFlags("s")
		end

		return false
	end,

	Action = function(self, entity)
		if (HasEquippedOutfit(entity:GetCharacter())) then
			if (CLIENT) then
				ix.util.Notify(L("warnEquippedOutfit"))
			end
		end

		if (PLUGIN:HasEquippedModelChangingOutfit(entity:GetCharacter())) then
			if (CLIENT) then
				ix.util.Notify(L("temporaryBodygroupChanges"))
			end
		end

		local panel = vgui.Create("ixBodygroupView")
		panel:Display(entity)
	end
})

ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_hooks.lua")

ix.command.Add("CharSetBodygroup", {
	description = "@cmdCharSetBodygroup",
	adminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.string,
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, target, bodygroup, value)
		PLUGIN:EnsureOriginalAppearance(target, target:GetPlayer())

		local index = target:GetPlayer():FindBodygroupByName(bodygroup)

		if (index > -1) then
			if (value and value < 1) then
				value = nil
			end

			local player = target:GetPlayer()
			local modelChangingOutfit = PLUGIN:HasEquippedModelChangingOutfit(target)
			local allowed = PLUGIN:GetEditableBodygroupValues(target, player, {[index] = value or 0})

			if (table.IsEmpty(allowed)) then
				client:NotifyLocalized("temporaryBodygroupChanges")
				return
			end

			if (!modelChangingOutfit) then
				local groups = target:GetData("groups", {})
				groups[index] = value
				PLUGIN:SetPersistentAppearance(target, groups)
			else
				client:NotifyLocalized("temporaryBodygroupChanges")
			end

			target:GetPlayer():SetBodygroup(index, value or 0)

			ix.util.NotifyLocalized("cChangeGroups", nil, client:GetName(), target:GetName(), bodygroup, value or 0)
		else
			return "@invalidArg", 2
		end
	end
})
