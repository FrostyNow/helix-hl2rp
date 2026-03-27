
RECIPE.name = "Screwdriver"
RECIPE.description = "recipeScrewdriverDesc"
RECIPE.category = "Crafting"
RECIPE.model = "models/synapse/alyxports/screwdriver_1.mdl"
RECIPE.station = "craftingtable"
RECIPE.requirements = {
	["comp_plastic"] = 2,
	["comp_aluminium"] = 1,
	["misc_glue"] = {amount = 1, substitutes = {["comp_adhesive"] = 1}},
}
RECIPE.results = {
	["misc_tool_screwdriver"] = 1,
}