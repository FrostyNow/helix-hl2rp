CLASS.name = "Overwatch Shotgunner"
CLASS.faction = FACTION_OTA
CLASS.isDefault = false

function CLASS:CanSwitchTo(client)
	return Schema:GetCombineRank(client:Name()) == "SGS"
end

CLASS_SGS = CLASS.index
