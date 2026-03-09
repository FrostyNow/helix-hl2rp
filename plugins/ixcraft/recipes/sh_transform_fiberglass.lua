
RECIPE.name = "Fiberglass"
RECIPE.description = "recipeFiberglassDesc"
RECIPE.category = "Transform"
RECIPE.model = "models/mosi/fallout4/props/junk/components/fiberglass.mdl"
RECIPE.station = "craftingtable"
RECIPE.requirements = {
	["comp_glass"] = 1
}
RECIPE.results = {
	["comp_fiberglass"] = 1,
}

RECIPE:PostHook("OnCanSee", function(recipeTable, client)
	local character = client:GetCharacter()
	local attributes = character:GetAttributes()

	if (attributes["int"] and attributes["int"] >= 5.5) then 
		return true 
	end

	return false
end)