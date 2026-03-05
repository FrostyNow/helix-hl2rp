local PLUGIN = PLUGIN

PLUGIN.Title = "Gear Menu"
PLUGIN.Author = "Ronald"
PLUGIN.Description = "Make menu for store equipment gear so it doesn't have slot in inventory."
PLUGIN.Version = "1.0.0"

-- Define all available gear slots.
PLUGIN.GearSlots = {
	{id = "head", name = "Head", icon = "icon16/user.png"},
	{id = "face", name = "Face", icon = "icon16/eye.png"},
	{id = "torso", name = "Torso", icon = "icon16/shield.png"},
	{id = "legs", name = "Legs", icon = "icon16/arrow_down.png"},
	{id = "back", name = "Back", icon = "icon16/basket.png"},
	{id = "weapon_primary", name = "Primary Weapon", icon = "icon16/gun.png"},
	{id = "weapon_secondary", name = "Secondary Weapon", icon = "icon16/bomb.png"},
}

-- Gear inventory: 1 column, N rows (one per slot).
-- Each slot maps to Y position: slot index 1 = y:1, slot index 2 = y:2, etc.
PLUGIN.GearInvWidth = 1
PLUGIN.GearInvHeight = #PLUGIN.GearSlots

-- Register the gear inventory type.
ix.inventory.Register("ixGearInv", PLUGIN.GearInvWidth, PLUGIN.GearInvHeight)

-- Helper: find a gear slot definition by id.
function PLUGIN:GetGearSlotByID(slotID)
	for _, slot in ipairs(self.GearSlots) do
		if (slot.id == slotID) then
			return slot
		end
	end
end

-- Helper: get the slot Y-position (1-indexed) in the gear inventory grid.
function PLUGIN:GetGearSlotIndex(slotID)
	for i, slot in ipairs(self.GearSlots) do
		if (slot.id == slotID) then
			return i
		end
	end
end

-- Helper: get the slot ID from a Y-position index.
function PLUGIN:GetGearSlotIDByIndex(index)
	local slot = self.GearSlots[index]
	return slot and slot.id
end

-- Helper: check if an item can be placed in a given gear slot.
function PLUGIN:CanItemFitSlot(itemTable, slotID)
	if (!itemTable or !itemTable.gearSlot) then
		return false
	end

	if (istable(itemTable.gearSlot)) then
		for _, v in ipairs(itemTable.gearSlot) do
			if (v == slotID) then
				return true
			end
		end

		return false
	end

	return itemTable.gearSlot == slotID
end

-- Helper: check if an inventory is a gear inventory.
function PLUGIN:IsGearInventory(invID)
	local inv = ix.item.inventories[invID]
	return inv and inv.vars and inv.vars.isGear
end

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")