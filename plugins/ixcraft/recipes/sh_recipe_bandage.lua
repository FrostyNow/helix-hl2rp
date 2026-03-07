
RECIPE.name = "Bandage"
RECIPE.description = "recipeBandageDesc"
RECIPE.category = "Consumable"
RECIPE.model = "models/props_lab/box01a.mdl"
RECIPE.requirements = {
	["antiseptic"] = 1,
	["cloth"] = 1,
}
RECIPE.results = {
	["bandage"] = 1
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			return true
		end
	end

	return false, "@noWorkbench"
end)
