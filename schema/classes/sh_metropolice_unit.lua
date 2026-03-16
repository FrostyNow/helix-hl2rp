CLASS.name = "Metropolice Unit"
CLASS.faction = FACTION_MPF

function CLASS:CanSwitchTo(client)
	return Schema:GetCombineClassFromRank("MPF", Schema:GetCombineRank(client:Name())) == CLASS_MPU
end

CLASS_MPU = CLASS.index
