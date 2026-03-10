
RECIPE.name = "Gunpowder"
RECIPE.description = "질산 비료와 숯을 혼합하여 화약을 만듭니다."
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