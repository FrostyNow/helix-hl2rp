RECIPE.name = "Scrap Match"
RECIPE.description = "recipeScrapMatchDesc"
RECIPE.category = "Disassemble"
RECIPE.model = "models/hls/alyxports/matchbox_0.mdl"
RECIPE.requirements = {
	["match"] = 1
}
RECIPE.results = {
	["paper"] = 1
}

RECIPE:PreHook("OnCanCraft", function(recipe, client)
	local character = client:GetCharacter()
	local inventory = character:GetInventory()
	local items = inventory:GetItemsByUniqueID("match")
	local hasEmpty = false

	for _, item in pairs(items) do
		if (item:GetData("uses", item.usenum or 10) <= 0) then
			hasEmpty = true
			break
		end
	end

	if (!hasEmpty) then
		return false, "@matchNotEmpty"
	end
end)

RECIPE:PreHook("OnCraft", function(recipe, client)
	local character = client:GetCharacter()
	local inventory = character:GetInventory()
	local items = inventory:GetItemsByUniqueID("match")
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

	return false, "@matchNotEmpty"
end)
