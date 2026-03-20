RECIPE.name = "Scrap Gasmask Filter"
RECIPE.description = "recipeScrapGasmaskFilterDesc"
RECIPE.category = "Disassemble"
RECIPE.model = "models/willardnetworks/props/blackfilter.mdl"
RECIPE.requirements = {
	["gasmask_filter"] = 1,
	["misc_tool_screwdriver"] = {amount = 1, preserve = true},
}
RECIPE.results = {
	["comp_plastic"] = 1,
	["comp_steel"] = 1
}
RECIPE.station = "craftingtable"

RECIPE.attribs = {
	["int"] = 2
}