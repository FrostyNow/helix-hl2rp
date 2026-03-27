RECIPE.name = "Tanning Hide"
RECIPE.description = "recipeTanningHideDesc"
RECIPE.category = "Transform"
RECIPE.model = "models/mosi/fallout4/props/junk/components/leather.mdl"
RECIPE.station = "craftingtable"
RECIPE.requirements = {
	["hide"] = 1,
	["misc_dried_tea"] = 1,
	["water_purified"] = {amount = 1, substitutes = {["water_purified_bottle"] = 1, ["water"] = 1, ["mineral_water"] = 1}},
	["bucket"] = {amount = 1, preserve = true}
}
RECIPE.results = {
	["comp_leather"] = 2
}

RECIPE.attribs = {
	["int"] = 2
}