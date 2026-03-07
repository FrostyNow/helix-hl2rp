
RECIPE.name = "Flashlight"
RECIPE.description = "recipeFlashlightDesc"
RECIPE.category = "Assembly"
RECIPE.model = "models/hls/alyxports/flashlight.mdl"
RECIPE.requirements = {
	["steel"] = 1,
	["glass"] = 1,
	["battery5v"] = 1,
}
RECIPE.results = {
	["flashlight"] = 1
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			return true
		end
	end

	return false, "@noWorkbench"
end)
