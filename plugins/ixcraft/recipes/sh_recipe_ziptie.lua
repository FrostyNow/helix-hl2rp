
RECIPE.name = "Zip Tie"
RECIPE.description = "recipeZipTieDesc"
RECIPE.category = "Assembly"
RECIPE.model = "models/items/crossbowrounds.mdl"
RECIPE.requirements = {
	["plastic"] = 2,
	["rubber"] = 1,
}
RECIPE.results = {
	["zip_tie"] = 1
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			return true
		end
	end

	return false, "@noWorkbench"
end)
