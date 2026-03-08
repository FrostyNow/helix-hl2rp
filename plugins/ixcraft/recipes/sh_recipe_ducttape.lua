
RECIPE.name = "Duct Tape"
RECIPE.description = "recipeDuctTapeDesc"
RECIPE.category = "Assembly"
RECIPE.model = "models/props_junk/PopCan01a.mdl"
RECIPE.requirements = {
	["cloth"] = 1,
	["plastic"] = 2,
	["glue"] = 1,
}
RECIPE.results = {
	["ducttape"] = 1
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			return true
		end
	end

	return false, "@noWorkbench"
end)
