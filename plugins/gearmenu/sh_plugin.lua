local PLUGIN = PLUGIN

PLUGIN.Title = "Gear Menu"
PLUGIN.Author = "Ronald and Frosty"
PLUGIN.Description = "Make menu for store equipment gear so it doesn't have slot in inventory."
PLUGIN.Version = "2.0.0"

PLUGIN.GearInvWidth = 50
PLUGIN.GearInvHeight = 50

ix.lang.AddTable("english", {
	["gear"] = "Inventory",
	gearTooltip = "Drag and drop\nto equip or unequip.",
})
ix.lang.AddTable("korean", {
	["gear"] = "소지품 및 장비",
	["Inventory"] = "소지품",
	["Equipment"] = "장비",
	gearTooltip = "장비를 드래그 드랍하여\n장착하거나 해제하실 수 있습니다.",
})

ix.inventory.Register("ixGearInv", PLUGIN.GearInvWidth, PLUGIN.GearInvHeight, true)

-- Helper: check if an inventory is a gear inventory.
function PLUGIN:IsGearInventory(invID)
	local inv = ix.item.inventories[invID]
	return inv and inv.vars and inv.vars.isGear
end

-- ============================================================
-- GLOBAL OVERRIDE: ix.meta.inventory
-- Make GetItems() universally return Gear Items for compatibility
-- ============================================================
local ix_inv = ix.meta.inventory
if (ix_inv) then
	ix_inv.GearOriginalGetItems = ix_inv.GearOriginalGetItems or ix_inv.GetItems

	function ix_inv:GetItems(onlyMain)
		local items = self:GearOriginalGetItems(onlyMain)

		-- Only inject gear items when directly querying a character's primary main inventory.
		-- onlyMain = false natively allows bags via base GetItems. Here we extend it to gear.
		if (onlyMain != true and !self.vars.isBag and !self.vars.isGear and self.owner) then
			local character = ix.char.loaded and ix.char.loaded[self.owner]
			
			if (character and character:GetInventory() == self) then
				local gearID = character:GetData("gearInvID")
				local gearInv = gearID and ix.item.inventories[gearID]

				if (gearInv and gearInv != self) then
					for itemID, itemInst in pairs(gearInv:GearOriginalGetItems(true)) do
						items[itemID] = itemInst
					end
				end
			end
		end

		return items
	end
end

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")