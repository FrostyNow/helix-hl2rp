local PLUGIN = PLUGIN

PLUGIN.Title = "Gear Menu"
PLUGIN.Author = "Ronald"
PLUGIN.Description = "Make menu for store equipment gear so it doesn't have slot in inventory."
PLUGIN.Version = "2.0.0"

PLUGIN.GearInvWidth = 50
PLUGIN.GearInvHeight = 50

ix.lang.AddTable("english", {
	["gear"] = "Inventory",
})
ix.lang.AddTable("korean", {
	["gear"] = "소지품 및 장비",
	["Inventory"] = "소지품",
	["Equipment"] = "장비",
})

ix.inventory.Register("ixGearInv", PLUGIN.GearInvWidth, PLUGIN.GearInvHeight, true)

function PLUGIN:IsGearInventory(invID)
	local inv = ix.item.inventories[invID]
	return inv and inv.vars and inv.vars.isGear
end

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")