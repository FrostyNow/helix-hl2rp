ITEM.name = "Whiskey"
ITEM.description = "itemWhiskeyDesc"
ITEM.model = "models/mosi/fallout4/props/alcohol/whiskey.mdl"
ITEM.thirst = 25
ITEM.price = 25
ITEM.empty = "glass_bottle_generic"
ITEM.strength = 2

ITEM:Hook("Drink", function(item)
	local client = item.player
	
	client:EmitSound("interface/inv_beer.ogg")
end)