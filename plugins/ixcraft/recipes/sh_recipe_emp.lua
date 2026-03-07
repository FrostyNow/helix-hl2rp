
RECIPE.name = "EMP Tool"
RECIPE.description = "recipeEMPDesc"
RECIPE.category = "Assembly"
RECIPE.model = "models/alyx_emptool_prop.mdl"
RECIPE.requirements = {
	["circuitery"] = 2,
	["copper"] = 2,
	["battery"] = 1,
}
RECIPE.results = {
	["emp"] = 1
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			return true
		end
	end

	return false, "@noWorkbench"
end)
