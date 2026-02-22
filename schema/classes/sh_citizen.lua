CLASS.name = "Second Class Citizen"
CLASS.faction = FACTION_CITIZEN
CLASS.isDefault = true
CLASS_CITIZEN = CLASS.index

function CLASS:CanSwitchTo(client)
	if client:GetCharacter():GetClass() != CLASS_CITIZEN then
		return false
	end
end