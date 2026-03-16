CLASS.name = "Elite Overwatch Soldier"
CLASS.faction = FACTION_OTA
CLASS.isDefault = false

function CLASS:CanSwitchTo(client)
	return Schema:GetCombineRank(client:Name()) == "EOW"
end

CLASS_EOW = CLASS.index
