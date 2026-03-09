
RECIPE.name = "Bottle Shard"
RECIPE.description = "recipeBottleShardDesc"
RECIPE.category = "Weapon"
RECIPE.model = "models/weapons/hl2meleepack/w_brokenbottle.mdl"
RECIPE.requirements = {
	["glass_bottle_generic"] = 1,
}
RECIPE.results = {
	["bottle_shard"] = 1
}

RECIPE:PostHook("OnCanCraft", function(recipeTable, client)
	for _, v in pairs(ents.FindByClass("ix_station_workbench")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100 * 100) then
			return true
		end
	end

	return false, "@noWorkbench"
end)
