
local PLUGIN = PLUGIN
PLUGIN.meta = PLUGIN.meta or {}

local RECIPE = PLUGIN.meta.recipe or {}
RECIPE.__index = RECIPE
RECIPE.name = "undefined"
RECIPE.description = "undefined"
RECIPE.uniqueID = "undefined"
RECIPE.category = "Crafting"

local cookingStations = {
	"ix_bucket",
	"ix_bonfire",
	"ix_stove"
}

function RECIPE:GetStations()
	if (!self.station) then
		return nil
	end

	if (istable(self.station)) then
		return self.station
	end

	return {self.station}
end

function RECIPE:GetName()
	return self.name
end

function RECIPE:GetDescription()
	return self.description
end

function RECIPE:GetSkin()
	return self.skin
end

function RECIPE:GetModel()
	return self.model
end

function RECIPE:PreHook(name, func)
	if (!self.preHooks) then
		self.preHooks = {}
	end

	self.preHooks[name] = func
end

function RECIPE:PostHook(name, func)
	if (!self.postHooks) then
		self.postHooks = {}
	end

	self.postHooks[name] = func
end

--- Parse a requirement entry into a normalized table
-- Handles both old format (number) and new format (table)
-- @param entry number|table The requirement entry
-- @return table Normalized requirement table {amount, preserve, substitutes}
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

--- Parse a substitute entry into a normalized table
-- @param entry number|table The substitute entry
-- @param parentPreserve bool The parent requirement's preserve value
-- @return table Normalized substitute table {amount, preserve}
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

--- Check how many of an item (or its substitutes) the player has
-- @param inventory The player's inventory
-- @param uniqueID The required item's unique ID
-- @param req The parsed requirement table
-- @return bool Whether the player has enough
-- @return string Missing item names (for error message)
function RECIPE:CheckRequirement(inventory, uniqueID, req, client)
	local needed = req.amount
	local has = inventory:GetItemCount(uniqueID)

	-- Check substitutes
	if (has < needed and req.substitutes) then
		for subID, _ in pairs(req.substitutes) do
			has = has + inventory:GetItemCount(subID)
		end
	end

	if (has >= needed) then
		return true
	end

	local itemTable = ix.item.Get(uniqueID)
	local itemName = itemTable and itemTable.name or uniqueID

	itemName = CLIENT and L(itemName) or L(itemName, client)

	return false, itemName
end

function RECIPE:GetStationName(client)
	local stations = self:GetStations()

	if (!stations) then
		return nil
	end

	local stationNames = {}

	for _, stationID in ipairs(stations) do
		local stationTable = PLUGIN.craft.stations[stationID]
		local stationName = stationTable and (stationTable.GetName and stationTable:GetName() or stationTable.name) or stationID

		stationNames[#stationNames + 1] = CLIENT and L(stationName) or L(stationName, client)
	end

	return table.concat(stationNames, " " .. L("CraftOr", client) .. " ")
end

function RECIPE:HasStationAccess(client)
	local stations = self:GetStations()

	if (!stations) then
		return true
	end

	local maxDist = 100 * 100
	local currentStation = client.ixCurrentStation
	local currentStationEnt = client.ixCurrentStationEnt

	if (IsValid(currentStationEnt) and isfunction(currentStationEnt.GetStationID) and table.HasValue(stations, currentStationEnt:GetStationID())) then
		if (client:GetPos():DistToSqr(currentStationEnt:GetPos()) < maxDist) then
			return true
		end
	end

	for _, stationID in ipairs(stations) do
		for _, entity in pairs(ents.FindByClass("ix_station_" .. stationID)) do
			if (client:GetPos():DistToSqr(entity:GetPos()) < maxDist) then
				return true
			end
		end
	end

	if (CLIENT and currentStation and table.HasValue(stations, currentStation)) then
		return true
	end

	if (CLIENT) then
		return false
	end

	return false
end

function RECIPE:GetNearbyCookingStation(client)
	local maxDist = 100 * 100
	local currentStationEnt = client.ixCurrentStationEnt

	if (IsValid(currentStationEnt) and currentStationEnt.IsStove and currentStationEnt:IsStove()) then
		if (client:GetPos():DistToSqr(currentStationEnt:GetPos()) < maxDist) then
			return currentStationEnt
		end
	end

	for _, className in ipairs(cookingStations) do
		for _, entity in ipairs(ents.FindByClass(className)) do
			if (client:GetPos():DistToSqr(entity:GetPos()) < maxDist) then
				return entity
			end
		end
	end
end

function RECIPE:OnCanSee(client)
	local character = client:GetCharacter()

	if (!character) then
		return false
	end

	if (self.preHooks and self.preHooks["OnCanSee"]) then
		local a, b, c, d, e, f = self.preHooks["OnCanSee"](self, client)

		if (a != nil) then
			return a, b, c, d, e, f
		end
	end

	if (self.flag and !character:HasFlags(self.flag)) then
		return false
	end

	if (self.postHooks and self.postHooks["OnCanSee"]) then
		local a, b, c, d, e, f = self.postHooks["OnCanSee"](self, client)

		if (a != nil) then
			return a, b, c, d, e, f
		end
	end

	return true
end

function RECIPE:CanList(client)
	local character = client:GetCharacter()

	if (!character) then
		return false
	end

	if (self.preHooks and self.preHooks["OnCanSee"]) then
		local a, b, c, d, e, f = self.preHooks["OnCanSee"](self, client)

		if (a != nil) then
			return a, b, c, d, e, f
		end
	end

	if (self.flag and !character:HasFlags(self.flag)) then
		return false
	end

	if (self.postHooks and self.postHooks["OnCanSee"]) then
		local a, b, c, d, e, f = self.postHooks["OnCanSee"](self, client)

		if (a != nil) then
			if (self.category == "Food" and a == false) then
				return true
			end

			return a, b, c, d, e, f
		end
	end

	return true
end

function RECIPE:OnCanCraft(client)
	local character = client:GetCharacter()

	if (!character) then
		return false
	end

	if (self.preHooks and self.preHooks["OnCanCraft"]) then
		local a, b, c, d, e, f = self.preHooks["OnCanCraft"](self, client)

		if (a != nil) then
			return a, b, c, d, e, f
		end
	end

	local inventory = character:GetInventory()
	local bHasItems, bHasTools
	local missing = ""

	if (self.flag and !character:HasFlags(self.flag)) then
		return false, "@CraftMissingFlag", self.flag
	end

	-- Check requirements (unified format)
	for uniqueID, entry in pairs(self.requirements or {}) do
		local req = ParseRequirement(entry)
		local bHas, missingName = self:CheckRequirement(inventory, uniqueID, req, client)

		if (!bHas) then
			bHasItems = false
			missing = missing .. missingName .. ", "
		end
	end

	if (missing != "") then
		missing = missing:sub(1, -3)
	end

	if (bHasItems == false) then
		return false, "@CraftMissingItem", missing
	end

	-- Check tools (legacy support)
	for _, uniqueID in pairs(self.tools or {}) do
		if (!inventory:HasItem(uniqueID)) then
			local itemTable = ix.item.Get(uniqueID)
			local itemName = itemTable and itemTable.name or uniqueID

			itemName = CLIENT and L(itemName) or L(itemName, client)

			bHasTools = false
			missing = itemName

			break
		end
	end

	if (bHasTools == false) then
		return false, "@CraftMissingTool", missing
	end

	-- Check station requirement
	if (!self:HasStationAccess(client)) then
		return false, "@CraftMissingStation", self:GetStationName(client)
	end

	if (self.category == "Food") then
		local cookingStation = self:GetNearbyCookingStation(client)

		if (!IsValid(cookingStation)) then
			return false, "@CraftMissingCookingStation"
		end

		if (!cookingStation:GetNetVar("active", false)) then
			return false, "@CraftStoveInactive"
		end
	end

	if (self.postHooks and self.postHooks["OnCanCraft"]) then
		local a, b, c, d, e, f = self.postHooks["OnCanCraft"](self, client)

		if (a != nil) then
			return a, b, c, d, e, f
		end
	end

	return true
end

if (SERVER) then
	function RECIPE:OnCraft(client)
		local bCanCraft, failString, c, d, e, f = self:OnCanCraft(client)

		if (bCanCraft == false) then
			return false, failString, c, d, e, f
		end

		if (self.preHooks and self.preHooks["OnCraft"]) then
			local a, b, c, d, e, f = self.preHooks["OnCraft"](self, client)

			if (a != nil) then
				return a, b, c, d, e, f
			end
		end

		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		if (self.requirements) then
			local removedItems = {}
			local items = inventory:GetItems()

			for uniqueID, entry in pairs(self.requirements) do
				local req = ParseRequirement(entry)

				-- Skip preserved items
				if (req.preserve) then
					continue
				end

				local amountToRemove = req.amount
				local amountRemoved = 0

				-- First try to remove the primary item
				for _, itemTable in pairs(items) do
					if (amountRemoved >= amountToRemove) then break end

					if (itemTable.uniqueID == uniqueID and !removedItems[itemTable.id]) then
						removedItems[itemTable.id] = true
						itemTable:Remove()
						amountRemoved = amountRemoved + 1
					end
				end

				-- If not enough primary items, try substitutes
				if (amountRemoved < amountToRemove and req.substitutes) then
					for subID, subEntry in pairs(req.substitutes) do
						if (amountRemoved >= amountToRemove) then break end

						local sub = ParseSubstitute(subEntry, req.preserve)

						-- Skip preserved substitutes
						if (sub.preserve) then
							continue
						end

						for _, itemTable in pairs(items) do
							if (amountRemoved >= amountToRemove) then break end

							if (itemTable.uniqueID == subID and !removedItems[itemTable.id]) then
								removedItems[itemTable.id] = true
								itemTable:Remove()
								amountRemoved = amountRemoved + 1
							end
						end
					end
				end
			end
		end

		for uniqueID, amount in pairs(self.results or {}) do
			if (istable(amount)) then
				if (amount["min"] and amount["max"]) then
					amount = math.random(amount["min"], amount["max"])
				else
					amount = amount[math.random(1, #amount)]
				end
			end

			for i = 1, amount do
				if (!inventory:Add(uniqueID)) then
					ix.item.Spawn(uniqueID, client)
				end
			end
		end

		if (self.postHooks and self.postHooks["OnCraft"]) then
			local a, b, c, d, e, f = self.postHooks["OnCraft"](self, client)

			if (a != nil) then
				return a, b, c, d, e, f
			end
		end

		local recipeName = self.GetName and self:GetName() or self.name

		recipeName = CLIENT and L(recipeName) or L(recipeName, client)

		return true, "@CraftSuccess", recipeName
	end
end

PLUGIN.meta.recipe = RECIPE
