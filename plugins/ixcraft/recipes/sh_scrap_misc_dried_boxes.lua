RECIPE.name = "건조 첨가물 분해"
RECIPE.description = "포장재인 금속통을 분해합니다."
RECIPE.category = "Disassemble"
RECIPE.model = "models/synapse/misc_props/synapse_misc_large_metal_box.mdl"
RECIPE.requirements = {
	["misc_dried_spices"] = {amount = 1, substitutes = {["misc_dried_tea"] = 1, ["misc_dried_vegetable"] = 1, ["misc_dried_eggprotein"] = 1}}
}
RECIPE.results = {
	["comp_aluminium"] = 1
}