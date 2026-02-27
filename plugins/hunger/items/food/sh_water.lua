ITEM.name = "Breen's Water"
ITEM.model = "models/props_junk/PopCan01a.mdl"
ITEM.description = "itemWaterDesc"
ITEM.thirst = 50
ITEM.price = 1
ITEM.empty = "water_empty"
ITEM.sound = "interface/inv_drink_can2.ogg"

ITEM:Hook("Eat", function(item)
	local client = item.player
	local char = client:GetCharacter()
	local stm = char:GetAttribute("stm", 0)

	char:AddBoost("water", "stm", stm * 0.9 )
end)