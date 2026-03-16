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
	cannotActionWhileSuit = "You cannot unequip, drop, or move this item while wearing a suit.",
	cannotRemoveSuitWithEquipment = "You must remove any extra outfit or armor pieces before removing the suit.",
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
	cannotActionWhileSuit = "전신 의상을 입고 있는 동안에는 이 아이템을 벗거나, 버리거나, 옮길 수 없습니다.",
	cannotRemoveSuitWithEquipment = "전신 의상을 벗으려면 먼저 추가로 착용한 의상이나 방어구를 모두 해제해야 합니다.",
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

local function IsWearingSuit(client)
	if (!IsValid(client)) then return false end
	local char = client:GetCharacter()
	if (!char) then return false end
	local inv = char:GetInventory()
	if (!inv) then return false end

	for _, v in pairs(inv:GetItems()) do
		if (v:GetData("equip")) then
			local itemTable = ix.item.list[v.uniqueID]
			local category = v.outfitCategory or (itemTable and itemTable.outfitCategory)
			if (category == "suit") then
				return true
			end
		end
	end
	return false
end

local function GetOutfitCategory(item)
	local itemTable = ix.item.list[item.uniqueID]
	return item.outfitCategory or (itemTable and itemTable.outfitCategory)
end

local function HasEquippedOutfitLayers(client, ignoreItemID)
	if (!IsValid(client)) then return false end

	local char = client:GetCharacter()
	local inv = char and char:GetInventory()

	if (!inv) then return false end

	for _, v in pairs(inv:GetItems()) do
		if (v.id == ignoreItemID or !v:GetData("equip")) then
			continue
		end

		local category = GetOutfitCategory(v)

		if (category and category != "suit") then
			return true
		end
	end

	return false
end

function PLUGIN:CanPlayerUnequipItem(client, item)
	local category = GetOutfitCategory(item)

	if (category == "suit" and HasEquippedOutfitLayers(client, item.id)) then
		client:NotifyLocalized("cannotRemoveSuitWithEquipment")
		return false
	end
end

function PLUGIN:CanTransferItem(item, curInv, inventory)
	if (item:GetData("equip")) then
		local client = item.player or item:GetOwner() or (CLIENT and LocalPlayer() or nil)
		if (IsValid(client)) then
			local category = GetOutfitCategory(item)
			
			if (category == "suit" and HasEquippedOutfitLayers(client, item.id)) then
				return false
			end
		end
	end
end

function PLUGIN:CanPlayerInteractItem(client, action, item, data)
	if (action == "drop" or action == "EquipUn") then
		local itemInstance = item
		if (isnumber(item)) then
			itemInstance = ix.item.instances[item]
		end

		if (!itemInstance) then return end

		local itemTable = ix.item.list[itemInstance.uniqueID]
		local category = itemInstance.outfitCategory or (itemTable and itemTable.outfitCategory)

		if (category == "suit" and itemInstance:GetData("equip") and HasEquippedOutfitLayers(client, itemInstance.id)) then
			client:NotifyLocalized("cannotRemoveSuitWithEquipment")
			return false
		end
	end
end
