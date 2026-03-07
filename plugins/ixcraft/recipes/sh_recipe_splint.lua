
RECIPE.name = "Improvised Splint"
RECIPE.description = "recipeSplintDesc"
RECIPE.category = "Consumable"
RECIPE.model = "models/props_c17/furnituredrawer001a_shard01.mdl"
RECIPE.requirements = {
	["wood"] = 1,
	["cloth"] = 2,
}
RECIPE.results = {
	["splint"] = 1
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			return true
		end
	end

	return false, "@noWorkbench"
end)
