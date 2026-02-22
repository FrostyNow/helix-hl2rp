local PLUGIN = PLUGIN
PLUGIN.name = "Better Armor"
PLUGIN.author = "Subleader, Alex Grist, and Frosty"
PLUGIN.desc = "Compatible with bad air and localized damage, plus it adds damage resistance."

ix.lang.AddTable("english", {
	gasmaskRemoved = "You have removed your gasmask",
	gasmaskEquipped = "You have put on your gasmask.",
	repairToolsDesc = "Some tools for repairing armour.",
	hatDesc = "A cap worn by the military personnel in the field when a combat helmet is not required.\n(CONSCRIPT MODELS ONLY)",
	hazmatSuitDesc = "A military protective clothing that protects wearers from harmful environments.\n(MALE CONSCRIPT MODELS ONLY)",
	hazmatSuitCitizenDesc = "A protective clothing that protects wearers from harmful environments.",
	pasgtBodyArmorDesc = "A Kebler-fiber bulletproof vest that the U.S. Army adopted in 1983 to replace M69 Flak Vest.\n(CONSCRIPT MODELS ONLY)",
	pasgtHelmetDesc = "A Kebler-fiber bulletproof helmet that the U.S. Army adopted in 1983 to replace the M1 steel helmet.\n(MALE CONSCRIPT MODELS ONLY)",
	durabilityDesc = "\n \n Durability:",
	bulletproof = "\n \nDamage Resistance: \n  Bulletproof: ",
	stabProof = "\n  Stab Proof: ",
	electricResistance = "\n  Electric Resistance: ",
	fireResistance = "\n  Fire Resistance: ",
	radiationResistance = "\n  Radiation Resistance: ",
	poisonResistance = "\n  Poison Resistance: ",
	shockResistance = "\n  Shock Resistance: ",
	cannotActionWhileSuit = "You cannot unequip, drop, or move this item while wearing a suit.",
})
ix.lang.AddTable("korean", {
	["Intelligence"] = "지능",
	gasmaskRemoved = "방독면 착용을 해제했습니다.",
	gasmaskEquipped = "방독면을 착용했습니다.",
	Repair = "수리하기",
	["Repair Tools"] = "수리 공구",
	repairToolsDesc = "방어구의 수리에 쓰이는 공구를 모아두었습니다.",
	["Field Cap"] = "전투모",
	hatDesc = "군인이 평상시에 착용하도록 만든 모자입니다.\n(징집군 모델 전용)",
	["Hazmat Suit"] = "방호복",
	hazmatSuitDesc = "유해한 환경으로부터 착용자를 보호하는 군용 방호복입니다.\n(남성 징집군 모델 전용)",
	hazmatSuitCitizenDesc = "유해한 환경으로부터 착용자를 보호하는 방호복입니다.",
	["PASGT Vest"] = "PASGT 방탄복",
	pasgtBodyArmorDesc = "1983년 미군이 M69 방편복을 대체하여 채용한 케블러 섬유 소재 방탄복입니다.\n(징집군 모델 전용)",
	["PASGT Helmet"] = "PASGT 방탄모",
	pasgtHelmetDesc = "1983년 미군이 M1 철모를 대체하여 채용한 케블러 섬유 소재 방탄모입니다.\n(남성 징집군 모델 전용)",
	durabilityDesc = "\n \n 내구도:",
	bulletproof = "\n \n피해 저항: \n  방탄: ",
	stabProof = "\n  방검: ",
	electricResistance = "\n  전격 저항: ",
	fireResistance = "\n  화염 저항: ",
	radiationResistance = "\n  방사선 피폭 저항: ",
	poisonResistance = "\n  독성 저항: ",
	shockResistance = "\n  충격 저항: ",
	cannotActionWhileSuit = "전신 의상을 입고 있는 동안에는 이 아이템을 벗거나, 버리거나, 옮길 수 없습니다.",
})

ix.util.Include("cl_plugin.lua")

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

function PLUGIN:ScalePlayerDamage(client, hitgroup, dmginfo)
	if (!client:GetCharacter()) then return end
	local character = client:GetCharacter()
	if (!character:GetInventory()) then return end
	local inventory = character:GetInventory()
	local items = inventory:GetItems()
	
	local bestScale = 1
	local foundArmor = false

	for k, v in pairs(items) do
		if (v:GetData("equip") and v.base == "base_armor" and v.resistance) then
			-- Check if item covers this hitgroup
			-- If hitGroups is nil, it covers everything (backward compatibility/suits)
			if (v.hitGroups and !table.HasValue(v.hitGroups, hitgroup or 0)) then
				continue
			end

			local durability = v:GetData("Durability", v.maxDurability)
			local fraction = 1
	
			if (durability <= 0) then
				fraction = 0.5
			end
	
			local function GetEffectiveScale(base, frac)
				return base * frac + (1 - frac)
			end
			
			local dmg = v.damage or {1,1,1,1,1,1,1}
			local scale = 1

			if (dmginfo:IsDamageType(DMG_BULLET)) then
				foundArmor = true
				scale = dmg[1]
			elseif (dmginfo:IsDamageType(DMG_SLASH)) then
				foundArmor = true
				scale = dmg[2]
			elseif (dmginfo:IsDamageType(DMG_CLUB)) then
				foundArmor = true
				scale = dmg[2] -- Treat club as slash/melee
			end
			
			if (foundArmor) then
				scale = GetEffectiveScale(scale, fraction)
				if (scale < bestScale) then
					bestScale = scale
				end
			end
		end
	end

	if (foundArmor) then
		dmginfo:ScaleDamage(bestScale)
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

function PLUGIN:CanPlayerUnequipItem(client, item)
	local itemTable = ix.item.list[item.uniqueID]
	local category = item.outfitCategory or (itemTable and itemTable.outfitCategory)

	if (category != "suit" and IsWearingSuit(client)) then
		client:NotifyLocalized("cannotActionWhileSuit")
		return false
	end
end

function PLUGIN:CanTransferItem(item, curInv, inventory)
	if (item:GetData("equip")) then
		local client = item.player or item:GetOwner() or (CLIENT and LocalPlayer() or nil)
		if (IsValid(client)) then
			local itemTable = ix.item.list[item.uniqueID]
			local category = item.outfitCategory or (itemTable and itemTable.outfitCategory)
			
			if (category != "suit" and IsWearingSuit(client)) then
				-- We can't easily notify here without spamming during drag, 
				-- but item:Transfer will handle the notification if it fails via an action.
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

		-- Only block if the item being actioned is EQUIPPED and isn't a suit itself
		if (category != "suit" and itemInstance:GetData("equip") and IsWearingSuit(client)) then
			client:NotifyLocalized("cannotActionWhileSuit")
			return false
		end
	end
end
