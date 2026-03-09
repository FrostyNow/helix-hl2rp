
ITEM.name = "Stimulated Protein Mix"
ITEM.model = Model("models/hls/alyxports/ration_box.mdl")
ITEM.skin = 4
ITEM.description = "metropoliceSupplementsDesc"
ITEM.factions = {FACTION_MPF, FACTION_OTA}
ITEM.hunger = 20
ITEM.thirst = 30
ITEM.price = 20
ITEM.heal = 10
ITEM.sound = "interface/inv_eat_ration1.ogg"

ITEM:Hook("Eat", function(item)
	local client = item.player
	local char = client:GetCharacter()

	char:AddBoost("mp_supplements", "strength", 3 )
end)