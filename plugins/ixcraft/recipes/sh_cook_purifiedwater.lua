
RECIPE.name = "Purified Water"
RECIPE.description = "recipePurifiedWaterDesc"
RECIPE.category = "Food"
RECIPE.model = "models/synapse/alyxports/water_bottle_04_lid.mdl"
RECIPE.requirements = {
	["water_dirty"] = {amount = 1, substitutes = {["water_dirty_bottle"] = 1, ["water_dirty_can"] = 1, ["water"] = 1}},
	["comp_cloth"] = {amount = 1, substitutes = {["paper"] = 1}},
	["misc_charcoal"] = 1,
	["misc_plasticbottle"] = {amount = 1, substitutes = {["coke_bottle_empty"] = 1, ["misc_plasticbottle"] = 1, ["glass_bottle_generic"] = 1}},
	["pot"] = {amount = 1, preserve = true, substitutes = {["misc_tool_pressurecooker"] = 1, ["misc_tool_coffeepot"] = 1}}
}
RECIPE.results = {
	["water_purified_bottle"] = 1
}

local stoves = {"ix_bucket", "ix_bonfire", "ix_stove"}

RECIPE:PostHook("OnCanSee", function(recipeTable, client)
	for _, class in ipairs(stoves) do
		for _, v in ipairs(ents.FindByClass(class)) do
			if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
				return true
			end
		end
	end

	return false
end)

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	for _, class in ipairs(stoves) do
		for _, v in ipairs(ents.FindByClass(class)) do
			if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
				return v:GetNetVar("active", false), "@turnOnStove"
			end
		end
	end
end)