
RECIPE.name = "Process SMG Parts"
RECIPE.description = "recipeGunPartsDesc"
RECIPE.category = "Weapons"
RECIPE.model = "models/willardnetworks/skills/weaponparts.mdl"
RECIPE.station = {"craftingtable", "workbench"}
RECIPE.requirements = {
	["comp_steel"] = {amount = 5, substitutes = {["comp_combine_steel"] = 2}},
	["resin"] = 10,
}
RECIPE.results = {
	["misc_gunparts_smg"] = 1,
}

RECIPE.attribs = {
	["int"] = 4
}