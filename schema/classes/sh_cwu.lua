CLASS.name = "Civil Worker's Union"
CLASS.faction = FACTION_CITIZEN
CLASS.color = Color(144, 143, 83, 255)

function CLASS:CanSwitchTo(client)
	return false
end

CLASS_CWU = CLASS.index