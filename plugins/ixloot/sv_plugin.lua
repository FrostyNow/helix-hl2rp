local PLUGIN = PLUGIN

function PLUGIN:GetRandomItem(lootTable)
	local totalWeight = 0

	for _, weight in pairs(lootTable) do
		totalWeight = totalWeight + weight
	end

	local randomValue = math.random(0, totalWeight)
	local currentWeight = 0

	print(randomValue)

	for item, weight in pairs(lootTable) do
		currentWeight = currentWeight + weight

		if (randomValue <= currentWeight) then
			return item
		end
	end
end

-- messy but idc.
function PLUGIN:SearchLootContainer(ent, ply)
	if not ( ply:IsCombine() ) then
		if not ent.containerAlreadyUsed or ent.containerAlreadyUsed <= CurTime() then
			if not ( ply.isEatingConsumeable == true ) then -- support for my plugin
				local randomChance = math.random(1,20)
				local randomAmountChance = math.random(1,3)
				local lootAmount = 1

				local randomLootItem = self:GetRandomItem(PLUGIN.randomLoot.common)
				if ( randomAmountChance == 3 ) then
					lootAmount = math.random(1,3)
				else
					lootAmount = 1
				end

				-- ply:Freeze(true)
				ply:SetAction("@storageSearching", 5)
				ply:DoStaredAction(ent, function()
					-- ply:Freeze(false)
					for i = 1, lootAmount do
						if (randomChance == math.random(1,20)) then
							randomLootItem = self:GetRandomItem(PLUGIN.randomLoot.rare)
							if !ix.item.Get(randomLootItem) then return print("Item not found: " .. randomLootItem) end

							ply:NotifyLocalized("ixlootGained", L(ix.item.Get(randomLootItem):GetName(), ply))
							ply:GetCharacter():GetInventory():Add(randomLootItem)
						else
							randomLootItem = self:GetRandomItem(PLUGIN.randomLoot.common)
							if !ix.item.Get(randomLootItem) then return print("Item not found: " .. randomLootItem) end
							
							ply:NotifyLocalized("ixlootGained", L(ix.item.Get(randomLootItem):GetName(), ply))
							ply:GetCharacter():GetInventory():Add(randomLootItem)
						end
					end

					ent.containerAlreadyUsed = CurTime() + 180
				end, 5, function()
					ply:SetAction(false)
				end)
			else
				if not ent.ixContainerNotAllowedEat or ent.ixContainerNotAllowedEat <= CurTime() then
					ply:NotifyLocalized("ixlootNotEating")
					ent.ixContainerNotAllowedEat = CurTime() + 1
				end
			end
		else
			if not ent.ixContainerNothingInItCooldown or ent.ixContainerNothingInItCooldown <= CurTime() then
				ply:NotifyLocalized("ixlootNoItem")
				ent.ixContainerNothingInItCooldown = CurTime() + 1
			end
		end
	else
		if not ent.ixContainerNotAllowed or ent.ixContainerNotAllowed <= CurTime() then
			ply:NotifyLocalized("ixlootNotFaction")
			ent.ixContainerNotAllowed = CurTime() + 1
		end
	end
end

function Schema:SpawnRandomLoot(position, rareItem)
	local randomLootItem = PLUGIN:GetRandomItem(PLUGIN.randomLoot.common)

	if (rareItem == true) then
		randomLootItem = PLUGIN:GetRandomItem(PLUGIN.randomLoot.rare)
	end

	ix.item.Spawn(randomLootItem, position)
end


function PLUGIN:SaveData()
	local data = {}

	local entities = {
		"ix_loot_barrel",
		"ix_loot_crate",
		"ix_loot_dumpster",
		"ix_loot_filecabinet",
		"ix_loot_trashcan",
		"ix_loot_trashbin",
		"ix_loot_locker",
	}

	for _, class in ipairs(entities) do
		for _, v in ipairs(ents.FindByClass(class)) do
			data[#data + 1] = {
				class = class,
				pos = v:GetPos(),
				angles = v:GetAngles(),
				skin = v:GetSkin()
			}
		end
	end

	self:SetData(data)
end

function PLUGIN:LoadData()
	local data = self:GetData()

	if (data) then
		for _, v in ipairs(data) do
			local entity = ents.Create(v.class)
			entity:SetPos(v.pos)
			entity:SetAngles(v.angles)
			entity:SetSkin(v.skin)
			entity:Spawn()
		end
	end
end