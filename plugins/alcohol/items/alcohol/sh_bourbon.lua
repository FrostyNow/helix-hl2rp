ITEM.name = "Bourbon"
ITEM.description = "itemBourbonDesc"
ITEM.model = "models/mosi/fallout4/props/alcohol/bourbon.mdl"
ITEM.force = 10
ITEM.thirst = 25
ITEM.price = 40
ITEM.empty = "glass_bottle_generic"

ITEM:Hook("Drink", function(item)
	local client = item.player
	
	client:EmitSound("interface/inv_beer.ogg")
end)