
RECIPE.name = "Purified Water"
RECIPE.description = "recipePurifiedWaterFilterDesc"
RECIPE.category = "Food"
RECIPE.model = "models/synapse/alyxports/water_bottle_04_lid.mdl"
RECIPE.requirements = {
	["water_dirty"] = {amount = 1, substitutes = {["water_dirty_bottle"] = 1, ["water_dirty_can"] = 1, ["water"] = 1}},
	["gasmask_filter"] = 1,
	["misc_plasticbottle"] = {amount = 1, substitutes = {["coke_bottle_empty"] = 1, ["glass_bottle_generic"] = 1}}
}
RECIPE.results = {
	["water_purified_bottle"] = 1
}

RECIPE.attribs = {
	["int"] = 2
}