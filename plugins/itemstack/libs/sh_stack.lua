
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

function PLUGIN.stack.FindAutoStackTarget(inventory, item)
	if (!inventory or !item or !item.isStackable) then
		return nil
	end

	local seen = {}

	for x, column in pairs(inventory.slots or {}) do
		for y, candidate in pairs(column) do
			if (istable(candidate) and candidate.id and !seen[candidate.id] and candidate.id != item.id) then
				seen[candidate.id] = true

				if (candidate.gridX == x and candidate.gridY == y and PLUGIN.stack.CanStack(candidate, item)) then
					return candidate
				end
			end
		end
	end

	return nil
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

	inventory.stacks = {}

	for x, column in pairs(inventory.slots or {}) do
		for y, slotItem in pairs(column) do
			if (istable(slotItem) and slotItem.isStackable) then
				column[y] = nil
			end
		end
	end

	local positionMap = {}

	for _, item in pairs(ix.item.instances) do
		if (item and item.invID == inventory:GetID() and item.isStackable and item.gridX and item.gridY) then
			local key = SlotKey(item.gridX, item.gridY)
			positionMap[key] = positionMap[key] or {}
			positionMap[key][#positionMap[key] + 1] = item
		end
	end

	for key, items in pairs(positionMap) do
		local parts = string.Explode(":", key)
		local x, y = tonumber(parts[1]), tonumber(parts[2])

		table.sort(items, function(a, b)
			return a.id < b.id
		end)

		if (x and y and items[1]) then
			for x2 = 0, items[1].width - 1 do
				local slotX = x + x2
				inventory.slots[slotX] = inventory.slots[slotX] or {}

				for y2 = 0, items[1].height - 1 do
					inventory.slots[slotX][y + y2] = items[1]
				end
			end
		end

		if (#items > 1) then
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

local function ReplicateSlotState(inventory, x, y, receivers, representative, previousRepresentative)
	if (!inventory or x == nil or y == nil or !istable(receivers)) then
		return
	end

	if (previousRepresentative and (!representative or previousRepresentative.id != representative.id)) then
		net.Start("ixInventoryRemove")
			net.WriteUInt(previousRepresentative.id, 32)
			net.WriteUInt(inventory:GetID(), 32)
		net.Send(receivers)
	end

	if (representative) then
		inventory:SendSlot(x, y, representative)
	else
		SyncStackSlot(inventory, x, y, receivers)
	end
end

local function NetworkInventoryMove(receiver, invID, itemID, oldX, oldY, x, y)
	net.Start("ixInventoryMove")
		net.WriteUInt(invID, 32)
		net.WriteUInt(itemID, 32)
		net.WriteUInt(oldX, 6)
		net.WriteUInt(oldY, 6)
		net.WriteUInt(x, 6)
		net.WriteUInt(y, 6)
	net.Send(receiver)
end

local function ClearSlotArea(inventory, x, y, width, height)
	for x2 = 0, width - 1 do
		local column = inventory.slots[x + x2]

		if (column) then
			for y2 = 0, height - 1 do
				column[y + y2] = nil
			end
		end
	end
end
local function ClearItemSlots(inventory, item, x, y)
	for x2 = 0, item.width - 1 do
		local column = inventory.slots[x + x2]

		if (column) then
			for y2 = 0, item.height - 1 do
				if (column[y + y2] == item) then
					column[y + y2] = nil
				end
			end
		end
	end
end

local function FillItemSlots(inventory, item, x, y)
	for x2 = 0, item.width - 1 do
		local slotX = x + x2
		inventory.slots[slotX] = inventory.slots[slotX] or {}

		for y2 = 0, item.height - 1 do
			inventory.slots[slotX][y + y2] = item
		end
	end
end

local function FilterReceivers(receivers, excluded)
	if (!istable(receivers)) then
		return nil
	end

	local filtered = {}

	for _, receiver in ipairs(receivers) do
		if (receiver != excluded) then
			filtered[#filtered + 1] = receiver
		end
	end

	return filtered
end

local function SaveStackPosition(stack, invID, x, y, noSave)
	if (noSave) then
		return
	end

	for _, stackItem in ipairs(stack) do
		local query = mysql:Update("ix_items")
			query:Update("inventory_id", invID)
			query:Update("x", x)
			query:Update("y", y)
			query:Where("item_id", stackItem.id)
		query:Execute()
	end
end

local function RebuildInventories(...)
	local seen = {}

	for index = 1, select("#", ...) do
		local inventory = select(index, ...)

		if (inventory and !seen[inventory]) then
			PLUGIN.stack.RebuildForInventory(inventory)
			seen[inventory] = true
		end
	end
end

local function GetRepresentativeAt(inventory, x, y)
	if (!inventory or !x or !y) then
		return nil
	end

	return inventory:GetItemAt(x, y)
end

local function RunInventoryItemAdded(oldInv, newInv, item)
	if (!item) then
		return
	end

	item.ixSkipAutoStack = true
	hook.Run("InventoryItemAdded", oldInv, newInv, item)
	item.ixSkipAutoStack = nil
end

function PLUGIN.stack.MoveStack(inventory, item, newX, newY, client)
	if (!inventory or !item or !inventory.stacks) then
		return false, "invalidInventory"
	end

	RebuildInventories(inventory)
	local oldX, oldY = item.gridX, item.gridY
	local oldKey = SlotKey(oldX, oldY)
	local stack = inventory.stacks[oldKey]

	if (!stack or #stack <= 1) then
		return false, "invalidStack"
	end

	if (!inventory:CanItemFit(newX, newY, item.width, item.height, item)) then
		return false, "noFit"
	end

	ClearSlotArea(inventory, oldX, oldY, item.width, item.height)

	for _, stackItem in ipairs(stack) do
		stackItem.gridX = newX
		stackItem.gridY = newY
	end

	FillItemSlots(inventory, stack[1], newX, newY)
	SaveStackPosition(stack, inventory:GetID(), newX, newY, inventory.noSave)
	RebuildInventories(inventory)

	local receivers = inventory:GetReceivers()
	local filtered = FilterReceivers(receivers, client)

	if (istable(filtered) and #filtered > 0) then
		NetworkInventoryMove(filtered, inventory:GetID(), stack[1].id, oldX, oldY, newX, newY)
	end

	if (istable(receivers)) then
		SyncStackSlot(inventory, oldX, oldY, receivers)
		SyncStackSlot(inventory, newX, newY, receivers)
	end

	return true
end

function PLUGIN.stack.TransferStack(item, targetInv, x, y, client, noReplication)
	local sourceInv = ix.item.inventories[item.invID or 0]

	if (!sourceInv or !targetInv or !sourceInv.stacks) then
		return false, "invalidInventory"
	end

	RebuildInventories(sourceInv, targetInv)
	local oldX, oldY = item.gridX, item.gridY
	local oldKey = SlotKey(oldX, oldY)
	local stack = sourceInv.stacks[oldKey]
	local previousRepresentative = stack and stack[1] or nil

	if (!stack or #stack <= 1) then
		return false, "invalidStack"
	end

	if (!x and !y) then
		x, y = targetInv:FindEmptySlot(item.width, item.height)
	end

	if (!x or !y) then
		return false, "noFit"
	end

	if (!targetInv:CanItemFit(x, y, item.width, item.height, item)) then
		return false, "noFit"
	end

	ClearSlotArea(sourceInv, oldX, oldY, item.width, item.height)

	for _, stackItem in ipairs(stack) do
		stackItem.invID = targetInv:GetID()
		stackItem.gridX = x
		stackItem.gridY = y

		if (stackItem.OnTransferred) then
			stackItem:OnTransferred(sourceInv, targetInv)
		end

		hook.Run("OnItemTransferred", stackItem, sourceInv, targetInv)
		RunInventoryItemAdded(sourceInv, targetInv, stackItem)
	end

	FillItemSlots(targetInv, stack[1], x, y)
	SaveStackPosition(stack, targetInv:GetID(), x, y, targetInv.noSave)
	RebuildInventories(sourceInv, targetInv)

	if (!noReplication) then
		local sourceReceivers = sourceInv:GetReceivers()
		local targetReceivers = targetInv:GetReceivers()
		local sourceRepresentative = GetRepresentativeAt(sourceInv, oldX, oldY)
		local targetRepresentative = GetRepresentativeAt(targetInv, x, y)

		if (istable(sourceReceivers)) then
			ReplicateSlotState(sourceInv, oldX, oldY, sourceReceivers, sourceRepresentative, previousRepresentative)
		end

		if (istable(targetReceivers) and targetRepresentative) then
			targetInv:SendSlot(x, y, targetRepresentative)
			SyncStackSlot(targetInv, x, y, targetReceivers)
		end
	end

	return true
end

function PLUGIN.stack.TransferSingle(sourceInv, item, targetInv, newX, newY)
	if (!sourceInv or !targetInv or !item or !sourceInv.stacks) then
		return false, "invalidInventory"
	end

	RebuildInventories(sourceInv, targetInv)
	local oldX, oldY = item.gridX, item.gridY
	local oldKey = SlotKey(oldX, oldY)
	local sourceStack = sourceInv.stacks[oldKey]
	local previousSourceRepresentative = sourceStack and sourceStack[1] or nil

	if (sourceInv == targetInv and oldX == newX and oldY == newY) then
		return false, "sameSlot"
	end

	if (!sourceStack or #sourceStack <= 1 or sourceStack[1].id != item.id) then
		return false, "invalidStack"
	end

	local targetItem = targetInv:GetItemAt(newX, newY)
	local previousTargetRepresentative = targetItem

	if (targetItem) then
		if (!PLUGIN.stack.CanStack(targetItem, item)) then
			return false, "noFit"
		end
	elseif (!targetInv:CanItemFit(newX, newY, item.width, item.height, item)) then
		return false, "noFit"
	end

	if (#sourceStack <= 2) then
		ClearSlotArea(sourceInv, oldX, oldY, item.width, item.height)
		if (#sourceStack == 2) then
			local remainingItem = sourceStack[2]
			if (remainingItem and remainingItem.id == item.id) then
				remainingItem = sourceStack[1]
			end
			if (remainingItem) then
				FillItemSlots(sourceInv, remainingItem, oldX, oldY)
			end
		end
	end

	item.gridX = newX
	item.gridY = newY
	item.invID = targetInv:GetID()

	if (!targetItem) then
		FillItemSlots(targetInv, item, newX, newY)
	end

	if (sourceInv != targetInv) then
		if (item.OnTransferred) then
			item:OnTransferred(sourceInv, targetInv)
		end

		hook.Run("OnItemTransferred", item, sourceInv, targetInv)
		RunInventoryItemAdded(sourceInv, targetInv, item)
	end

	if (!targetInv.noSave) then
		local query = mysql:Update("ix_items")
			query:Update("inventory_id", targetInv:GetID())
			query:Update("x", newX)
			query:Update("y", newY)
			query:Where("item_id", item.id)
		query:Execute()
	end

	RebuildInventories(sourceInv, targetInv)

	local sourceReceivers = sourceInv:GetReceivers()
	if (istable(sourceReceivers)) then
		ReplicateSlotState(sourceInv, oldX, oldY, sourceReceivers, GetRepresentativeAt(sourceInv, oldX, oldY), previousSourceRepresentative)
	end

	local targetReceivers = targetInv:GetReceivers()
	if (istable(targetReceivers)) then
		local targetRepresentative = GetRepresentativeAt(targetInv, newX, newY)

		if (targetItem) then
			SyncStackSlot(targetInv, newX, newY, targetReceivers)
		elseif (targetRepresentative) then
			ReplicateSlotState(targetInv, newX, newY, targetReceivers, targetRepresentative, previousTargetRepresentative)
		end
	end

	return true
end

function PLUGIN.stack.MoveSingle(inventory, item, newX, newY)
	return PLUGIN.stack.TransferSingle(inventory, item, inventory, newX, newY)
end

function PLUGIN.stack.DropStack(item, client)
	local inventory = ix.item.inventories[item.invID or 0]

	if (!inventory or !item.isStackable or !item.gridX or !item.gridY) then
		return item:Transfer(nil, nil, nil, client)
	end

	local key = SlotKey(item.gridX, item.gridY)
	local stack = inventory.stacks and inventory.stacks[key]

	if (!stack or #stack <= 1 or stack[1].id != item.id) then
		return item:Transfer(nil, nil, nil, client)
	end

	local itemIDs = {}

	for _, stackItem in ipairs(stack) do
		itemIDs[#itemIDs + 1] = stackItem.id
	end

	for _, itemID in ipairs(itemIDs) do
		local stackItem = ix.item.instances[itemID]

		if (stackItem) then
			local success, err = stackItem:Transfer(nil, nil, nil, client)

			if (!success) then
				return false, err
			end
		end
	end

	return true
end

-- ============================================
-- Inventory Meta Overrides
-- ============================================
local META = ix.meta.inventory

META.ixcOrigGetItems = META.ixcOrigGetItems or META.GetItems
META.ixcOrigRemove = META.ixcOrigRemove or META.Remove
META.ixcOrigIter = META.ixcOrigIter or META.Iter
META.ixcOrigGetItemCount = META.ixcOrigGetItemCount or META.GetItemCount

local ITEMMETA = ix.meta.item
if (ITEMMETA) then
	ITEMMETA.ixcOrigRemove = ITEMMETA.ixcOrigRemove or ITEMMETA.Remove
end

local function CleanupStackEntry(inventory, key)
	if (!inventory or !inventory.stacks or !key) then
		return nil
	end

	local stack = inventory.stacks[key]
	if (!stack) then
		return nil
	end

	for index = #stack, 1, -1 do
		local stackItem = stack[index]
		local liveItem = stackItem and ix.item.instances[stackItem.id]

		if (!liveItem or liveItem.invID != inventory:GetID() or !liveItem.gridX or !liveItem.gridY or SlotKey(liveItem.gridX, liveItem.gridY) != key) then
			table.remove(stack, index)
		else
			stack[index] = liveItem
		end
	end

	if (#stack <= 1) then
		inventory.stacks[key] = nil

		if (stack[1]) then
			inventory.slots[stack[1].gridX] = inventory.slots[stack[1].gridX] or {}
			inventory.slots[stack[1].gridX][stack[1].gridY] = stack[1]
		end

		return nil
	end

	return inventory.stacks[key]
end

--- Override GetItems to include ALL stacked items
function META:GetItems(onlyMain)
	local items = self:ixcOrigGetItems(onlyMain) or {}

	if (self.stacks) then
		for key, _ in pairs(self.stacks) do
			local stack = CleanupStackEntry(self, key)

			if (stack) then
				for _, stackItem in ipairs(stack) do
					if (!items[stackItem.id]) then
						items[stackItem.id] = stackItem
						stackItem.data = stackItem.data or {}
					end
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

	if (!item) then
		if (self.stacks) then
			for key, _ in pairs(self.stacks) do
				CleanupStackEntry(self, key)
			end
		end

		return nil
	end

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

					-- Refresh the slot icon when the representative changes, otherwise just sync stack data.
					ReplicateSlotState(self, x, y, receivers, newRep)
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

if (ITEMMETA) then
	function ITEMMETA:Remove(bNoReplication, bNoDelete)
		local liveItem = ix.item.instances[self.id]

		if (!liveItem) then
			return false
		end

		if (liveItem != self) then
			return liveItem:Remove(bNoReplication, bNoDelete)
		end

		local inventory = ix.item.inventories[self.invID or 0]

		if (inventory and self.isStackable and self.gridX and self.gridY and inventory.stacks) then
			local key = SlotKey(self.gridX, self.gridY)
			local stack = inventory.stacks[key]

			if (stack and #stack > 1) then
				inventory:Remove(self.id, bNoReplication, bNoDelete)
				return true
			end
		end

		return self:ixcOrigRemove(bNoReplication, bNoDelete)
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
	util.AddNetworkString("ixStackMoveSingle")

	META.ixcOrigSync = META.ixcOrigSync or META.Sync
	META.ixcOrigSendSlot = META.ixcOrigSendSlot or META.SendSlot

	--- Override Sync to include stack data
	function META:Sync(receiver)
		PLUGIN.stack.RebuildForInventory(self)

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

		if (!sourceInv) then
			return false
		end

	RebuildInventories(sourceInv, inventory)
		local sourceX, sourceY = sourceItem.gridX, sourceItem.gridY
		local targetX, targetY = targetItem.gridX, targetItem.gridY
		local sourceKey = SlotKey(sourceX, sourceY)
		local sourceStack = sourceInv.stacks and sourceInv.stacks[sourceKey] or {sourceItem}
		local previousSourceRepresentative = sourceStack and sourceStack[1] or nil
		local maxStack = targetItem.maxStack or sourceItem.maxStack or 6
		local targetCount = PLUGIN.stack.GetCount(targetItem)
		local moveCount = math.min(maxStack - targetCount, #sourceStack)

		if (moveCount <= 0) then
			return false
		end

		local moveItems = {}
		local firstMoveIndex = #sourceStack - moveCount + 1

		for index = firstMoveIndex, #sourceStack do
			moveItems[#moveItems + 1] = sourceStack[index]
		end

		if (moveCount >= #sourceStack) then
			ClearSlotArea(sourceInv, sourceX, sourceY, sourceItem.width, sourceItem.height)
		end

		local sourceRepresentativeMoved = false

		for _, movingItem in ipairs(moveItems) do
			if (previousSourceRepresentative and movingItem.id == previousSourceRepresentative.id) then
				sourceRepresentativeMoved = true
			end

			movingItem.gridX = targetX
			movingItem.gridY = targetY
			movingItem.invID = inventory:GetID()

			if (!inventory.noSave) then
				local query = mysql:Update("ix_items")
					query:Update("inventory_id", inventory:GetID())
					query:Update("x", targetX)
					query:Update("y", targetY)
					query:Where("item_id", movingItem.id)
				query:Execute()
			end

			if (sourceInv != inventory) then
				if (movingItem.OnTransferred) then
					movingItem:OnTransferred(sourceInv, inventory)
				end

				hook.Run("OnItemTransferred", movingItem, sourceInv, inventory)
				RunInventoryItemAdded(sourceInv, inventory, movingItem)
			end
		end

		RebuildInventories(sourceInv, inventory)

		local sourceReceivers = sourceInv:GetReceivers()
		if (istable(sourceReceivers)) then
			if (sourceRepresentativeMoved) then
				ReplicateSlotState(sourceInv, sourceX, sourceY, sourceReceivers, GetRepresentativeAt(sourceInv, sourceX, sourceY), previousSourceRepresentative)
			else
				SyncStackSlot(sourceInv, sourceX, sourceY, sourceReceivers)
			end
		end

		local targetReceivers = inventory:GetReceivers()
		if (istable(targetReceivers)) then
			SyncStackSlot(inventory, targetX, targetY, targetReceivers)
		end

		return true
	end

	--- Handle stack combine requests from clients (drag & drop stacking)
	net.Receive("ixInventoryMove", function(length, client)
		local oldX, oldY, x, y = net.ReadUInt(6), net.ReadUInt(6), net.ReadUInt(6), net.ReadUInt(6)
		local invID, newInvID = net.ReadUInt(32), net.ReadUInt(32)
		local character = client:GetCharacter()

		if (!character) then
			return
		end

		local inventory = ix.item.inventories[invID]

		if (!inventory) then
			return
		end

		if ((inventory.owner and inventory.owner == character:GetID()) or inventory:OnCheckAccess(client)) then
			local item = inventory:GetItemAt(oldX, oldY)

			if (item) then
				local key = SlotKey(item.gridX, item.gridY)
				local stack = inventory.stacks and inventory.stacks[key]
				local isStackMove = stack and #stack > 1 and stack[1] and stack[1].id == item.id

				if (newInvID and invID != newInvID) then
					local inventory2 = ix.item.inventories[newInvID]

					if (inventory2) then
						local bStatus, error

						if (isStackMove) then
							bStatus, error = PLUGIN.stack.TransferStack(item, inventory2, x, y, client)
						else
							bStatus, error = item:Transfer(newInvID, x, y, client)
						end

						if (!bStatus) then
							NetworkInventoryMove(client, item.invID, item:GetID(), item.gridX, item.gridY, item.gridX, item.gridY)
							client:NotifyLocalized(error or "unknownError")
						end
					end

					return
				end

				if (isStackMove) then
					local bStatus, error = PLUGIN.stack.MoveStack(inventory, item, x, y, client)

					if (!bStatus) then
						NetworkInventoryMove(client, item.invID, item:GetID(), item.gridX, item.gridY, item.gridX, item.gridY)

						if (error and error != "invalidStack") then
							client:NotifyLocalized(error)
						end
					end

					return
				end

				if (inventory:CanItemFit(x, y, item.width, item.height, item)) then
					item.gridX = x
					item.gridY = y

					for x2 = 0, item.width - 1 do
						for y2 = 0, item.height - 1 do
							local previousX = inventory.slots[oldX + x2]

							if (previousX) then
								previousX[oldY + y2] = nil
							end
						end
					end

					for x2 = 0, item.width - 1 do
						for y2 = 0, item.height - 1 do
							inventory.slots[x + x2] = inventory.slots[x + x2] or {}
							inventory.slots[x + x2][y + y2] = item
						end
					end

					local receivers = inventory:GetReceivers()

					if (istable(receivers)) then
						local filtered = FilterReceivers(receivers, client)

						if (istable(filtered) and #filtered > 0) then
							NetworkInventoryMove(filtered, invID, item:GetID(), oldX, oldY, x, y)
						end
					end

					if (!inventory.noSave) then
						local query = mysql:Update("ix_items")
							query:Update("x", x)
							query:Update("y", y)
							query:Where("item_id", item.id)
						query:Execute()
					end
				else
					NetworkInventoryMove(client, item.invID, item:GetID(), item.gridX, item.gridY, item.gridX, item.gridY)
				end
			end
		else
			local item = inventory:GetItemAt(oldX, oldY)

			if (item) then
				NetworkInventoryMove(client, item.invID, item:GetID(), item.gridX, item.gridY, item.gridX, item.gridY)
			end
		end
	end)

	net.Receive("ixStackMoveSingle", function(length, client)
		local sourceInvID = net.ReadUInt(32)
		local targetInvID = net.ReadUInt(32)
		local itemID = net.ReadUInt(32)
		local x = net.ReadUInt(6)
		local y = net.ReadUInt(6)
		local character = client:GetCharacter()

		if (!character) then return end

		local sourceInv = ix.item.inventories[sourceInvID]
		if (!sourceInv) then return end

		if (!((sourceInv.owner and sourceInv.owner == character:GetID()) or sourceInv:OnCheckAccess(client))) then
			return
		end

		local item = ix.item.instances[itemID]
		if (!item or item.invID != sourceInvID or !item.isStackable) then return end

		if (targetInvID != sourceInvID) then
			local targetInv = ix.item.inventories[targetInvID]
			if (!targetInv) then return end

			if (!((targetInv.owner and targetInv.owner == character:GetID()) or targetInv:OnCheckAccess(client))) then
				return
			end

			local targetItem = targetInv:GetItemAt(x, y)
			local success, err

			if (targetItem and PLUGIN.stack.CanStack(targetItem, item)) then
				success, err = PLUGIN.stack.TransferSingle(sourceInv, item, targetInv, x, y)
			else
				success, err = item:Transfer(targetInvID, x, y, client)
			end

			if (!success and err and err != "same inv" and err != "sameSlot") then
				client:NotifyLocalized(err)
			end

			return
		end

		local success, err = PLUGIN.stack.MoveSingle(sourceInv, item, x, y)
		if (!success and err and err != "sameSlot") then
			client:NotifyLocalized(err)
		end
	end)

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
		local oldRepresentative = stack[1]

		-- Unregister from stack
		local newRep = PLUGIN.stack.Unregister(inventory, item)

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
			-- Refresh the old slot icon if splitting changed the representative.
			local parts = string.Explode(":", oldKey)
			local oldX, oldY = tonumber(parts[1]), tonumber(parts[2])
			ReplicateSlotState(inventory, oldX, oldY, receivers, newRep, oldRepresentative)

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
		local oldRepresentative = slotItem

		PLUGIN.stack.Reorder(inventory, slotItem, newOrder)

		local receivers = inventory:GetReceivers()
		local key = SlotKey(x, y)
		local stack = inventory.stacks[key]

		if (stack and istable(receivers)) then
			ReplicateSlotState(inventory, x, y, receivers, stack[1], oldRepresentative)
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

		-- Helix inventory sync owns slot representatives and icon panels.
		-- Stack sync only updates hidden members and ordering for a slot.

		local stackManager = ix.gui and ix.gui.stackManager
		if (IsValid(stackManager) and stackManager.inventory == inventory and stackManager.stackX == x and stackManager.stackY == y) then
			if (#syncedItems > 1) then
				stackManager.stackItems = table.Copy(syncedItems)
				stackManager:Populate()
			else
				stackManager:Close()
			end
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

			local dropFunc = itemTable.functions.drop
			if (dropFunc and !dropFunc.ixStackWrapped) then
				local originalDropRun = dropFunc.OnRun

				dropFunc.OnRun = function(item, data)
					if (SERVER) then
						local success, err = PLUGIN.stack.DropStack(item, item.player)

						if (!success and err and IsValid(item.player)) then
							item.player:NotifyLocalized(err)
						elseif (success and IsValid(item.player)) then
							item.player:EmitSound("npc/zombie/foot_slide" .. math.random(1, 3) .. ".wav", 75, math.random(90, 120), 1)
						end
					end

					if (originalDropRun and !SERVER) then
						return originalDropRun(item, data)
					end

					return false
				end

				dropFunc.ixStackWrapped = true
			end

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

local function RebuildLoadedInventories(syncReceivers)
	for _, inventory in pairs(ix.item.inventories) do
		if (inventory and inventory.slots) then
			PLUGIN.stack.RebuildForInventory(inventory)

			if (SERVER and syncReceivers) then
				local receivers = inventory:GetReceivers()

				if (istable(receivers)) then
					for key, stack in pairs(inventory.stacks or {}) do
						if (stack and #stack > 1) then
							local parts = string.Explode(":", key)
							local x, y = tonumber(parts[1]), tonumber(parts[2])

							if (x and y) then
								SyncStackSlot(inventory, x, y, receivers)
							end
						end
					end
				end
			end
		end
	end
end

hook.Add("InitializedPlugins", "ixItemStackRebuildLoaded", function()
	RebuildLoadedInventories(true)
end)

-- Rebuild stacks when a character's inventory is loaded
hook.Add("CharacterLoaded", "ixItemStack", function(character)
	timer.Simple(0, function()
		if (!character) then return end

		local client = character.GetPlayer and character:GetPlayer() or nil
		local invList = character:GetInventory(true)
		local inventories = {}

		if (istable(invList)) then
			inventories = invList
		elseif (invList) then
			inventories[1] = invList
		end

		for _, inv in ipairs(inventories) do
			if (inv and inv.slots) then
				PLUGIN.stack.RebuildForInventory(inv)

				if (SERVER and IsValid(client)) then
					inv:Sync(client)
				end
			end
		end
	end)
end)

-- Register new items into stacks at runtime
hook.Add("InventoryItemAdded", "ixItemStack", function(oldInv, newInv, item)
	if (!SERVER or !item or item.ixSkipAutoStack or !item.isStackable or !newInv) then
		return
	end

	newInv.stacks = newInv.stacks or {}
	PLUGIN.stack.Register(newInv, item)

	local targetItem = PLUGIN.stack.FindAutoStackTarget(newInv, item)

	if (targetItem) then
		PLUGIN.stack.DoStack(newInv, targetItem, item)
	end
end)



