
RECIPE.name = "Purified Water"
RECIPE.description = "recipePurifiedWaterDesc"
RECIPE.category = "Food"
RECIPE.model = "models/props_junk/PopCan01a.mdl"
RECIPE.requirements = {
	["water_dirty"] = 1,
	["comp_cloth"] = 1,
	["misc_charcoal"] = 1,
	["coffeepot"] = {amount = 1, preserve = true, substitutes = {["pressurecooker"] = 1}}
}
RECIPE.results = {
	["purified_water"] = 1
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