RECIPE.name = "빈 병 분해"
RECIPE.description = "병을 잘라내거나 성형하여 적절한 형태로 가공합니다."
RECIPE.category = "Disassemble"
RECIPE.model = "models/props_junk/GlassBottle01a.mdl"
RECIPE.requirements = {
	["glass_bottle_generic"] = {amount = 1, substitutes = {["coke_bottle_empty"] = 1, ["bottle_shard"] = 1}},
}
RECIPE.results = {
	["comp_glass"] = 1
}