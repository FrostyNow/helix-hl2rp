
RECIPE.name = "Process Pistol Parts"
RECIPE.description = "recipeGunPartsDesc"
RECIPE.category = "Weapons"
RECIPE.model = "models/willardnetworks/skills/weaponparts.mdl"
RECIPE.station = {"craftingtable", "workbench"}
RECIPE.requirements = {
	["comp_steel"] = {amount = 2, substitutes = {["comp_combine_steel"] = 1}},
	["resin"] = 5,
}
RECIPE.results = {
	["misc_gunparts_pistol"] = 1,
}