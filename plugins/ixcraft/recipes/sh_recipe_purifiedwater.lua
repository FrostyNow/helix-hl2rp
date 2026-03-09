
RECIPE.name = "Purified Water"
RECIPE.description = "recipePurifiedWaterDesc"
RECIPE.category = "Consumable"
RECIPE.model = "models/props_junk/PopCan01a.mdl"
RECIPE.requirements = {
	["water_dirty"] = 1,
	["cloth"] = 1,
	["misc_charcoal"] = 1,
}
RECIPE.results = {
	["purified_water"] = 1
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			return true
		end
	end

	return false, "@noWorkbench"
end)
