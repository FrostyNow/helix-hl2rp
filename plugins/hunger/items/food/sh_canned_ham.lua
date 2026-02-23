ITEM.name = "Canned Ham"
ITEM.model = "models/hlvr/food/can_square.mdl"
ITEM.description = "itemCannedHamDesc"
ITEM.hunger = 20
ITEM.thirst = -10
ITEM.price = 5

ITEM:Hook("Eat", function(item)
	local client = item.player
	
	client:EmitSound("npc/barnacle/barnacle_gulp2.wav")

	for i = 1, 10 do
		timer.Simple(i, function()
			client:SetHealth(math.Clamp(client:Health() + 1, 0, client:GetMaxHealth()))
		end)
	end
end)