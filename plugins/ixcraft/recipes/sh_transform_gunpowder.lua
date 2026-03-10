
RECIPE.name = "Gunpowder"
RECIPE.description = "recipeGunpowderDesc"
RECIPE.category = "Transform"
RECIPE.model = "models/mosi/fallout4/props/junk/components/asbestos.mdl"
RECIPE.station = "craftingtable"
RECIPE.requirements = {
	["comp_fertilizer"] = 1,
	["misc_charcoal"] = 2,
}
RECIPE.results = {
	["misc_gunpowder"] = 1,
}

RECIPE:PostHook("OnCanSee", function(recipeTable, client)
	local character = client:GetCharacter()
	local attributes = character:GetAttributes()

	if (attributes["int"] and attributes["int"] >= 2) then 
		return true 
	end

	return false
end)