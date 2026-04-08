RECIPE.name = "Scrap Shield Scanner Part"
RECIPE.description = "recipeScrapShieldScannerPartDesc"
RECIPE.category = "Disassemble"
RECIPE.model = "models/gibs/shield_scanner_gib5.mdl"
RECIPE.requirements = {
	["shield_scanner_gib01"] = {
		amount = 1,
		substitutes = {
			["shield_scanner_gib02"] = 1,
			["shield_scanner_gib03"] = 1,
			["shield_scanner_gib04"] = 1,
			["shield_scanner_gib05"] = 1,
			["shield_scanner_gib06"] = 1
		}
	}
}
RECIPE.results = {
	["comp_combine_steel"] = 2,
    ["comp_aluminium"] = 1,
    ["resin"] = 1,
}
RECIPE.station = "craftingtable"

RECIPE.attribs = {
	["int"] = 5
}
