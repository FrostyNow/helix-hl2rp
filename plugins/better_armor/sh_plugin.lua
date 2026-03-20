local PLUGIN = PLUGIN
PLUGIN.name = "Better Armor"
PLUGIN.author = "Subleader, Alex Grist | Modified by Frosty"
PLUGIN.desc = "Compatible with bad air and localized damage, plus it adds damage resistance."

ix.lang.AddTable("english", {
	gasmaskRemoved = "You have removed your gasmask",
	gasmaskEquipped = "You have put on your gasmask.",
	repairToolsDesc = "Some tools for repairing armour.",
	hazmatSuitDesc = "A military protective clothing that protects wearers from harmful environments.",
	hazmatSuitCitizenDesc = "A protective clothing that protects wearers from harmful environments.",
	pasgtBodyArmorDesc = "A Kebler-fiber bulletproof vest that the U.S. Army adopted in 1983 to replace M69 Flak Vest.",
	pasgtHelmetDesc = "A Kebler-fiber bulletproof helmet that the U.S. Army adopted in 1983 to replace the M1 steel helmet.",
	durabilityDesc = "\n \n Durability:",
	bulletproof = "\n \nDamage Resistance: \n  Bulletproof: ",
	stabProof = "\n  Stab Proof: ",
	electricResistance = "\n  Electric Resistance: ",
	fireResistance = "\n  Fire Resistance: ",
	radiationResistance = "\n  Radiation Resistance: ",
	poisonResistance = "\n  Poison Resistance: ",
	shockResistance = "\n  Shock Resistance: ",
	cp_vest_desc = "A Civil Protection bulletproof vest.",
	cp_vest_medic_desc = "A Civil Protection bulletproof vest with a red cross medic bag.",
	cp_vest_rebel_desc = "A Civil Protection bulletproof vest with a backpack attached.",
	cp_vest_mpf_desc = "A standard-issue Civil Protection ballistic vest sized for metropolice uniforms.",
	combat_vest_desc = "A combat vest with limited ballistic protection.",
	molle_vest_desc = "A ballistic combat vest equipped with MOLLE storage pouches.",
	overwatch_vest_desc = "A bulletproof vest made from the equipment of the Overwatch Transhuman Arm.",
	flak_jacket_desc = "A protective vest designed to shield against fragmentation and shrapnel.",
})
ix.lang.AddTable("korean", {
	["Intelligence"] = "지능",
	gasmaskRemoved = "방독면 착용을 해제했습니다.",
	gasmaskEquipped = "방독면을 착용했습니다.",
	Repair = "수리하기",
	["Repair Tools"] = "수리 공구",
	repairToolsDesc = "방어구의 수리에 쓰이는 공구를 모아두었습니다.",
	["Hazmat Suit"] = "방호복",
	hazmatSuitDesc = "유해한 환경으로부터 착용자를 보호하는 군용 방호복입니다.",
	hazmatSuitCitizenDesc = "유해한 환경으로부터 착용자를 보호하는 방호복입니다.",
	["PASGT Vest"] = "PASGT 방탄복",
	pasgtBodyArmorDesc = "1983년 미군이 M69 방편복을 대체하여 채용한 케블러 섬유 소재 방탄복입니다.",
	["PASGT Helmet"] = "PASGT 방탄모",
	pasgtHelmetDesc = "1983년 미군이 M1 철모를 대체하여 채용한 케블러 섬유 소재 방탄모입니다.",
	durabilityDesc = "\n \n 내구도:",
	bulletproof = "\n \n피해 저항: \n  방탄: ",
	stabProof = "\n  방검: ",
	electricResistance = "\n  전격 저항: ",
	fireResistance = "\n  화염 저항: ",
	radiationResistance = "\n  방사선 피폭 저항: ",
	poisonResistance = "\n  독성 저항: ",
	shockResistance = "\n  충격 저항: ",
	["CP Armor Vest"] = "시민 보호 기동대 방탄 조끼",
	cp_vest_desc = "시민 보호 기동대에게 지급되는 제식 방탄 조끼입니다.",
	["CP Vest with Medic Bag"] = "시민 보호 기동대 방탄 조끼 (저항군 의무병)",
	cp_vest_medic_desc = "시민 보호 기동대에게 지급되는 제식 방탄 조끼에 적십자가 있는 의무병 가방을 갖췄습니다.",
	["CP Vest with Bag"] = "시민 보호 기동대 방탄 조끼 (저항군)",
	cp_vest_rebel_desc = "시민 보호 기동대에게 지급되는 제식 방탄 조끼에 가방을 갖췄습니다.",
	cp_vest_mpf_desc = "시민 보호 기동대 제복 위에 장착하도록 만들어진 제식 방탄 조끼입니다.",
	["Combat Vest"] = "전투 조끼",
	combat_vest_desc = "제한적인 방탄 성능이 있는 전투 조끼입니다.",
	["Combat Helmet"] = "우드랜드 방탄모",
	combat_helmet_desc = "우드랜드 위장무늬 천을 씌운 방탄모입니다.",
	["Molle Vest"] = "MOLLE 방탄 조끼",
	molle_vest_desc = "7시간 전쟁 전 군인에게 지급되었던 수납 기능이 있는 방탄 전투조끼입니다.",
	["Overwatch Vest"] = "감시부대 방탄 조끼",
	overwatch_vest_desc = "감시인 신인류 부대의 제식 장비를 벗겨내서 만든 방탄 조끼입니다.",
	["Flak Jacket"] = "방편복",
	flak_jacket_desc = "파편을 방호할 수 있는 조끼입니다.",
})

ix.util.Include("cl_plugin.lua")

local function GetArmorProtectionInfo(client, hitgroup, dmginfo)
	if (!IsValid(client) or !client:IsPlayer()) then
		return 1, false
	end

	local character = client:GetCharacter()

	if (!character) then
		return 1, false
	end

	local inventory = character:GetInventory()

	if (!inventory) then
		return 1, false
	end

	local items = inventory:GetItems()
	local bestScale = 1
	local hitgroupProtected = false

	for _, item in pairs(items) do
		if (item:GetData("equip") != true or item.base != "base_armor" or !item.resistance) then
			continue
		end

		if (item.hitGroups and !table.HasValue(item.hitGroups, hitgroup or 0)) then
			continue
		end

		local durability = item:GetData("Durability", item.maxDurability)
		local fraction = durability <= 0 and 0.5 or 1
		local dmg = item.damage or {1, 1, 1, 1, 1, 1, 1}
		local scale = 1
		local validType = false

		if (dmginfo:IsDamageType(DMG_BULLET)) then
			validType = true
			scale = dmg[1]
		elseif (dmginfo:IsDamageType(DMG_SLASH) or dmginfo:IsDamageType(DMG_CLUB)) then
			validType = true
			scale = dmg[2]
		end

		if (!validType) then
			continue
		end

		scale = scale * fraction + (1 - fraction)

		if (scale < bestScale) then
			bestScale = scale
			hitgroupProtected = scale < 1
		end
	end

	return bestScale, hitgroupProtected
end

function PLUGIN:EntityTakeDamage( target, dmginfo )
	if ( target:IsPlayer() ) then
		if ( target:GetNetVar("resistance") == true ) then
			if (dmginfo:IsDamageType(DMG_SHOCK)) then
				dmginfo:ScaleDamage(target:GetNWFloat("dmg_shock"))
			elseif (dmginfo:IsDamageType(DMG_BURN)) then
				dmginfo:ScaleDamage(target:GetNWFloat("dmg_burn"))
			elseif (dmginfo:IsDamageType(DMG_RADIATION)) then
				dmginfo:ScaleDamage(target:GetNWFloat("dmg_radiation"))
			elseif (dmginfo:IsDamageType(DMG_ACID)) then
				dmginfo:ScaleDamage(target:GetNWFloat("dmg_acid"))
			elseif (dmginfo:IsExplosionDamage()) then
				dmginfo:ScaleDamage(target:GetNWFloat("dmg_explosive"))
			end
		end
	end
end

function PLUGIN:PlayerTraceAttack(client, dmginfo, dir, trace)
	if (!SERVER or !IsValid(client) or !client:IsPlayer()) then
		return
	end

	if (!dmginfo:IsDamageType(DMG_BULLET)) then
		return
	end

	local hitgroup = trace and trace.HitGroup or HITGROUP_GENERIC
	local _, hitgroupProtected = GetArmorProtectionInfo(client, hitgroup, dmginfo)

	if (!hitgroupProtected or !trace or !trace.Hit) then
		return
	end

	local hitNormal = trace.HitNormal or (-dir)

	local sparkEffect = EffectData()
	sparkEffect:SetOrigin(trace.HitPos)
	sparkEffect:SetNormal(hitNormal)
	util.Effect("MetalSpark", sparkEffect, true, true)

	local impactEffect = EffectData()
	impactEffect:SetOrigin(trace.HitPos)
	impactEffect:SetNormal(hitNormal)
	util.Effect("StunstickImpact", impactEffect, true, true)
end

function PLUGIN:ScalePlayerDamage(client, hitgroup, dmginfo)
	local bestScale, hitgroupProtected = GetArmorProtectionInfo(client, hitgroup, dmginfo)

	if (CLIENT and hitgroupProtected and dmginfo:IsDamageType(DMG_BULLET)) then
		return true
	end

	if (hitgroupProtected) then
		dmginfo:ScaleDamage(bestScale)

		if (SERVER and dmginfo:IsDamageType(DMG_BULLET)) then
			if (hitgroup == HITGROUP_HEAD) then
				client:EmitSound("player/bhit_helmet-1.wav")
			else
				client:EmitSound("player/kevlar" .. math.random(1, 5) .. ".wav")
			end
		end
	elseif (SERVER and dmginfo:IsDamageType(DMG_BULLET) and hitgroup == HITGROUP_HEAD) then
		client:EmitSound("player/headshot" .. math.random(1, 2) .. ".wav")
	end
end

function PLUGIN:PlayerHurt( client, attacker, health, damageTaken )
	if (client:IsPlayer()) then
		local character = client:GetCharacter()
		local inventory = character:GetInventory()
		local items = inventory:GetItems()
		
		local hitgroup = client:LastHitGroup()

		for k, v in pairs(items) do
			if (v:GetData("equip")) then
				if (v.base == "base_armor" and v.resistance) then
					-- Durability loss only if hitgroup matches
					if (v.hitGroups and !table.HasValue(v.hitGroups, hitgroup or 0)) then
						continue
					end

					local durability = v:GetData("Durability", 100)
					
					if (durability > 0) then
						v:SetData("Durability", math.max(durability - (damageTaken/2)))
					elseif (durability <= 0) then
						v:SetData("Durability", 0)
					end
					
					if (v.UpdateResistance) then
						v:UpdateResistance(client)
					end
				end
			end
		end
	end
end

-- ix.command.Add("Gasmask", {
-- 	description = "Wear or unwear your gasmask.",
-- 	adminOnly = false,
-- 	OnRun = function(self, client)
-- 		local character = client:GetCharacter()
-- 		local inventory = character:GetInventory()
-- 		local items = inventory:GetItems()
-- 		for k, v in pairs(items) do
-- 			if (v.gasmask == true) then
-- 				if client:GetNetVar("gasmask") then
-- 					client:SetNetVar("gasmask", false)
-- 					client:NotifyLocalized("gasmaskRemoved")
-- 				else
-- 					client:SetNetVar("gasmask", true)
-- 					client:NotifyLocalized("gasmaskEquipped")
-- 				end
-- 			end
-- 		end
-- 	end
-- })

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
			if (item.IsCompatibleWith and !item:IsCompatibleWith(currentModel) and !IsModelChangingItem(item)) then
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
	if (!character) then
		return false
	end

	for key, value in pairs(character:GetData()) do
		if (isstring(key) and key:sub(1, 8) == "oldModel" and value != nil) then
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

	for i = 0, client:GetNumBodyGroups() - 1 do
		client:SetBodygroup(i, 0)
	end

	local currentModel = NormalizeModel(client:GetModel())
	local isOverridden = self:IsModelOverridden(character)
	local baseGroups = character:GetData("groups", {})

	for key, value in pairs(baseGroups) do
		local index = -1

		if (isnumber(key)) then
			if (!isOverridden) then
				index = key
			else
				continue
			end
		else
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
			for _, item in pairs(inv:GetItems()) do
				table.insert(items, item)
			end
		end
	end

	for _, item in pairs(items) do
		if (item:GetData("equip") and item.eqBodyGroups) then
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

function PLUGIN:CanPlayerUnequipItem(client, item)
end

function PLUGIN:CanTransferItem(item, curInv, inventory)
end

function PLUGIN:CanPlayerInteractItem(client, action, item, data)
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
