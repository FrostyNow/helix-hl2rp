ITEM.name = "Vodka"
ITEM.description = "itemVodkaDesc"
ITEM.model = "models/hlvr/props/bottles/bottle_vodka.mdl"
ITEM.thirst = 25
ITEM.price = 25
ITEM.empty = "glass_bottle_generic"
ITEM.strength = 2

ITEM:Hook("Drink", function(item)
	local client = item.player
	
	client:EmitSound("interface/inv_beer.ogg")
end)