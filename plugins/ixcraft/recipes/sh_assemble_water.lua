
RECIPE.name = "Breen's Water"
RECIPE.description = "recipeWaterDesc"
RECIPE.category = "Assembly"
RECIPE.model = "models/props_junk/PopCan01a.mdl"
RECIPE.requirements = {
	["water_empty"] = 1,
	["water_drug"] = 1,
	["water_purified"] = {amount = 1, substitutes = {["water_purified_bottle"] = 1, ["water"] = 1, ["mineralwater"] = 1}},
}
RECIPE.results = {
	["water"] = 1
}
RECIPE.station = "workbench"