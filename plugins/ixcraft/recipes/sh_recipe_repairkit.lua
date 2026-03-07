
RECIPE.name = "Basic Repair Kit"
RECIPE.description = "recipeRepairKitDesc"
RECIPE.category = "Consumable"
RECIPE.model = "models/props_junk/cardboard_box004a.mdl"
RECIPE.requirements = {
	["screw"] = 2,
	["oil"] = 1,
}
RECIPE.tools = {"screwdriver"}
RECIPE.results = {
	["repair_tools"] = 1
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			return true
		end
	end

	return false, "@noWorkbench"
end)
