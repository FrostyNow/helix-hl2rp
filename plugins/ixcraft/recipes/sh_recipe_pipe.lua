
RECIPE.name = "Pipe"
RECIPE.description = "recipePipeDesc"
RECIPE.category = "Weapon"
RECIPE.model = "models/props_canal/mattpipe.mdl"
RECIPE.requirements = {
	["steel"] = 2,
	["ducttape"] = 1,
}
RECIPE.results = {
	["pipe"] = 1
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			return true
		end
	end

	return false, "@noWorkbench"
end)
