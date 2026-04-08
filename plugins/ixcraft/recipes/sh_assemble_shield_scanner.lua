RECIPE.name = "Combine Shield Scanner"
RECIPE.description = "recipeShieldScannerDesc"
RECIPE.category = "Assembly"
RECIPE.model = "models/shield_scanner.mdl"
RECIPE.requirements = {
	["shield_scanner_gib01"] = 1,
	["shield_scanner_gib02"] = 1,
	["shield_scanner_gib03"] = 1,
	["shield_scanner_gib04"] = 1,
	["shield_scanner_gib05"] = 1,
	["shield_scanner_gib06"] = 1,
	["battery"] = 1,
	["comp_circuitry"] = 2,
	["resin"] = 2,
}
RECIPE.results = {
	["scanner_claw"] = 1
}
RECIPE.station = "workbench"

RECIPE.attribs = {
	["int"] = 7
}
