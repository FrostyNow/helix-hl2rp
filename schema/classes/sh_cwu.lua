CLASS.name = "Civil Worker's Union"
CLASS.faction = FACTION_CITIZEN
CLASS.color = Color(224, 208, 117, 255)

function CLASS:CanSwitchTo(client)
	return false
end

CLASS_CWU = CLASS.index