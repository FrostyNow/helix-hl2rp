
RECIPE.name = "Purified Water"
RECIPE.description = "recipePurifiedWaterFilterDesc"
RECIPE.category = "Food"
RECIPE.model = "models/synapse/alyxports/water_bottle_04_lid.mdl"
RECIPE.requirements = {
	["water_dirty"] = {amount = 1, substitutes = {["water_dirty_bottle"] = 1, ["water_dirty_can"] = 1, ["water"] = 1}},
	["gasmask_filter"] = {amount = 1, preserve = true, substitutes = {["overwatch_gasmask_filter"] = 1}},
	["misc_plasticbottle"] = {amount = 1, substitutes = {["coke_bottle_empty"] = 1, ["glass_bottle_generic"] = 1}}
}
RECIPE.results = {
	["water_purified_bottle"] = 1
}

RECIPE.attribs = {
	["int"] = 2
}

RECIPE:PreHook("OnCanCraft", function(self, client)
	local character = client:GetCharacter()
	local inventory = character:GetInventory()
	local items = inventory:GetItems()
	local bFound = false

	for _, item in pairs(items) do
		if (item.uniqueID == "gasmask_filter" or item.uniqueID == "overwatch_gasmask_filter") then
			local durability = item:GetData("Durability", item.maxDurability or 100)
			if (durability > 50) then
				bFound = true
				break
			end
		end
	end

	if (!bFound) then
		return false, "@recipePurifiedWaterFilterLowDurability"
	end
end)

RECIPE:PreHook("OnCraft", function(self, client)
	local character = client:GetCharacter()
	local inventory = character:GetInventory()
	local items = inventory:GetItems()
	local bestFilter
	local minDurability = 999

	for _, item in pairs(items) do
		if (item.uniqueID == "gasmask_filter" or item.uniqueID == "overwatch_gasmask_filter") then
			local durability = item:GetData("Durability", item.maxDurability or 100)
			if (durability > 50 and durability < minDurability) then
				minDurability = durability
				bestFilter = item
			end
		end
	end

	if (bestFilter) then
		local newDurability = minDurability - 50
		if (newDurability <= 0) then
			bestFilter:Remove()
		else
			bestFilter:SetData("Durability", newDurability)
		end
	end
end)