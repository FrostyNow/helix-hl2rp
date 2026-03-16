CLASS.name = "Overwatch Soldier"
CLASS.faction = FACTION_OTA
CLASS.isDefault = true

function CLASS:CanSwitchTo(client)
	return Schema:GetCombineRank(client:Name()) == "OWS"
end

CLASS_OWS = CLASS.index
