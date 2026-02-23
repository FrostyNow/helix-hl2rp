ITEM.name = "Ale"
ITEM.description = "itemAleDesc"
ITEM.model = "models/hlvr/props/bottles/garbage_glassbottle001a.mdl"
ITEM.force = 5
ITEM.thirst = 20
ITEM.price = 10

ITEM:Hook("Drink", function(item)
	local client = item.player
	
	client:EmitSound("interface/inv_beer.ogg")
end)