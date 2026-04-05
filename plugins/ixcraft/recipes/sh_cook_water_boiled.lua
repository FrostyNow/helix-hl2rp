RECIPE.name = "Boil Water"
RECIPE.description = "recipeBoilWaterDesc"
RECIPE.category = "Food"
RECIPE.model = "models/synapse/alyxports/water_bottle_04_lid.mdl"
RECIPE.requirements = {
	["water_dirty"] = {amount = 1, substitutes = {["water_dirty_can"] = 1, ["water_dirty_bottle"] = 1, ["water"] = 1}},
	["pot"] = {amount = 1, preserve = true, substitutes = {["misc_tool_pressurecooker"] = 1, ["pan"] = 1}}
}
RECIPE.results = {
	["water_boiled"] = 1
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
