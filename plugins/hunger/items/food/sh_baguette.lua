ITEM.name = "Baguette"
ITEM.model = "models/hlvr/food/bread01a.mdl"
ITEM.description = "itemBaguetteDesc"
ITEM.hunger = 40
ITEM.thirst = -10
ITEM.price = 5

ITEM:Hook("Eat", function(item)
	local client = item.player
	
	client:EmitSound("npc/barnacle/barnacle_gulp2.wav")

	for i = 1, 5 do
		timer.Simple(i, function()
			client:SetHealth(math.Clamp(client:Health() + 1, 0, client:GetMaxHealth()))
		end)
	end
end)