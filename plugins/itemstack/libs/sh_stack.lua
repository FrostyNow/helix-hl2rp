
local PLUGIN = PLUGIN

PLUGIN.stack = PLUGIN.stack or {}

-- Helper: Generate a key for a slot position
local function SlotKey(x, y)
	return x .. ":" .. y
end

--- Check if two items can be stacked together
function PLUGIN.stack.CanStack(item1, item2)
	if (!item1 or !item2) then return false end
	if (item1.id == item2.id) then return false end
	if (item1.uniqueID != item2.uniqueID) then return false end
	if (!item1.isStackable) then return false end
	if (!item1.gridX or !item1.gridY) then return false end

	local maxStack = item1.maxStack or 16
	local currentCount = PLUGIN.stack.GetCount(item1)

	return currentCount < maxStack
end

--- Get the number of items stacked at this item's position
function PLUGIN.stack.GetCount(item)
	if (!item or !item.invID) then return 1 end
	if (!item.gridX or !item.gridY) then return 1 end

	local inventory = ix.item.inventories[item.invID]
	if (!inventory or !inventory.stacks) then return 1 end

	local key = SlotKey(item.gridX, item.gridY)
	local stack = inventory.stacks[key]

	if (!stack) then return 1 end

	return #stack
end

--- Get all items stacked at this item's position
function PLUGIN.stack.GetStackItems(item)
	if (!item or !item.invID) then return {item} end
	if (!item.gridX or !item.gridY) then return {item} end

	local inventory = ix.item.inventories[item.invID]
	if (!inventory or !inventory.stacks) then return {item} end

	local key = SlotKey(item.gridX, item.gridY)
	local stack = inventory.stacks[key]

	if (!stack) then return {item} end

	return stack
end

--- Register an item into the stack at its position
function PLUGIN.stack.Register(inventory, item)
	if (!inventory or !item) then return end
	if (!item.isStackable) then return end

	inventory.stacks = inventory.stacks or {}

	local key = SlotKey(item.gridX, item.gridY)
	inventory.stacks[key] = inventory.stacks[key] or {}

	-- Avoid duplicates
	for _, v in ipairs(inventory.stacks[key]) do
		if (v.id == item.id) then return end
	end

	table.insert(inventory.stacks[key], item)

	-- The first item in the stack is the slot representative
	if (#inventory.stacks[key] == 1) then
		inventory.slots[item.gridX] = inventory.slots[item.gridX] or {}
		inventory.slots[item.gridX][item.gridY] = item
	end
end

--- Unregister an item from the stack at its position
function PLUGIN.stack.Unregister(inventory, item)
	if (!inventory or !item or !inventory.stacks) then return end

	local key = SlotKey(item.gridX, item.gridY)
	local stack = inventory.stacks[key]

	if (!stack) then return end

	local wasFirst = (stack[1] and stack[1].id == item.id)

	for i, v in ipairs(stack) do
		if (v.id == item.id) then
			table.remove(stack, i)
			break
		end
	end

	-- If stack is now empty, clean up
	if (#stack == 0) then
		inventory.stacks[key] = nil
		return nil
	end

	-- If the removed item was the representative, promote the next one
	if (wasFirst) then
		local newRep = stack[1]
		inventory.slots[item.gridX] = inventory.slots[item.gridX] or {}
		inventory.slots[item.gridX][item.gridY] = newRep

		return newRep
	end
end

--- Reorder items within a stack
function PLUGIN.stack.Reorder(inventory, item, newOrder)
	if (!inventory or !item or !inventory.stacks) then return end

	local key = SlotKey(item.gridX, item.gridY)
	local stack = inventory.stacks[key]

	if (!stack) then return end

	local itemLookup = {}
	for _, v in ipairs(stack) do
		itemLookup[v.id] = v
	end

	local newStack = {}
	for _, id in ipairs(newOrder) do
		if (itemLookup[id]) then
			table.insert(newStack, itemLookup[id])
			itemLookup[id] = nil
		end
	end

	for _, v in pairs(itemLookup) do
		table.insert(newStack, v)
	end

	inventory.stacks[key] = newStack

	if (newStack[1]) then
		inventory.slots[item.gridX] = inventory.slots[item.gridX] or {}
		inventory.slots[item.gridX][item.gridY] = newStack[1]
	end
end

--- Rebuild stacks for an inventory by scanning all items at same positions
function PLUGIN.stack.RebuildForInventory(inventory)
	if (!inventory) then return end

	inventory.stacks = inventory.stacks or {}

	-- Group items by position
	local positionMap = {}
	for _, v in pairs(inventory.slots) do
		for _, item in pairs(v) do
			if (istable(item) and item.isStackable and item.gridX and item.gridY) then
				local key = SlotKey(item.gridX, item.gridY)
				positionMap[key] = positionMap[key] or {}

				local found = false
				for _, existing in ipairs(positionMap[key]) do
					if (existing.id == item.id) then
						found = true
						break
					end
				end

				if (!found) then
					table.insert(positionMap[key], item)
				end
			end
		end
	end

	for key, items in pairs(positionMap) do
		if (#items > 0) then
			inventory.stacks[key] = items
		end
	end
end

--- Helper to send a stack sync net message
local function SendStackSync(invID, x, y, stack, receivers)
	stack = stack or {}

	net.Start("ixStackSync")
		net.WriteUInt(invID, 32)
		net.WriteUInt(x, 6)
		net.WriteUInt(y, 6)
		net.WriteUInt(#stack, 8)
		for _, stackItem in ipairs(stack) do
			net.WriteUInt(stackItem.id, 32)
			net.WriteString(stackItem.uniqueID)
			net.WriteTable(stackItem.data or {})
		end
	net.Send(receivers)
end

local function GetSlotSyncStack(inventory, x, y)
	if (!inventory or x == nil or y == nil) then
		return {}
	end

	local key = SlotKey(x, y)
	local stack = inventory.stacks and inventory.stacks[key]

	if (stack and #stack > 0) then
		return stack
	end

	local slotItem = inventory:GetItemAt(x, y)

	if (slotItem) then
		return {slotItem}
	end

	return {}
end

local function SyncStackSlot(inventory, x, y, receivers)
	if (!inventory or x == nil or y == nil or !istable(receivers)) then
		return
	end

	SendStackSync(inventory:GetID(), x, y, GetSlotSyncStack(inventory, x, y), receivers)
end

-- ============================================
-- Inventory Meta Overrides
-- ============================================
local META = ix.meta.inventory

META.ixcOrigGetItems = META.ixcOrigGetItems or META.GetItems
META.ixcOrigRemove = META.ixcOrigRemove or META.Remove
META.ixcOrigIter = META.ixcOrigIter or META.Iter
META.ixcOrigGetItemCount = META.ixcOrigGetItemCount or META.GetItemCount

--- Override GetItems to include ALL stacked items
function META:GetItems(onlyMain)
	local items = {}

	for _, v in pairs(self.slots) do
		for _, v2 in pairs(v) do
			if (istable(v2) and !items[v2.id]) then
				items[v2.id] = v2
				v2.data = v2.data or {}
			end
		end
	end

	-- Add all stacked items that aren't the representative
	if (self.stacks) then
		for _, stack in pairs(self.stacks) do
			for _, stackItem in ipairs(stack) do
				if (!items[stackItem.id]) then
					items[stackItem.id] = stackItem
					stackItem.data = stackItem.data or {}
				end
			end
		end
	end

	-- Include bag items
	if (onlyMain != true) then
		for id, item in pairs(items) do
			local isBag = (((item.base == "base_bags") or item.isBag) and item.data and item.data.id)

			if (isBag and isBag != self:GetID()) then
				local bagInv = ix.item.inventories[isBag]

				if (bagInv) then
					local bagItems = bagInv:GetItems()
					table.Merge(items, bagItems)
				end
			end
		end
	end

	return items
end

--- Override GetItemCount to count stacked items
function META:GetItemCount(uniqueID, onlyMain)
	local i = 0

	for _, v in pairs(self:GetItems(onlyMain)) do
		if (v.uniqueID == uniqueID) then
			i = i + 1
		end
	end

	return i
end

--- Override Remove to handle stacked items
function META:Remove(id, bNoReplication, bNoDelete, bTransferring)
	local item = ix.item.instances[id]

	-- Check if this item is part of a multi-item stack
	if (item and item.isStackable and item.gridX and item.gridY and self.stacks) then
		local key = SlotKey(item.gridX, item.gridY)
		local stack = self.stacks[key]

		if (stack and #stack > 1) then
			local x, y = item.gridX, item.gridY
			local newRep = PLUGIN.stack.Unregister(self, item)

			if (SERVER and !bNoReplication) then
				local receivers = self:GetReceivers()

				if (istable(receivers)) then
					net.Start("ixInventoryRemove")
						net.WriteUInt(id, 32)
						net.WriteUInt(self:GetID(), 32)
					net.Send(receivers)

					-- Sync the remaining slot state, including collapsed or empty stacks.
					SyncStackSlot(self, x, y, receivers)
				end

				if (!bTransferring) then
					hook.Run("InventoryItemRemoved", self, item)
				end

				if (!bNoDelete) then
					if (item and item.OnRemoved) then
						item:OnRemoved()
					end

					local query = mysql:Delete("ix_items")
						query:Where("item_id", id)
					query:Execute()

					ix.item.instances[id] = nil
				end
			end

			return x, y
		end
	end

	-- Fall back to original Remove for non-stacked items or last item in stack
	if (item and item.isStackable and item.gridX and item.gridY and self.stacks) then
		PLUGIN.stack.Unregister(self, item)
	end

	return self:ixcOrigRemove(id, bNoReplication, bNoDelete, bTransferring)
end

--- Override Iter to include stacked items
function META:Iter()
	local items = self:GetItems(true)
	local currentKey, currentItem = nil, nil

	return function()
		currentKey, currentItem = next(items, currentKey)

		if (currentItem) then
			return currentItem, currentItem.gridX, currentItem.gridY
		end
	end
end

-- ============================================
-- SERVER: Network strings, Sync overrides, Combine handler
-- ============================================
if (SERVER) then
	util.AddNetworkString("ixStackSync")
	util.AddNetworkString("ixStackPop")
	util.AddNetworkString("ixStackReorder")
	util.AddNetworkString("ixStackCombine")

	META.ixcOrigSync = META.ixcOrigSync or META.Sync
	META.ixcOrigSendSlot = META.ixcOrigSendSlot or META.SendSlot

	--- Override Sync to include stack data
	function META:Sync(receiver)
		local slots = {}

		for x, items in pairs(self.slots) do
			for y, item in pairs(items) do
				if (istable(item) and item.gridX == x and item.gridY == y) then
					slots[#slots + 1] = {x, y, item.uniqueID, item.id, item.data}
				end
			end
		end

		net.Start("ixInventorySync")
			net.WriteTable(slots)
			net.WriteUInt(self:GetID(), 32)
			net.WriteUInt(self.w, 6)
			net.WriteUInt(self.h, 6)
			net.WriteType(self.owner)
			net.WriteTable(self.vars or {})
		net.Send(receiver)

		for k, _ in self:Iter() do
			k:Call("OnSendData", receiver)
		end

		-- Send stack data
		if (self.stacks) then
			for key, stack in pairs(self.stacks) do
				if (#stack > 1) then
					local parts = string.Explode(":", key)
					local x, y = tonumber(parts[1]), tonumber(parts[2])

					SendStackSync(self:GetID(), x, y, stack, receiver)
				end
			end
		end
	end

	--- Override SendSlot to include stack info
	function META:SendSlot(x, y, item)
		self:ixcOrigSendSlot(x, y, item)
		SyncStackSlot(self, x, y, self:GetReceivers())
	end

	--- Perform the actual stacking of sourceItem onto targetItem
	function PLUGIN.stack.DoStack(inventory, targetItem, sourceItem)
		if (!PLUGIN.stack.CanStack(targetItem, sourceItem)) then
			return false
		end

		local sourceInv = ix.item.inventories[sourceItem.invID]
		local sourceX, sourceY = sourceItem.gridX, sourceItem.gridY

		-- Remove source item from its old slot (without deleting from DB)
		if (sourceInv) then
			-- Clear old slot references
			for x2 = 0, sourceItem.width - 1 do
				for y2 = 0, sourceItem.height - 1 do
					local sx = sourceItem.gridX + x2
					local sy = sourceItem.gridY + y2

					if (sourceInv.slots[sx]) then
						if (sourceInv.slots[sx][sy] and sourceInv.slots[sx][sy].id == sourceItem.id) then
							sourceInv.slots[sx][sy] = nil
						end
					end
				end
			end

			-- If source was in a stack, unregister it
			if (sourceInv.stacks) then
				PLUGIN.stack.Unregister(sourceInv, sourceItem)
			end

			-- Notify clients about source removal from old position
			local receivers = sourceInv:GetReceivers()
			if (istable(receivers)) then
				net.Start("ixInventoryRemove")
					net.WriteUInt(sourceItem.id, 32)
					net.WriteUInt(sourceInv:GetID(), 32)
				net.Send(receivers)

				SyncStackSlot(sourceInv, sourceX, sourceY, receivers)
			end
		end

		-- Move source to target's position
		sourceItem.gridX = targetItem.gridX
		sourceItem.gridY = targetItem.gridY
		sourceItem.invID = inventory:GetID()

		-- Register both in the stack
		inventory.stacks = inventory.stacks or {}
		PLUGIN.stack.Register(inventory, targetItem)
		PLUGIN.stack.Register(inventory, sourceItem)

		-- Update DB position for source item
		if (!inventory.noSave) then
			local query = mysql:Update("ix_items")
				query:Update("inventory_id", inventory:GetID())
				query:Update("x", targetItem.gridX)
				query:Update("y", targetItem.gridY)
				query:Where("item_id", sourceItem.id)
			query:Execute()
		end

		-- Sync the slot state to clients.
		local receivers = inventory:GetReceivers()

		if (istable(receivers)) then
			SyncStackSlot(inventory, targetItem.gridX, targetItem.gridY, receivers)
		end

		return true
	end

	--- Handle stack combine requests from clients (drag & drop stacking)
	net.Receive("ixStackCombine", function(length, client)
		local targetID = net.ReadUInt(32)
		local sourceID = net.ReadUInt(32)
		local invID = net.ReadUInt(32)

		local character = client:GetCharacter()
		if (!character) then return end

		local inventory = ix.item.inventories[invID]
		if (!inventory) then return end

		if (!inventory:OnCheckAccess(client)) then return end

		local targetItem = ix.item.instances[targetID]
		local sourceItem = ix.item.instances[sourceID]

		if (!targetItem or !sourceItem) then return end

		local success = PLUGIN.stack.DoStack(inventory, targetItem, sourceItem)

		if (!success) then
			client:NotifyLocalized("stackFull")
		end
	end)

	--- Handle stack pop requests from clients
	net.Receive("ixStackPop", function(length, client)
		local invID = net.ReadUInt(32)
		local itemID = net.ReadUInt(32)

		local character = client:GetCharacter()
		if (!character) then return end

		local inventory = ix.item.inventories[invID]
		if (!inventory) then return end

		if (!inventory:OnCheckAccess(client)) then return end

		local item = ix.item.instances[itemID]
		if (!item or !item.isStackable) then return end

		local key = SlotKey(item.gridX, item.gridY)
		local stack = inventory.stacks and inventory.stacks[key]
		if (!stack or #stack <= 1) then return end

		-- Find an empty slot for the popped item
		local newX, newY = inventory:FindEmptySlot(item.width, item.height, true)
		if (!newX or !newY) then
			client:NotifyLocalized("noFit")
			return
		end

		local oldKey = key

		-- Unregister from stack
		PLUGIN.stack.Unregister(inventory, item)

		-- Place in new slot
		item.gridX = newX
		item.gridY = newY

		for x2 = 0, item.width - 1 do
			for y2 = 0, item.height - 1 do
				inventory.slots[newX + x2] = inventory.slots[newX + x2] or {}
				inventory.slots[newX + x2][newY + y2] = item
			end
		end

		PLUGIN.stack.Register(inventory, item)

		-- Update DB
		local query = mysql:Update("ix_items")
			query:Update("x", newX)
			query:Update("y", newY)
			query:Where("item_id", itemID)
		query:Execute()

		-- Network the changes
		local receivers = inventory:GetReceivers()
		if (istable(receivers)) then
			-- Sync old slot state, including collapsed stacks.
			local parts = string.Explode(":", oldKey)
			local oldX, oldY = tonumber(parts[1]), tonumber(parts[2])
			SyncStackSlot(inventory, oldX, oldY, receivers)

			-- Send new slot
			inventory:SendSlot(newX, newY, item)
		end
	end)

	--- Handle stack reorder requests from clients
	net.Receive("ixStackReorder", function(length, client)
		local invID = net.ReadUInt(32)
		local x = net.ReadUInt(6)
		local y = net.ReadUInt(6)
		local count = net.ReadUInt(8)
		local newOrder = {}

		for i = 1, count do
			newOrder[i] = net.ReadUInt(32)
		end

		local character = client:GetCharacter()
		if (!character) then return end

		local inventory = ix.item.inventories[invID]
		if (!inventory) then return end

		if (!inventory:OnCheckAccess(client)) then return end

		local slotItem = inventory:GetItemAt(x, y)
		if (!slotItem) then return end

		PLUGIN.stack.Reorder(inventory, slotItem, newOrder)

		local receivers = inventory:GetReceivers()
		local key = SlotKey(x, y)
		local stack = inventory.stacks[key]

		if (stack and istable(receivers)) then
			SendStackSync(invID, x, y, stack, receivers)
		end
	end)
end

-- ============================================
-- CLIENT: Network receivers
-- ============================================
if (CLIENT) then
	net.Receive("ixStackSync", function()
		local invID = net.ReadUInt(32)
		local x = net.ReadUInt(6)
		local y = net.ReadUInt(6)
		local count = net.ReadUInt(8)

		local inventory = ix.item.inventories[invID]
		if (!inventory) then return end

		local key = SlotKey(x, y)
		local syncedItems = {}

		for i = 1, count do
			local itemID = net.ReadUInt(32)
			local uniqueID = net.ReadString()
			local data = net.ReadTable()

			local item = ix.item.instances[itemID] or ix.item.New(uniqueID, itemID)
			if (item) then
				item.data = data or {}
				item.invID = invID
				item.gridX = x
				item.gridY = y

				syncedItems[i] = item
			end
		end

		inventory.stacks = inventory.stacks or {}

		if (#syncedItems > 1) then
			inventory.stacks[key] = syncedItems
		else
			inventory.stacks[key] = nil
		end

		-- Update slot representative when the server includes one.
		if (#syncedItems > 0) then
			local rep = syncedItems[1]
			inventory.slots[x] = inventory.slots[x] or {}
			inventory.slots[x][y] = rep
		elseif (inventory.slots[x]) then
			inventory.slots[x][y] = nil
		end
	end)

	--- Set gridX/gridY on all inventory item instances from slot data
	-- Called when opening the menu to ensure client items have coordinates
	hook.Add("CreateMenuButtons", "ixItemStackFixGrid", function(tabs)
		local character = LocalPlayer():GetCharacter()
		if (!character) then return end

		local invList = character:GetInventory(true)
		local inventories = {}

		if (istable(invList)) then
			for _, inv in ipairs(invList) do
				table.insert(inventories, inv)
			end
		elseif (invList) then
			table.insert(inventories, invList)
		end

		for _, inventory in ipairs(inventories) do
			if (!inventory or !inventory.slots) then continue end

			-- Set gridX/gridY on all instances from slot positions
			for slotX, column in pairs(inventory.slots) do
				for slotY, data in pairs(column) do
					if (istable(data) and data.id) then
						local instance = ix.item.instances[data.id]
						if (instance) then
							instance.gridX = slotX
							instance.gridY = slotY
						end
					end
				end
			end

			-- Also set on stacked items
			if (inventory.stacks) then
				for stackKey, stack in pairs(inventory.stacks) do
					local parts = string.Explode(":", stackKey)
					local sx, sy = tonumber(parts[1]), tonumber(parts[2])

					for _, item in ipairs(stack) do
						if (item) then
							item.gridX = sx
							item.gridY = sy
						end
					end
				end
			end
		end
	end)
end

-- ============================================
-- Add combine function to stackable items for drag & drop
-- ============================================
local stackCanStack = PLUGIN.stack.CanStack
local stackDoStack = SERVER and PLUGIN.stack.DoStack or nil

local COMBINE_FUNC = {
	OnCanRun = function(item, data)
		-- Only check basic compatibility here - server validates fully in OnRun
		if (!data or !data[1]) then return false end

		local sourceItem = ix.item.instances[data[1]]
		if (!sourceItem) then return false end
		if (!sourceItem.isStackable) then return false end
		if (sourceItem.uniqueID != item.uniqueID) then return false end
		if (sourceItem.id == item.id) then return false end

		return true
	end,
	OnRun = function(item, data)
		if (SERVER and stackDoStack) then
			local sourceItem = ix.item.instances[data[1]]

			if (sourceItem) then
				local inventory = ix.item.inventories[item.invID]

				if (inventory) then
					stackDoStack(inventory, item, sourceItem)
				end
			end
		end

		return false -- Don't remove the target item
	end
}

hook.Add("InitializedPlugins", "ixItemStack", function()
	local count = 0

	for uniqueID, itemTable in pairs(ix.item.list) do
		if (itemTable.isStackable) then
			itemTable.functions.combine = COMBINE_FUNC
			count = count + 1

			print("[ItemStack] Added combine to: " .. uniqueID
				.. " | functions table: " .. tostring(itemTable.functions)
				.. " | combine: " .. tostring(itemTable.functions.combine))
		end
	end

	print("[ItemStack] Total: " .. count .. " stackable items")

	-- Verify instances can see it
	timer.Simple(5, function()
		for id, instance in pairs(ix.item.instances) do
			if (instance.isStackable) then
				print("[ItemStack] Instance " .. id .. " (" .. instance.uniqueID .. ")"
					.. " | functions: " .. tostring(instance.functions)
					.. " | combine: " .. tostring(instance.functions and instance.functions.combine))
				break -- only print first one
			end
		end
	end)
end)

-- Rebuild stacks when a character's inventory is loaded
hook.Add("CharacterLoaded", "ixItemStack", function(character)
	timer.Simple(0, function()
		if (!character) then return end

		local invList = character:GetInventory(true)

		if (istable(invList)) then
			for _, inv in ipairs(invList) do
				if (inv and inv.slots) then
					PLUGIN.stack.RebuildForInventory(inv)
				end
			end
		elseif (invList and invList.slots) then
			PLUGIN.stack.RebuildForInventory(invList)
		end
	end)
end)

-- Register new items into stacks at runtime
hook.Add("InventoryItemAdded", "ixItemStack", function(oldInv, newInv, item)
	if (item and item.isStackable and newInv) then
		newInv.stacks = newInv.stacks or {}
		PLUGIN.stack.Register(newInv, item)
	end
end)
