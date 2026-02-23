ITEM.name = "Mineral Water"
ITEM.model = "models/hlvr/props/bottles/plastic_bottle_1.mdl"
ITEM.description = "itemMineralWaterDesc"
ITEM.thirst = 100
ITEM.price = 10
ITEM.empty = "empty_can"

ITEM:Hook("Eat", function(item)
	local client = item.player
	
	client:EmitSound("npc/barnacle/barnacle_gulp2.wav")

	for i = 1, 5 do
		timer.Simple(i, function()
			client:SetHealth(math.Clamp(client:Health() + 2, 0, client:GetMaxHealth()))
		end)
	end
end)