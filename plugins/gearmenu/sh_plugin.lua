local PLUGIN = PLUGIN

PLUGIN.Title = "Gear Menu"
PLUGIN.Author = "Ronald"
PLUGIN.Description = "Make menu for store equipment gear so it doesn't have slot in inventory."
PLUGIN.Version = "1.0.0"

-- Define all available gear slots. Base slots.
PLUGIN.GearSlots = {
	{id = "head", name = "Head", icon = "icon16/user.png"},
	{id = "face", name = "Face", icon = "icon16/eye.png"},
	{id = "torso", name = "Torso", icon = "icon16/shield.png"},
	{id = "legs", name = "Legs", icon = "icon16/arrow_down.png"},
	{id = "back", name = "Back", icon = "icon16/basket.png"},
	{id = "belt", name = "Belt"},
	{id = "weapon1", name = "Weapon", icon = "icon16/gun.png"}
}

-- Gear inventory: 1 column, N rows (one per slot).
-- Each slot maps to Y position: slot index 1 = y:1, slot index 2 = y:2, etc.
PLUGIN.GearInvWidth = 15
PLUGIN.GearInvHeight = 30

-- Allow other plugins to add or modify gear slots per character.
function PLUGIN:GetCharacterGearSlots(character)
	-- deep copy the base slots
	local slots = table.Copy(self.GearSlots)

	-- Add dynamically granted extra slots (like from belts or bags)
	if (character) then
		local extraSlots = character:GetData("extraGearSlots", {})
		for _, extraSlotID in ipairs(extraSlots) do
			if (extraSlotID == "weapon2") then
				table.insert(slots, {
					id = "weapon2",
					name = "Secondary Weapon",
					icon = "icon16/bomb.png"
				})
			end
			-- Add other dynamic slot definitions here as needed
		end
	end

	-- pass the character and the copied slots table to listeners
	hook.Run("ixGearMenuSlots", slots, character)

	return slots
end

-- Helper: find a gear slot definition by id.
function PLUGIN:GetGearSlotByID(character, slotID)
	for _, slot in ipairs(self:GetCharacterGearSlots(character)) do
		if (slot.id == slotID) then
			return slot
		end
	end
end

-- Helper: get the slot Y-position (1-indexed) in the gear inventory grid.
function PLUGIN:GetGearSlotIndex(character, slotID)
	for i, slot in ipairs(self:GetCharacterGearSlots(character)) do
		if (slot.id == slotID) then
			return i
		end
	end
end

-- Helper: get the slot ID from a Y-position index.
function PLUGIN:GetGearSlotIDByIndex(character, index)
	local slots = self:GetCharacterGearSlots(character)
	local slot = slots[index]
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