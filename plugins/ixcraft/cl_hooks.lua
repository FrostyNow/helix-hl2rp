
local PLUGIN = PLUGIN

--- Helper to parse a requirement entry for display
local function ParseRequirement(entry)
	if (isnumber(entry)) then
		return {amount = entry, preserve = false, substitutes = nil}
	elseif (istable(entry)) then
		return {
			amount = entry.amount or 1,
			preserve = entry.preserve or false,
			substitutes = entry.substitutes or nil
		}
	end

	return {amount = 1, preserve = false, substitutes = nil}
end

function PLUGIN:BuildCraftingMenu()
	if (table.IsEmpty(self.craft.GetCategories(LocalPlayer()))) then
		return false
	end
end

function PLUGIN:PopulateRecipeTooltip(tooltip, recipe)
	local canCraft, failString, c, d, e, f = recipe:OnCanCraft(LocalPlayer())

	local name = tooltip:AddRow("name")
	name:SetImportant()
	name:SetText(L(recipe.category)..": "..L(recipe.GetName and recipe:GetName() or recipe.name))
	name:SetMaxWidth(math.max(name:GetMaxWidth(), ScrW() * 0.5))
	name:SizeToContents()

	if (!canCraft) then
		if (failString:sub(1, 1) == "@") then
			failString = L(failString:sub(2), c, d, e, f)
		end

		local errorRow = tooltip:AddRow("errorRow")
		errorRow:SetText(failString)
		errorRow:SetBackgroundColor(Color(255,24,0))
		errorRow:SizeToContents()
	end

	local description = tooltip:AddRow("description")
	description:SetText(L(recipe.GetDescription and recipe:GetDescription() or recipe.description))
	description:SizeToContents()

	-- Station requirement
	if (recipe.station) then
		local stationRow = tooltip:AddRow("station")
		local stationTable = PLUGIN.craft.stations[recipe.station]
		local stationName = stationTable and L(stationTable.name or recipe.station) or recipe.station

		stationRow:SetText(L("CraftStation") .. ": " .. stationName)
		stationRow:SetBackgroundColor(Color(100, 50, 150))
		stationRow:SizeToContents()
	end

	-- Tools (legacy)
	if (recipe.tools) then
		local tools = tooltip:AddRow("tools")
		tools:SetText(L("CraftTools"))
		tools:SetBackgroundColor(Color(150,150,25))
		tools:SizeToContents()

		local toolString = ""

		for _, v in pairs(recipe.tools) do
			local itemTable = ix.item.Get(v)
			local itemName = v

			if (itemTable) then
			    itemName = L(itemTable.name)
			end

			toolString = toolString..itemName..", "
		end

		if (toolString != "") then
			local tools = tooltip:AddRow("toolList")
			tools:SetText("- "..string.sub(toolString, 0, #toolString-2))
			tools:SizeToContents()
		end
	end

	-- Requirements
	local requirements = tooltip:AddRow("requirements")
	requirements:SetText(L("CraftRequirements"))
	requirements:SetBackgroundColor(Color(25,150,150))
	requirements:SizeToContents()

	local requirementString = ""

	for k, v in pairs(recipe.requirements or {}) do
		local req = ParseRequirement(v)
		local itemTable = ix.item.Get(k)
		local itemName = k

		if (itemTable) then
		    itemName = L(itemTable.name)
		end

		local prefix = ""
		if (req.preserve) then
			prefix = "🔒 "
		end

		requirementString = requirementString .. prefix .. req.amount .. "x " .. itemName

		-- Show substitutes
		if (req.substitutes) then
			local subNames = {}
			for subID, _ in pairs(req.substitutes) do
				local subItem = ix.item.Get(subID)
				local subName = subItem and L(subItem.name) or subID
				table.insert(subNames, subName)
			end

			if (#subNames > 0) then
				requirementString = requirementString .. " (" .. L("CraftOr") .. ": " .. table.concat(subNames, ", ") .. ")"
			end
		end

		requirementString = requirementString .. ", "
	end

	if (requirementString != "") then
		local requirement = tooltip:AddRow("ingredientList")
		requirement:SetText("- "..string.sub(requirementString, 0, #requirementString-2))
		requirement:SizeToContents()
	end

	-- Results
	local result = tooltip:AddRow("result")
	result:SetText(L("CraftResults"))
	result:SetBackgroundColor(derma.GetColor("Warning", tooltip))
	result:SizeToContents()

	local resultString = ""

	for k, v in pairs(recipe.results or {}) do
		local itemTable = ix.item.Get(k)
		local itemName = k
		local amount = v

		if (itemTable) then
		    itemName = L(itemTable.name)
		end

		if (istable(v)) then
			if (v["min"] and v["max"]) then
				amount = v["min"].."-"..v["max"]
			else
				amount = v[1].."-"..v[#v]
			end
		end

		resultString = resultString..amount.."x "..itemName..", "
	end

	if (resultString != "") then
		local result = tooltip:AddRow("resultList")
		result:SetText("- "..string.sub(resultString, 0, #resultString-2))
		result:SizeToContents()
	end

	if (recipe.PopulateTooltip) then
		recipe:PopulateTooltip(tooltip)
	end
end

function PLUGIN:PopulateStationTooltip(tooltip, station)
	local name = tooltip:AddRow("name")
	name:SetImportant()
	name:SetText(L(station.GetName and station:GetName() or station.name))
	name:SetMaxWidth(math.max(name:GetMaxWidth(), ScrW() * 0.5))
	name:SizeToContents()

	local description = tooltip:AddRow("description")
	description:SetText(L(station.GetDescription and station:GetDescription() or station.description))
	description:SizeToContents()

	-- Show "Press E to use" hint
	local useHint = tooltip:AddRow("useHint")
	useHint:SetText(L("StationUseHint"))
	useHint:SetTextColor(Color(150, 200, 150))
	useHint:SizeToContents()

	if (station.PopulateTooltip) then
		station:PopulateTooltip(tooltip)
	end
end
