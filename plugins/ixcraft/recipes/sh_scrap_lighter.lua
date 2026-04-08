RECIPE.name = "Scrap Lighter"
RECIPE.description = "recipeScrapLighterDesc"
RECIPE.category = "Disassemble"
RECIPE.model = "models/hls/alyxports/tabletop_lighter.mdl"
RECIPE.requirements = {
	["lighter"] = 1
}
RECIPE.results = {
	["comp_plastic"] = 1
}

RECIPE:PreHook("OnCanCraft", function(recipe, client)
	local character = client:GetCharacter()
	local inventory = character:GetInventory()
	local items = inventory:GetItemsByUniqueID("lighter")
	local hasEmpty = false

	for _, item in pairs(items) do
		if (item:GetData("uses", item.usenum or 10) <= 0) then
			hasEmpty = true
			break
		end
	end

	if (!hasEmpty) then
		return false, "@lighterNotEmpty"
	end
end)

RECIPE:PreHook("OnCraft", function(recipe, client)
	local character = client:GetCharacter()
	local inventory = character:GetInventory()
	local items = inventory:GetItemsByUniqueID("lighter")
	local target

	for _, item in pairs(items) do
		if (item:GetData("uses", item.usenum or 10) <= 0) then
			target = item
			break
		end
	end

	if (target) then
		target:Remove()

		for uniqueID, amount in pairs(recipe.results or {}) do
			for i = 1, amount do
				if (!inventory:Add(uniqueID)) then
					ix.item.Spawn(uniqueID, client)
				end
			end
		end

		return true, "@CraftSuccess", (CLIENT and L(recipe.name) or L(recipe.name, client))
	end

	return false, "@lighterNotEmpty"
end)
