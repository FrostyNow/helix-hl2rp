CLASS.name = "First Class Citizen"
CLASS.faction = FACTION_CITIZEN
CLASS.color = Color(191, 57, 75, 255)

function CLASS:CanSwitchTo(client)
	return false
end

CLASS_ELITE_CITIZEN = CLASS.index