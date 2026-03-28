ITEM.name = "Breen's Water"
ITEM.model = "models/hls/alyxports/popcan01a_hls.mdl"
ITEM.description = "itemWaterDesc"
ITEM.classes = nil
ITEM.thirst = 15
ITEM.price = 15
ITEM.empty = "water_empty"
ITEM.sound = "interface/inv_drink_can2.ogg"
ITEM.isDrink = true

ITEM:Hook("Eat", function(item)
	local client = item.player
	local char = client:GetCharacter()
	
	-- Get the base attribute (excluding other boosts)
	local baseStm = char:GetAttrib("stm", 0)
	
	-- Apply a 10% reduction as a temporary debuff
	char:AddBoost("water", "stm", -baseStm * 0.1)
end)