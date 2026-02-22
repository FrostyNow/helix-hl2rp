CLASS.name = "Resistance"
CLASS.faction = FACTION_CITIZEN
-- CLASS.color = Color(243, 123, 33, 255)

function CLASS:CanSwitchTo(client)
	return false
end

CLASS_REBEL = CLASS.index