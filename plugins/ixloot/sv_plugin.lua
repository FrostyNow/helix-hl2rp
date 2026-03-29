local PLUGIN = PLUGIN

local SEARCH_DURATION = 5
local SEARCH_SOUND_INTERVAL = 0.85
local SEARCH_BED_INTERVAL = 0.27

local metalSearchSounds = {
	"physics/metal/metal_barrel_impact_soft1.wav",
	"physics/metal/metal_barrel_impact_soft2.wav",
	"physics/metal/metal_barrel_impact_soft3.wav"
}

local woodSearchSounds = {
	"physics/wood/wood_crate_impact_soft2.wav",
	"physics/wood/wood_crate_impact_soft3.wav",
	"physics/wood/wood_crate_impact_soft4.wav"
}

local cardboardSearchSounds = {
	"physics/cardboard/cardboard_box_impact_soft1.wav",
	"physics/cardboard/cardboard_box_impact_soft2.wav",
	"physics/cardboard/cardboard_box_impact_soft3.wav"
}

local searchBedSounds = {
	"npc/zombie/foot_slide1.wav",
	"npc/zombie/foot_slide2.wav",
	"npc/zombie/foot_slide3.wav"
}

function PLUGIN:GetLootSearchSounds(ent)
	local model = string.lower(tostring(ent:GetModel() or ""))
	local class = string.lower(tostring(ent:GetClass() or ""))

	if (
		model:find("crate", 1, true) and !model:find("ammocrate", 1, true)
	) then
		return woodSearchSounds
	end

	if (
		model:find("trash", 1, true) or
		model:find("dumpster", 1, true) or
		class:find("trash", 1, true) or
		class:find("dumpster", 1, true)
	) then
		return cardboardSearchSounds
	end

	return metalSearchSounds
end

function PLUGIN:PlayLootSearchSound(ent)
	if (!IsValid(ent)) then
		return
	end

	local sounds = self:GetLootSearchSounds(ent)
	local soundPath = sounds[math.random(1, #sounds)]

	ent:EmitSound(soundPath, 60, math.random(95, 108), 0.75)
end

function PLUGIN:StopLootSearchSound(ply)
	if (!ply) then
		return
	end

	local timerIDs = {
		ply.ixLootSearchSoundTimer,
		ply.ixLootSearchBedTimer
	}

	for _, timerID in ipairs(timerIDs) do
		if (!timerID) then
			continue
		end

		timer.Remove(timerID)
	end

	ply.ixLootSearchSoundTimer = nil
	ply.ixLootSearchBedTimer = nil
end

function PLUGIN:StartLootSearchSound(ent, ply)
	self:StopLootSearchSound(ply)

	local timerID = "ixLootSearchSound" .. ply:SteamID64()
	local bedTimerID = "ixLootSearchBed" .. ply:SteamID64()
	ply.ixLootSearchSoundTimer = timerID
	ply.ixLootSearchBedTimer = bedTimerID

	self:PlayLootSearchSound(ent)

	timer.Create(timerID, SEARCH_SOUND_INTERVAL, 0, function()
		if (!IsValid(ply)) then
			timer.Remove(timerID)
			return
		end

		if (!IsValid(ent) or ply.ixLootSearchSoundTimer != timerID) then
			self:StopLootSearchSound(ply)
			return
		end

		self:PlayLootSearchSound(ent)
	end)

	timer.Create(bedTimerID, SEARCH_BED_INTERVAL, 0, function()
		if (!IsValid(ply)) then
			timer.Remove(bedTimerID)
			return
		end

		if (!IsValid(ent) or ply.ixLootSearchBedTimer != bedTimerID) then
			self:StopLootSearchSound(ply)
			return
		end

		ent:EmitSound(searchBedSounds[math.random(1, #searchBedSounds)], 45, math.random(88, 104), 0.18)
	end)
end

function PLUGIN:GetRandomItem(lootTable)
	local totalWeight = 0
	local processedTable = {}

	for k, v in pairs(lootTable) do
		local itemID
		local weight

		if (type(v) == "number") then
			itemID = k
			weight = v
		elseif (type(v) == "string") then
			itemID = v
			local itemTable = ix.item.list[itemID]
			local price = (itemTable and itemTable.price) or 10
			weight = math.Clamp(math.floor(100 / math.max(1, price)), 1, 100)
		end

		if (itemID and weight) then
			totalWeight = totalWeight + weight
			processedTable[itemID] = (processedTable[itemID] or 0) + weight
		end
	end

	if (totalWeight <= 0) then
		return
	end

	local randomValue = math.random(1, totalWeight)
	local currentWeight = 0

	for item, weight in pairs(processedTable) do
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

				ply:SetAction("@storageSearching", SEARCH_DURATION)
				self:StartLootSearchSound(ent, ply)
				ply:SetNetVar("isSearchingLoot", true)

				ply:DoStaredAction(ent, function()
					ply:SetNetVar("isSearchingLoot", false)
					self:StopLootSearchSound(ply)

					local character = ply:GetCharacter()
					local lck = character:GetAttribute("lck", 0)
					local multiplier = ix.config.Get("luckMultiplier", 1)
					
					local firstItemChance = 50 + (lck * multiplier)
					local extraItemChance = 30 + (lck * multiplier)

					if (math.random(1, 100) <= firstItemChance) then
						local function GiveItem()
							local rareChance = 1 + math.min(lck * multiplier, 10)
							local randomLootItem

							if (math.random(1, 100) <= rareChance) then
								randomLootItem = self:GetRandomItem(PLUGIN.randomLoot.rare)
							else
								randomLootItem = self:GetRandomItem(PLUGIN.randomLoot.common)
							end

							if (randomLootItem and ix.item.Get(randomLootItem)) then
								local name = L(ix.item.Get(randomLootItem):GetName(), ply)

								if (character:GetInventory():Add(randomLootItem)) then
								else
									ix.item.Spawn(randomLootItem, ply)
								end
								ply:NotifyLocalized("ixlootGained", name)
							end
						end

						-- Give the first item
						GiveItem()

						-- Handle extra items with 30% chance (plus luck)
						while (math.random(1, 100) <= extraItemChance) do
							GiveItem()
						end
					else
						ply:NotifyLocalized("ixlootNoItem")
					end

					ent.containerAlreadyUsed = CurTime() + 180
				end, SEARCH_DURATION, function()
					ply:SetNetVar("isSearchingLoot", false)
					self:StopLootSearchSound(ply)
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
