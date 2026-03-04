ITEM.name = "Wine"
ITEM.description = "itemWineDesc"
ITEM.model = "models/hlvr/props/bottles/garbage_glassbottle003a.mdl"
ITEM.height = 2
ITEM.force = 5
ITEM.thirst = 15
ITEM.price = 30
ITEM.empty = "glass_bottle_generic"

ITEM:Hook("Drink", function(item)
	local client = item.player
	
	client:EmitSound("interface/inv_beer.ogg")
end)