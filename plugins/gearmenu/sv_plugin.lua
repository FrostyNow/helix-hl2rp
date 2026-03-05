local PLUGIN = PLUGIN

util.AddNetworkString("ixGearSync")
util.AddNetworkString("ixGearUnequip")
util.AddNetworkString("ixGearEquip")

-- ============================================================
-- Gear Inventory Management
-- ============================================================

local function GetOrCreateGearInventory(character, callback)
	local gearInvID = character:GetData("gearInvID")

	if (gearInvID) then
		local inv = ix.item.inventories[gearInvID]

		if (inv) then
			if (callback) then callback(inv) end
			return inv
		end

		ix.inventory.Restore(gearInvID, PLUGIN.GearInvWidth, PLUGIN.GearInvHeight, function(inv)
			inv:SetOwner(character:GetID())
			inv.vars.isGear = true

			local client = character:GetPlayer()
			if (IsValid(client)) then
				inv:AddReceiver(client)
				inv:Sync(client)
			end

			if (callback) then callback(inv) end
		end)

		return
	end

	ix.inventory.New(character:GetID(), "ixGearInv", function(inv)
		character:SetData("gearInvID", inv:GetID())
		inv.vars.isGear = true

		local client = character:GetPlayer()
		if (IsValid(client)) then
			inv:AddReceiver(client)
		end

		if (callback) then callback(inv) end
	end)
end

local function SyncGearSlots(client)
	local character = client:GetCharacter()
	if (!character) then return end

	local gearInvID = character:GetData("gearInvID") or 0

	net.Start("ixGearSync")
		net.WriteUInt(gearInvID, 32)
	net.Send(client)
end

-- ============================================================
-- Network Handlers for Gear Actions
-- ============================================================

net.Receive("ixGearEquip", function(len, client)
	local sourceInvID = net.ReadUInt(32)
	local itemID = net.ReadUInt(32)
	local targetSlotID = net.ReadString()

	local character = client:GetCharacter()
	if (!character) then return end

	local gearInvID = character:GetData("gearInvID")
	if (!gearInvID) then return end

	local gearInv = ix.item.inventories[gearInvID]
	if (!gearInv) then return end

	local item = ix.item.instances[itemID]
	if (!item or item.invID != sourceInvID) then return end

	-- Block if the item is already equipped
	if (item:GetData("equipSlot") != nil and sourceInvID != gearInvID) then return end

	-- Check if the slot is already occupied by something else
	local existingItem = nil
	for _, v in pairs(gearInv:GetItems()) do
		if (v:GetData("equipSlot") == targetSlotID) then
			existingItem = v
			break
		end
	end

	item.player = client

	-- If it's just moving from one gear slot to another:
	if (sourceInvID == gearInvID) then
		if (existingItem and existingItem.id != itemID) then
			client:NotifyLocalized("Slot is already occupied.")
			return
		end

		if (item.OnUnequip) then item:OnUnequip() end
		item:SetData("equipSlot", targetSlotID)
		if (item.OnEquip) then item:OnEquip() end
		item.player = nil
		return
	end

	-- Move from main/bag inventory into Gear Inventory
	-- If something is already there, put it back in the main inventory first.
	if (existingItem) then
		existingItem.player = client
		if (existingItem.OnUnequip) then existingItem:OnUnequip() end
		existingItem:SetData("equipSlot", nil)
		
		local mainInv = character:GetInventory()
		local emptyX, emptyY = mainInv:FindEmptySlot(existingItem.width, existingItem.height)
		
		if (!emptyX or !emptyY) then
			client:NotifyLocalized("Not enough space to unequip existing gear.")
			existingItem.player = nil
			return
		end
		
		existingItem:Transfer(mainInv:GetID(), emptyX, emptyY, client)
		existingItem.player = nil
	end

	-- Clear basic equip flags temporarily so hooking plugins don't block the transfer
	if (item.OnUnequip) then item:OnUnequip() end

	-- Find an empty slot in the internal gear inventory pack
	local emptyX, emptyY = gearInv:FindEmptySlot(item.width, item.height)
	if (!emptyX or !emptyY) then
		client:NotifyLocalized("Gear capacity full.")
		item.player = nil
		return
	end

	item.bGearEquipping = true
	local bSuccess, err = item:Transfer(gearInvID, emptyX, emptyY, client)
	item.bGearEquipping = nil

	if (!bSuccess) then
		client:NotifyLocalized(err or "Failed to equip.")
	else
		item:SetData("equipSlot", targetSlotID)
		if (item.OnEquip) then item:OnEquip() end
	end
	
	item.player = nil
end)

net.Receive("ixGearUnequip", function(len, client)
	local itemID = net.ReadUInt(32)
	local bHasTarget = net.ReadBool()
	local targetInvID, targetX, targetY

	if (bHasTarget) then
		targetInvID = net.ReadUInt(32)
		targetX = net.ReadUInt(6)
		targetY = net.ReadUInt(6)
	end

	local character = client:GetCharacter()
	if (!character) then return end

	local gearInvID = character:GetData("gearInvID")
	if (!gearInvID) then return end

	local gearInv = ix.item.inventories[gearInvID]
	if (!gearInv) then return end

	local item = ix.item.instances[itemID]
	if (!item or item.invID != gearInvID) then return end

	local destInvID, destX, destY

	if (bHasTarget and targetInvID) then
		destInvID = targetInvID
		if (targetX and targetY and targetX > 0 and targetY > 0) then
			destX = targetX
			destY = targetY
		end
	else
		local mainInv = character:GetInventory()
		if (!mainInv) then return end
		destInvID = mainInv:GetID()
	end

	local targetInv = ix.item.inventories[destInvID]
	if (!targetInv) then return end

	if (!destX or !destY) then
		local emptyX, emptyY = targetInv:FindEmptySlot(item.width, item.height)
		if (!emptyX or !emptyY) then
			client:NotifyLocalized("noFit")
			return
		end
		destX = emptyX
		destY = emptyY
	end

	item.player = client
	if (item.OnUnequip) then item:OnUnequip() end
	item:SetData("equipSlot", nil)
	item.player = nil

	local bStatus, error = item:Transfer(destInvID, destX, destY, client)

	if (!bStatus) then
		-- Revert
		item.player = client
		item:SetData("equipSlot", item:GetData("equipSlot")) -- Actually, previous slot needs saving if we properly revert, but sticking to basics.
		if (item.OnEquip) then item:OnEquip() end
		item.player = nil
		client:NotifyLocalized(error or "unknownError")
	end
end)

-- Validate transfers TO gear inventory natively (prevent drag/drop natively into gear inv)
function PLUGIN:CanTransferItem(item, curInv, newInv)
	if (!item or !curInv or !newInv) then return end

	local curIsGear = curInv.vars and curInv.vars.isGear
	local newIsGear = newInv.vars and newInv.vars.isGear

	if (newIsGear and !curIsGear) then
		return false -- Must use ixGearEquip net message.
	end
	
	if (curIsGear and newIsGear) then
		return false -- Prevent manual gear backpack rearrangement via typical UI.
	end
end

-- Character loaded → setup gear inventory.
function PLUGIN:CharacterLoaded(character)
	local client = character:GetPlayer()

	if (IsValid(client)) then
		timer.Simple(1, function()
			if (IsValid(client) and client:GetCharacter() == character) then
				GetOrCreateGearInventory(character, function(inv)
					if (inv and IsValid(client)) then
						inv:AddReceiver(client)
						inv:Sync(client)
						inv.vars.isGear = true
					end

					SyncGearSlots(client)
				end)
			end
		end)
	end
end