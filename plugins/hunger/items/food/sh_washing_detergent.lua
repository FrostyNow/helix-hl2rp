ITEM.name = "Washing Detergent"
ITEM.description = "itemWashingDetergentDesc"
ITEM.model = "models/hlvr/props/bottles/washing_detergent_bottle001.mdl"
ITEM.thirst = 30
ITEM.price = 20

ITEM:Hook("Eat", function(item)
	local client = item.player
	
	client:EmitSound("npc/barnacle/barnacle_gulp2.wav")

	for i = 1, 10 do
		timer.Simple(i, function()
			client:SetHealth(math.Clamp(client:Health() - 2, 0, client:GetMaxHealth()))
		end)
	end
end)