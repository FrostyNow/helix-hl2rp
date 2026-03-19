ITEM.name = "Bourbon"
ITEM.description = "itemBourbonDesc"
ITEM.model = "models/mosi/fallout4/props/alcohol/bourbon.mdl"
ITEM.thirst = 25
ITEM.price = 60
ITEM.empty = "glass_bottle_generic"
ITEM.strength = 2

ITEM:Hook("Drink", function(item)
	local client = item.player
	
	client:EmitSound("interface/inv_beer.ogg")
end)