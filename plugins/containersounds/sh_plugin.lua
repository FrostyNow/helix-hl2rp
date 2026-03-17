PLUGIN.name = "Container Sounds"
PLUGIN.author = "Frosty"
PLUGIN.description = "Adds open and close sounds to storage containers."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

local metalOpenSounds = {
	"items/ammocrate_open.wav",
	"doors/door_metal_medium_open1.wav"
}

local metalCloseSounds = {
	"items/ammocrate_close.wav",
	"doors/door_metal_medium_close1.wav"
}

local woodOpenSounds = {
	"physics/wood/wood_crate_impact_soft2.wav",
	"physics/wood/wood_crate_impact_soft3.wav"
}

local woodCloseSounds = {
	"physics/wood/wood_crate_impact_hard2.wav",
	"physics/wood/wood_crate_impact_hard3.wav"
}

local cardboardOpenSounds = {
	"physics/cardboard/cardboard_box_impact_soft1.wav",
	"physics/cardboard/cardboard_box_impact_soft2.wav"
}

local cardboardCloseSounds = {
	"physics/cardboard/cardboard_box_impact_soft4.wav",
	"physics/cardboard/cardboard_box_impact_soft6.wav"
}

local metalSearchStartSounds = {
	"doors/door_latch3.wav"
}

local woodSearchStartSounds = {
	"physics/wood/wood_crate_impact_soft1.wav"
}

local cardboardSearchStartSounds = {
	"physics/cardboard/cardboard_box_impact_soft1.wav"
}

local function GetContainerEntityTable()
	local stored = scripted_ents.GetStored("ix_container")

	if (stored and stored.t) then
		return stored.t
	end

	return scripted_ents.Get("ix_container")
end

local function GetSoundValue(spec)
	if (isstring(spec)) then
		return spec, 70, 100, 1
	end

	if (!istable(spec)) then
		return
	end

	if (isstring(spec.sound)) then
		return spec.sound, spec.level or 70, spec.pitch or 100, spec.volume or 1
	end

	if (isstring(spec[1])) then
		return spec[math.random(1, #spec)], 70, 100, 1
	end
end

local function GetContainerMaterial(entity)
	local model = string.lower(tostring(entity:GetModel() or ""))

	if (
		model:find("cardboard", 1, true) or
		model:find("cashregister", 1, true)
	) then
		return "cardboard"
	end

	if (
		model:find("wood_crate", 1, true) or
		model:find("footlocker", 1, true) or
		model:find("item_crate", 1, true) or
		model:find("drawer", 1, true) or
		model:find("dresser", 1, true) or
		model:find("desk01a", 1, true)
	) then
		return "wood"
	end

	return "metal"
end

local function GetFallbackSoundSpec(entity, phase)
	local material = GetContainerMaterial(entity)
	local sounds

	if (phase == "search") then
		if (material == "cardboard") then
			sounds = cardboardSearchStartSounds
		elseif (material == "wood") then
			sounds = woodSearchStartSounds
		else
			sounds = metalSearchStartSounds
		end
	elseif (phase == "close") then
		if (material == "cardboard") then
			sounds = cardboardCloseSounds
		elseif (material == "wood") then
			sounds = woodCloseSounds
		else
			sounds = metalCloseSounds
		end
	else
		if (material == "cardboard") then
			sounds = cardboardOpenSounds
		elseif (material == "wood") then
			sounds = woodOpenSounds
		else
			sounds = metalOpenSounds
		end
	end

	return sounds[math.random(1, #sounds)]
end

function PLUGIN:EmitContainerSound(entity, definition, phase)
	if (!IsValid(entity)) then
		return
	end

	local key = phase == "close" and "closesound" or phase == "search" and "searchsound" or "opensound"
	local soundPath, level, pitch, volume

	if (istable(definition) and definition[key] != nil) then
		if (definition[key] == false) then
			return
		end

		soundPath, level, pitch, volume = GetSoundValue(definition[key])
	else
		soundPath = GetFallbackSoundSpec(entity, phase)
	end

	if (!isstring(soundPath) or soundPath == "") then
		return
	end

	entity:EmitSound(soundPath, level or 70, pitch or 100, volume or 1)
end

function PLUGIN:PatchContainerEntity()
	local entityTable = GetContainerEntityTable()

	if (!entityTable or entityTable.ixContainerSoundPatched) then
		return
	end

	entityTable.ixContainerSoundPatched = true

	function entityTable:OpenInventory(activator)
		local inventory = self:GetInventory()

		if (inventory) then
			local name = self:GetDisplayName()
			local definition = ix.container.stored[self:GetModel():lower()]
			local soundPlugin = ix.plugin.list["containersounds"]

			ix.storage.Open(activator, inventory, {
				name = name,
				entity = self,
				searchTime = ix.config.Get("containerOpenTime", 0.7),
				data = {money = self:GetMoney()},
				OnPlayerOpenStart = function(client)
					if (soundPlugin) then
						soundPlugin:EmitContainerSound(self, definition, "search")
					end
				end,
				OnPlayerOpenComplete = function(client)
					if (definition and definition.OnOpen) then
						definition.OnOpen(self, client)
					end

					if (soundPlugin) then
						soundPlugin:EmitContainerSound(self, definition, "open")
					end
				end,
				OnPlayerClose = function(client)
					if (definition and definition.OnClose) then
						definition.OnClose(self, client)
					end

					if (soundPlugin) then
						soundPlugin:EmitContainerSound(self, definition, "close")
					end

					ix.log.Add(client, "closeContainer", name, inventory:GetID())
				end
			})

			if (self:GetLocked()) then
				self.Sessions[activator:GetCharacter():GetID()] = true
			end

			ix.log.Add(activator, "openContainer", name, inventory:GetID())
		end
	end
end

function PLUGIN:PatchStorageLibrary()
	if (ix.storage.ixContainerSoundPatched) then
		return
	end

	ix.storage.ixContainerSoundPatched = true

	function ix.storage.Open(client, inventory, info)
		assert(IsValid(client) and client:IsPlayer(), "expected valid player")
		assert(type(inventory) == "table" and inventory:IsInstanceOf(ix.meta.inventory), "expected valid inventory")

		if (!inventory.storageInfo) then
			info = info or {}
			ix.storage.CreateContext(inventory, info)
		end

		local storageInfo = inventory.storageInfo

		if (storageInfo.bMultipleUsers or !ix.storage.InUse(inventory)) then
			ix.storage.AddReceiver(client, inventory, true)
		else
			client:NotifyLocalized("storageInUse")
			return
		end

		if (storageInfo.searchTime > 0) then
			client:SetAction(storageInfo.searchText, storageInfo.searchTime)

			if (isfunction(storageInfo.OnPlayerOpenStart)) then
				storageInfo.OnPlayerOpenStart(client)
			end

			client:DoStaredAction(storageInfo.entity, function()
				if (IsValid(client) and IsValid(storageInfo.entity) and inventory.storageInfo) then
					ix.storage.Sync(client, inventory)

					if (isfunction(storageInfo.OnPlayerOpenComplete)) then
						storageInfo.OnPlayerOpenComplete(client)
					end
				end
			end, storageInfo.searchTime, function()
				if (IsValid(client)) then
					ix.storage.RemoveReceiver(client, inventory)
					client:SetAction()
				end
			end)
		else
			ix.storage.Sync(client, inventory)

			if (isfunction(storageInfo.OnPlayerOpenComplete)) then
				storageInfo.OnPlayerOpenComplete(client)
			end
		end
	end
end

function PLUGIN:InitializedPlugins()
	self:PatchStorageLibrary()
	self:PatchContainerEntity()
end
