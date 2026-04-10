
RECIPE.name = "Decant Water"
RECIPE.description = "recipeDecantWaterLargeDesc"
RECIPE.category = "Refill"
RECIPE.model = "models/props/water_bottle/water_bottle.mdl"
RECIPE.requirements = {
	["misc_plasticbottle"] = 1,
	["water_large"] = {amount = 1, preserve = true}
}
RECIPE.results = {
	["water_purified_bottle"] = 1
}

RECIPE:PreHook("OnCanCraft", function(self, client)
	local character = client:GetCharacter()
	local inventory = character:GetInventory()
	local items = inventory:GetItems()
	local bFound = false

	for _, v in pairs(items) do
		if (v.uniqueID == "water_large") then
			local usenum = v:GetData("usenum", v.usenum or 1)
			if (usenum > 0) then
				bFound = true
				break
			end
		end
	end

	if (!bFound) then
		return false, "@CraftMissingItem", L("Large Bottle of Water (Empty)", client)
	end
end)

RECIPE:PreHook("OnCraft", function(self, client)
	local character = client:GetCharacter()
	local inventory = character:GetInventory()
	local items = inventory:GetItems()
	local waterItem = nil

	for _, v in pairs(items) do
		if (v.uniqueID == "water_large") then
			local usenum = v:GetData("usenum", v.usenum or 1)
			if (usenum > 0) then
				waterItem = v
				break
			end
		end
	end

	if (waterItem) then
		local usenum = waterItem:GetData("usenum", waterItem.usenum or 1)
		usenum = usenum - 1

		if (usenum <= 0) then
			local emptyID = waterItem.empty or "water_large_empty"
			waterItem:Remove()
			
			if (!inventory:Add(emptyID)) then
				ix.item.Spawn(emptyID, client)
			end
		else
			waterItem:SetData("usenum", usenum)
		end
	end

	return nil -- Continue to default logic
end)
