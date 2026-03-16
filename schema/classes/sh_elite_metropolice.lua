CLASS.name = "Elite Metropolice"
CLASS.faction = FACTION_MPF
CLASS.isDefault = false

function CLASS:CanSwitchTo(client)
	return Schema:GetCombineClassFromRank("MPF", Schema:GetCombineRank(client:Name())) == CLASS_EMP
end

CLASS_EMP = CLASS.index
