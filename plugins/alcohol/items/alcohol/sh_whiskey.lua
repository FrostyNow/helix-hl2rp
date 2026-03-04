ITEM.name = "Whiskey"
ITEM.description = "itemWhiskeyDesc"
ITEM.model = "models/mosi/fallout4/props/alcohol/whiskey.mdl"
ITEM.force = 10
ITEM.thirst = 25
ITEM.price = 40
ITEM.empty = "glass_bottle_generic"

ITEM:Hook("Drink", function(item)
	local client = item.player
	
	client:EmitSound("interface/inv_beer.ogg")
end)