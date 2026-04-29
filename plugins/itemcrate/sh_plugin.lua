local PLUGIN = PLUGIN

PLUGIN.name = "Item Crate Spawner"
PLUGIN.author = "Frosty"
PLUGIN.description = "Provides a command to spawn prepopulated item crates."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.lang.AddTable("english", {
	cmdItemCrateDesc = "Spawns an item crate containing the specified item or preset.",
	invalidItemOrPreset = "Invalid item or preset.",
	crateSpaceInsufficient = "Some items could not be added due to insufficient crate space.",
	itemCrateSpawned = "Item crate spawned successfully.",
	itemCratePresets = "Available presets: %s"
})

ix.lang.AddTable("korean", {
	cmdItemCrateDesc = "설정한 아이템이나 프리셋이 들어있는 물품 상자를 생성합니다.",
	invalidItemOrPreset = "유효하지 않은 아이템이거나 프리셋입니다.",
	crateSpaceInsufficient = "상자 공간이 부족하여 일부 아이템이 추가되지 못했습니다.",
	itemCrateSpawned = "물품 상자를 성공적으로 생성했습니다.",
	itemCratePresets = "사용 가능한 프리셋: %s",
})

-- Preset configurations
PLUGIN.presets = {
	["preset_ar2"] = {
		["ar2"] = 1,
		["ar2ammo"] = 3
	},
	["preset_smg1"] = {
		["smg1"] = 1,
		["smg1ammo"] = 2
	},
	["preset_pistol"] = {
		["pistol"] = 1,
		["pistolammo"] = 2
	},
	["preset_grenade"] = {
		["grenade"] = 3
	},
	["preset_vial"] = {
		["health_vial"] = 5
	},
	["preset_medkit"] = {
		["bandage"] = 5,
		["medkit"] = 3
	},
}

ix.command.Add("ItemCrate", {
	description = "@cmdItemCrateDesc",
	adminOnly = true,
	arguments = {
		ix.type.string,
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, itemOrPreset, amount)
		amount = amount or 1
		local itemsToSpawn = {}

		-- Check if the input is a preset or a single item
		if (PLUGIN.presets[itemOrPreset]) then
			itemsToSpawn = PLUGIN.presets[itemOrPreset]
		else
			local itemTable = ix.item.list[itemOrPreset]
			if (!itemTable) then
				local presetList = {}
				for k in pairs(PLUGIN.presets) do
					presetList[#presetList + 1] = k
				end
				client:NotifyLocalized("itemCratePresets", table.concat(presetList, ", "))
				return "@invalidItemOrPreset"
			end
			itemsToSpawn[itemOrPreset] = amount
		end

		-- Create the crate at the administrator's eye trace position
		local tr = client:GetEyeTraceNoCursor()
		local pos = tr.HitPos + Vector(0, 0, 15)
		local model = "models/items/item_item_crate.mdl"

		local container = ents.Create("ix_container")
		container:SetPos(pos)
		container:SetAngles(Angle(0, client:EyeAngles().y - 180, 0))
		container:SetModel(model)
		container:Spawn()

		-- Create a unique inventory and add items
		ix.inventory.New(0, "container:" .. model:lower(), function(inventory)
			inventory.vars.isBag = true
			inventory.vars.isContainer = true

			if (IsValid(container)) then
				container:SetInventory(inventory)

				local itemList = {}
				for uniqueID, amt in pairs(itemsToSpawn) do
					for i = 1, amt do
						itemList[#itemList + 1] = uniqueID
					end
				end

				local index = 1
				local function addNext()
					if (index > #itemList) then
						if (ix.plugin.list["containers"]) then
							ix.plugin.list["containers"]:SaveContainer()
						end
						return
					end

					local bSuccess = inventory:Add(itemList[index])
					if (!bSuccess) then
						client:NotifyLocalized("crateSpaceInsufficient")
						return
					end

					index = index + 1
					addNext()
				end

				addNext()
			end
		end)

		return "@itemCrateSpawned"
	end
})
