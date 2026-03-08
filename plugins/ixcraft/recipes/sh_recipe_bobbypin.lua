
RECIPE.name = "Bobby Pin Box"
RECIPE.description = "recipeBobbyPinDesc"
RECIPE.category = "Assembly"
RECIPE.model = "models/mosi/fallout4/props/junk/bobbypinbox.mdl"
RECIPE.requirements = {
	["steel"] = 1,
	["gears"] = 1,
}
RECIPE.results = {
	["bobbypin"] = 1
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			return true
		end
	end

	return false, "@noWorkbench"
end)
