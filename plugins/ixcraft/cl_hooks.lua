
local PLUGIN = PLUGIN

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

local function ParseSubstitute(entry, parentPreserve)
	if (isnumber(entry)) then
		return {amount = entry, preserve = parentPreserve}
	elseif (istable(entry)) then
		return {
			amount = entry.amount or 1,
			preserve = entry.preserve != nil and entry.preserve or parentPreserve
		}
	end

	return {amount = 1, preserve = parentPreserve}
end

local function GetItemName(uniqueID)
	local itemTable = ix.item.Get(uniqueID)

	return itemTable and L(itemTable.name) or uniqueID
end

local function BuildRequirementText(uniqueID, entry)
	local req = ParseRequirement(entry)
	local text = req.amount .. "x " .. GetItemName(uniqueID)

	if (req.substitutes) then
		local substitutes = {}

		for subID, subEntry in SortedPairs(req.substitutes) do
			local sub = ParseSubstitute(subEntry, req.preserve)
			substitutes[#substitutes + 1] = sub.amount .. "x " .. GetItemName(subID)
		end

		if (#substitutes > 0) then
			text = text .. " (" .. L("CraftOr") .. ": " .. table.concat(substitutes, ", ") .. ")"
		end
	end

	return text, req
end

local function AddListRow(tooltip, id, entries)
	if (#entries == 0) then
		return
	end

	local row = tooltip:AddRow(id)
	row:SetText("- " .. table.concat(entries, ", "))
	row:SizeToContents()
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
		local stationName = recipe:GetStationName(LocalPlayer()) or recipe.station

		stationRow:SetText(L("CraftStation") .. ": " .. stationName)
		stationRow:SetBackgroundColor(Color(100, 50, 150))
		stationRow:SizeToContents()
	end

	local toolEntries = {}

	if (recipe.tools) then
		for _, uniqueID in ipairs(recipe.tools) do
			toolEntries[#toolEntries + 1] = "1x " .. GetItemName(uniqueID)
		end
	end

	local requirementEntries = {}

	for uniqueID, entry in SortedPairs(recipe.requirements or {}) do
		local text, req = BuildRequirementText(uniqueID, entry)

		if (req.preserve) then
			toolEntries[#toolEntries + 1] = text
		else
			requirementEntries[#requirementEntries + 1] = text
		end
	end

	if (#toolEntries > 0) then
		local tools = tooltip:AddRow("tools")
		tools:SetText(L("CraftTools"))
		tools:SetBackgroundColor(Color(150,150,25))
		tools:SizeToContents()
		AddListRow(tooltip, "toolList", toolEntries)
	end

	local attributeEntries = {}

	for attribID, value in pairs(recipe.attribs or {}) do
		local attribName = attribID

		if (ix.attributes and ix.attributes.list[attribID]) then
			attribName = L(ix.attributes.list[attribID].name)
		end

		attributeEntries[#attributeEntries + 1] = attribName .. " " .. value
	end

	if (#attributeEntries > 0) then
		local attributes = tooltip:AddRow("attributes")
		attributes:SetText(L("Attributes"))
		attributes:SetBackgroundColor(Color(150, 50, 50))
		attributes:SizeToContents()
		AddListRow(tooltip, "attributeList", attributeEntries)
	end

	if (#requirementEntries > 0) then
		local requirements = tooltip:AddRow("requirements")
		requirements:SetText(L("CraftRequirements"))
		requirements:SetBackgroundColor(Color(25,150,150))
		requirements:SizeToContents()
		AddListRow(tooltip, "ingredientList", requirementEntries)
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
	useHint:SetBackgroundColor(Color(85, 127, 242, 50))
	useHint:SizeToContents()

	if (station.PopulateTooltip) then
		station:PopulateTooltip(tooltip)
	end
end
