RECIPE.name = "Scrap Empty Bottle"
RECIPE.description = "recipeScrapEmptyBottleDesc"
RECIPE.category = "Disassemble"
RECIPE.model = "models/props_junk/GlassBottle01a.mdl"
RECIPE.requirements = {
	["glass_bottle_generic"] = {amount = 1, substitutes = {["coke_bottle_empty"] = 1, ["bottle_shard"] = 1}},
}
RECIPE.results = {
	["comp_glass"] = 1
}