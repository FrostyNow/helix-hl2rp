RECIPE.name = "Scrap Empty Carton"
RECIPE.description = "recipeEmptyCartonDesc"
RECIPE.category = "Disassemble"
RECIPE.model = "models/props_junk/milk_carton001a.mdl"
RECIPE.requirements = {
	["empty_milk_carton"] = {amount = 1, substitutes = {["empty_milk_carton_generic"] = 1}},
}
RECIPE.results = {
	["paper"] = 1
}