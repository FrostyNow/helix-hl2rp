ITEM.name = "Canned Beer"
ITEM.model = "models/props_junk/PopCan01a.mdl"
ITEM.description = "itemBeerDesc"
ITEM.skin = 2
ITEM.force = 5
ITEM.thirst = 35
ITEM.usenum = 1
ITEM.price = 35
ITEM.empty = "water_empty"

ITEM:Hook("Eat", function(item)
	local client = item.player
	
	client:EmitSound("interface/inv_drink_can2.ogg")

	for i = 1, 5 do
		timer.Simple(i, function()
			client:SetHealth(math.Clamp(client:Health() + 2, 0, client:GetMaxHealth()))
		end)
	end
end)