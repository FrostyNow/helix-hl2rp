
ITEM.name = "Synthetized anti-fatigue bar"
ITEM.model = Model("models/hls/alyxports/ration_bar.mdl")
ITEM.skin = 4
ITEM.description = "metropoliceRationbarDesc"
ITEM.factions = {FACTION_MPF, FACTION_OTA}
ITEM.hunger = 30
ITEM.price = 20
ITEM.heal = 10
ITEM.sound = "interface/inv_eat_paperwrap.ogg"

ITEM:Hook("Eat", function(item)
	local client = item.player
	local char = client:GetCharacter()
    
	char:AddBoost("mp_rationbar", "endurance", 3 )
end)