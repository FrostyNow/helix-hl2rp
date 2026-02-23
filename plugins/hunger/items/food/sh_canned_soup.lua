ITEM.name = "Canned Soup"
ITEM.model = "models/bioschockinfinite/canned_soup.mdl"
ITEM.description = "itemCannedDesc"
ITEM.hunger = 40
ITEM.thirst = 10
ITEM.price = 5
ITEM.empty = "empty_can"

ITEM:Hook("Eat", function(item)
	local client = item.player
	
	client:EmitSound("interface/inv_eat_can.ogg")
	for i = 1, 5 do
		timer.Simple(i, function()
			client:SetHealth(math.Clamp(client:Health() + 1, 0, client:GetMaxHealth()))
		end)
	end
end)