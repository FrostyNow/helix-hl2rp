ITEM.name = "Base Container Furniture"
ITEM.description = "A cool description"
ITEM.price = 50
ITEM.category = "Containers"
ITEM.width = 2
ITEM.height = 2
-- Inventory Model
ITEM.model = "models/Items/item_item_crate.mdl"

--[[Container model

 MAKE SURE YOU HAVE REGISTER A CONTAINER IN HELIX/PLUGINS/CONTAINERS/sh_definitions.lua

--]]
ITEM.ContainerModel = "models/props_junk/wood_crate001a.mdl"

ITEM.functions.Use = {
	name = "Place",
	icon = "icon16/anchor.png",
	OnRun = function(item)
		local client = item.player

		hook.Run("ContainerFurnitureSpawn", item)
		return true
	end
}
