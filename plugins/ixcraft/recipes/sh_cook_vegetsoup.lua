RECIPE.name = "Vegetable Soup"
RECIPE.description = "recipeVegetSoupDesc"
RECIPE.category = "Food"
RECIPE.model = "models/mosi/fallout4/props/food/vegetablesoup.mdl"
RECIPE.requirements = {
	["cabbage"] = {amount = 1, substitutes = {["carrot"] = 1, ["onion"] = 1, ["corn"] = 1, ["tomato"] = 1, ["misc_dried_vegetable"] = 1}},
	["water_purified"] = {amount = 1, substitutes = {["water_purified_bottle"] = 1, ["water"] = 1, ["mineral_water"] = 1}},
	["pot"] = {amount = 1, preserve = true, substitutes = {["misc_tool_pressurecooker"] = 1, ["pan"] = 1}}
}
RECIPE.results = {
	["veget_soup"] = 1
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

RECIPE:PreHook("OnCraft", function(recipeTable, client)
	recipeTable.OldcraftResults = table.Copy(recipeTable.results)
	recipeTable.results = {}
end)

RECIPE:PostHook("OnCraft", function(recipeTable, client)
	recipeTable.results = recipeTable.OldcraftResults
	if (!recipeTable.results) then return end

	local character = client:GetCharacter()
	local inventory = character:GetInventory()
	local cookingSkill = character:GetAttribute("cooking", 0)
	local luck = character:GetAttribute("lck", 0)
	local maxAttrib = ix.config.Get("maxAttributes", 10)
	local weightedSkill = (cookingSkill * 0.8 + luck * 0.2) / maxAttrib
	local baseQuality = 3 + weightedSkill * 6
	local consistency = math.Clamp(cookingSkill / maxAttrib, 0, 1)
	local variance = (math.random() * 2 - 1) * (1.2 - consistency * 0.4)
	local f_quality = math.Clamp(math.Round(baseQuality + variance), 1, 9)

	local exp = (1 - (f_quality / 9)) * 0.15
	character:UpdateAttrib("cooking", exp)
	client:NotifyLocalized("notice_cooked", L(recipeTable.name, client))
	client:EmitSound("player/pl_burnpain" .. math.random(1, 3) .. ".wav", 75, 140)

	for uniqueID, amount in pairs(recipeTable.OldcraftResults) do
		for i = 1, amount do
			local bAdded = inventory:Add(uniqueID, 1, {cooklevel = f_quality})
			if (!bAdded) then
				ix.item.Spawn(uniqueID, client, function(item, entity)
					item:SetData("cooklevel", f_quality)
				end)
			end
		end
	end
end)
