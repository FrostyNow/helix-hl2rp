
RECIPE.name = "Process Rifle Parts"
RECIPE.description = "recipeGunPartsDesc"
RECIPE.category = "Weapons"
RECIPE.model = "models/willardnetworks/skills/weaponparts.mdl"
RECIPE.station = {"craftingtable", "workbench"}
RECIPE.requirements = {
	["comp_steel"] = {amount = 8, substitutes = {["scrap_combine_steel"] = 4}},
	["resin"] = 15,
}
RECIPE.results = {
	["misc_gunparts_rifle"] = 1,
}