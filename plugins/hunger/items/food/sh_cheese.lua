ITEM.name = "Truckle"
ITEM.model = "models/bioshockinfinite/pound_cheese.mdl"
ITEM.description = "itemCheeseDesc"
ITEM.hunger = 15
ITEM.price = 120
ITEM.heal = 5
ITEM.usenum = 8

ITEM.functions.Eat.OnCanRun = function(item)
	return false
end