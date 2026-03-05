local PLUGIN = PLUGIN
PLUGIN.name = "Equipped Items Tooltip"
PLUGIN.author = "Frosty with Antigravity"
PLUGIN.description = "Displays equipped items in the player info tooltip."

-- Register character variable to sync equipped items to clients
ix.char.RegisterVar("equippedItems", {
	field = "equipped_items",
	default = {},
	index = 10,
	isLocal = false, -- Sync to all clients so they can see tooltips
	bNoNetworking = false
})

if (SERVER) then
	-- Function to update the character's equipped items list
	local function RefreshEquippedItems(character)
		if (!character) then return end

		local inventory = character:GetInventory()
		local equipped = {}

		if (inventory) then
			for _, item in pairs(inventory:GetItems()) do
				if (item:GetData("equip") == true) then
					table.insert(equipped, item.uniqueID)
				end
			end
		end

		character:SetEquippedItems(equipped)
	end

	-- Update when items are equipped/unequipped
	function PLUGIN:OnItemEquipped(item, client)
		RefreshEquippedItems(client:GetCharacter())
	end

	function PLUGIN:OnItemUnequipped(item, client)
		RefreshEquippedItems(client:GetCharacter())
	end

	-- Update when items are removed/dropped from inventory
	function PLUGIN:InventoryItemRemoved(inventory, item)
		local character = ix.char.loaded[inventory.owner]
		if (character) then
			-- Item might still be in the 'equipped' state until this tick finishes
			timer.Simple(0, function()
				if (character) then RefreshEquippedItems(character) end
			end)
		end
	end

	-- Update when items are transferred between inventories
	function PLUGIN:OnItemTransferred(item, curInv, inventory)
		local char1 = ix.char.loaded[curInv.owner]
		local char2 = ix.char.loaded[inventory.owner]

		timer.Simple(0, function()
			if (char1) then RefreshEquippedItems(char1) end
			if (char2) then RefreshEquippedItems(char2) end
		end)
	end

	-- Initial sync when character loads
	function PLUGIN:PlayerLoadedCharacter(client, character)
		timer.Simple(0.2, function()
			if (character) then RefreshEquippedItems(character) end
		end)
	end
end

if (CLIENT) then
	-- Standard Helix hook for adding info to player tooltips
	function PLUGIN:PopulateCharacterInfo(player, character, tooltip)
		local equipped = character:GetEquippedItems()

		if (equipped and #equipped > 0) then
			local names = {}
			for _, v in ipairs(equipped) do
				local itemTable = ix.item.list[v]
				if (itemTable) then
					table.insert(names, L(itemTable.name))
				end
			end

			if (#names > 0) then
				local row = tooltip:AddRow("equipped_items")
				row:SetText(table.concat(names, ", ") .. L("equippedGarmentsSuffix"))
				row:SetBackgroundColor(ix.config.Get("color"))
				row:SetTextColor(color_white)
				row:SizeToContents()
			end
		end
	end
end

ix.lang.AddTable("english", {
	equippedGarmentsSuffix = " equipped."
})

ix.lang.AddTable("korean", {
	equippedGarmentsSuffix = " 착용."
})
