ITEM.name = "Breen's Water"
ITEM.model = "models/hls/alyxports/popcan01a_hls.mdl"
ITEM.description = "itemWaterDesc"
ITEM.thirst = 15
ITEM.price = 5
ITEM.empty = "water_empty"
ITEM.sound = "interface/inv_drink_can2.ogg"

ITEM:Hook("Eat", function(item)
	local client = item.player
	local char = client:GetCharacter()
	local stm = char:GetAttribute("stm", 0)

	char:AddBoost("water", "stm", stm * 0.9 )
end)