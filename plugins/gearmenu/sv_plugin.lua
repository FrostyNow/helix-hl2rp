local PLUGIN = PLUGIN

util.AddNetworkString("ixGearSync")
util.AddNetworkString("ixGearUnequip")

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
-- Custom Unequip: needed because ixInventoryMove can't send nil x/y
-- for FindEmptySlot behavior (Lua treats 0 as truthy).
-- ============================================================

net.Receive("ixGearUnequip", function(len, client)
	local gearGridY = net.ReadUInt(6)
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

	local item = gearInv:GetItemAt(1, gearGridY)
	if (!item) then return end

	-- Determine target inventory.
	local destInvID
	local destX, destY

	if (bHasTarget and targetInvID) then
		destInvID = targetInvID

		-- If specific coordinates are provided (and valid), use them.
		if (targetX and targetY and targetX > 0 and targetY > 0) then
			destX = targetX
			destY = targetY
		end
		-- Otherwise, destX and destY remain nil (auto-find slot in targetInvID).
	else
		-- Fallback to auto-find empty slot in main inventory.
		local mainInv = character:GetInventory()
		if (!mainInv) then return end

		destInvID = mainInv:GetID()
	local targetInv = ix.item.inventories[destInvID]
	if (!targetInv) then return end

	-- If no coords provided, explicitly find an empty slot.
	if (!destX or !destY) then
		local emptyX, emptyY = targetInv:FindEmptySlot(item.width, item.height)
		if (!emptyX or !emptyY) then
			client:NotifyLocalized("noFit")
			return
		end
		destX = emptyX
		destY = emptyY
	end

	-- IMPORTANT: Unequip BEFORE Transfer.
	-- Other plugins (better_armor, sh_suitcase) check equip data in
	-- CanTransferItem/CanTransfer and block equipped items from moving.
	item.player = client

	if (item.OnUnequip) then
		item:OnUnequip()
	end

	item.player = nil

	-- Transfer with equip already cleared.
	local bStatus, error = item:Transfer(destInvID, destX, destY, client)

	if (!bStatus) then
		-- Transfer failed → re-equip the item.
		item.player = client

		if (item.OnEquip) then
			item:OnEquip()
		end

		item.player = nil

		client:NotifyLocalized(error or "unknownError")
	end
end)

-- ============================================================
-- Hooks
-- ============================================================

-- Validate transfers TO gear inventory.
function PLUGIN:CanTransferItem(item, curInv, newInv)
	if (!item or !curInv or !newInv) then return end

	local curIsGear = curInv.vars and curInv.vars.isGear
	local newIsGear = newInv.vars and newInv.vars.isGear

	-- INTO gear: item must have a gearSlot field.
	if (newIsGear and !curIsGear) then
		if (!item.gearSlot) then
			return false
		end

		return
	end

	-- FROM gear to regular: always allowed.
	if (curIsGear and !newIsGear) then
		return
	end

	-- Between two gear inventories: not allowed.
	if (curIsGear and newIsGear) then
		return false
	end
end

local function UnequipItem(item, client)
	item.player = client

	if (item.OnUnequip) then
		item:OnUnequip()
	end

	item.player = nil
end

local function EquipItem(item, client)
	item.player = client

	if (item.OnEquip) then
		item:OnEquip()
	end

	item.player = nil
end

-- Item added to gear inventory → equip.
function PLUGIN:InventoryItemAdded(oldInv, newInv, item)
	if (!newInv or !item) then return end

	if (newInv.vars and newInv.vars.isGear) then
		local owner = newInv:GetOwner()
		if (!IsValid(owner)) then return end

		EquipItem(item, owner)
	end
end

-- Item removed from gear inventory (delete/drop) → unequip.
function PLUGIN:InventoryItemRemoved(inventory, item)
	if (!item or !inventory) then return end

	if (inventory.vars and inventory.vars.isGear) then
		local owner = inventory:GetOwner()
		if (!IsValid(owner)) then return end

		UnequipItem(item, owner)
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