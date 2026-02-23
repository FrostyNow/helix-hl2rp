ITEM.name = "Gin"
ITEM.description = "itemGinDesc"
ITEM.model = "models/hlvr/props/bottles/bottle_o_gin.mdl"
ITEM.force = 10
ITEM.thirst = 25
ITEM.price = 20

ITEM:Hook("Drink", function(item)
	local client = item.player
	
	client:EmitSound("interface/inv_beer.ogg")
end)