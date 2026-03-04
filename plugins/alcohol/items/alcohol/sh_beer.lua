ITEM.name = "Beer"
ITEM.description = "itemBeerDesc"
ITEM.model = "models/hlvr/props/bottles/bear_bottle_1.mdl"
ITEM.force = 5
ITEM.thirst = 20
ITEM.price = 10
ITEM.empty = "glass_bottle_generic"

ITEM:Hook("Drink", function(item)
	local client = item.player
	
	client:EmitSound("interface/inv_beer.ogg")
end)