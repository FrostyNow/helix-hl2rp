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
				ply:SetAction("@storageSearching", SEARCH_DURATION)
				self:StartLootSearchSound(ent, ply)
				ply:DoStaredAction(ent, function()
					self:StopLootSearchSound(ply)
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
				end, SEARCH_DURATION, function()
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
