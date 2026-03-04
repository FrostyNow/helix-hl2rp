ITEM.name = "Vodka"
ITEM.description = "itemVodkaDesc"
ITEM.model = "models/hlvr/props/bottles/bottle_vodka.mdl"
ITEM.force = 10
ITEM.thirst = 25
ITEM.price = 20
ITEM.empty = "glass_bottle_generic"

ITEM:Hook("Drink", function(item)
	local client = item.player
	
	client:EmitSound("interface/inv_beer.ogg")
end)