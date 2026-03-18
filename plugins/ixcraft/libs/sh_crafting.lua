
local PLUGIN = PLUGIN

PLUGIN.craft = PLUGIN.craft or {}
PLUGIN.craft.recipes = PLUGIN.craft.recipes or {}
PLUGIN.craft.stations = PLUGIN.craft.stations or {}

function PLUGIN.craft.LoadFromDir(directory, pathType)
	for _, v in ipairs(file.Find(directory.."/sh_*.lua", "LUA")) do
		local niceName = v:sub(4, -5)

		if (pathType == "recipe") then
			RECIPE = setmetatable({
				uniqueID = niceName
			}, PLUGIN.meta.recipe)
				ix.util.Include(directory.."/"..v, "shared")

				PLUGIN.craft.recipes[niceName] = RECIPE
			RECIPE = nil
		elseif (pathType == "station") then
			STATION = setmetatable({
				uniqueID = niceName
			}, PLUGIN.meta.station)
				ix.util.Include(directory.."/"..v, "shared")

				if (!scripted_ents.Get("ix_station_"..niceName)) then
					local STATION_ENT = scripted_ents.Get("ix_station")

					if (STATION_ENT) then
						STATION_ENT.PrintName = STATION.name
						STATION_ENT.uniqueID = niceName
						STATION_ENT.Spawnable = true
						STATION_ENT.AdminOnly = false
						STATION_ENT.Category = "Helix"

						scripted_ents.Register(STATION_ENT, "ix_station_"..niceName)
					end
				end

				PLUGIN.craft.stations[niceName] = STATION
			STATION = nil
		end
	end
end

function PLUGIN.craft.GetCategories(client)
	local categories = {}

	for k, v in pairs(PLUGIN.craft.recipes) do
		local category = v.category or "Crafting"

		if (v:CanList(client)) then
			if (!categories[category]) then
				categories[category] = {}
			end

			table.insert(categories[category], k)
		end
	end

	return categories
end

function PLUGIN.craft.FindByName(recipe)
	recipe = recipe:lower()
	local uniqueID

	for k, v in pairs(PLUGIN.craft.recipes) do
		if (recipe:find(v.name:lower())) then
			uniqueID = k

			break
		end
	end

	return uniqueID
end

if (SERVER) then
	util.AddNetworkString("ixCraftRecipe")
	util.AddNetworkString("ixCraftRefresh")

	local function RefreshCraftingMenu(client)
		timer.Simple(0.05, function()
			if (!IsValid(client)) then
				return
			end

			net.Start("ixCraftRefresh")
			net.Send(client)
		end)
	end

	local function NotifyCraftMessage(client, text, a, b, c, d)
		if (!text) then
			return
		end

		if (text:sub(1, 1) == "@") then
			text = L(text:sub(2), client, a, b, c, d)
		end

		client:Notify(text)
	end

	local function ClearCraftState(client)
		if (!IsValid(client)) then
			return
		end

		client.ixCraftingRecipe = nil
		client:SetAction(false)
		timer.Remove("ixStare" .. client:SteamID64())
	end

	local function CompleteCraft(client, recipeTable)
		local success, craftString, a, b, c, d = recipeTable:OnCraft(client)

		NotifyCraftMessage(client, craftString, a, b, c, d)
		hook.Run("CraftRecipeCompleted", client, recipeTable, success)
		RefreshCraftingMenu(client)

		return success
	end

	function PLUGIN.craft.CraftRecipe(client, uniqueID)
		local recipeTable = PLUGIN.craft.recipes[uniqueID]

		if (recipeTable) then
			local bCanCraft, failString, a, b, c, d = recipeTable:OnCanCraft(client)

			if (!bCanCraft) then
				NotifyCraftMessage(client, failString, a, b, c, d)

				return false
			end

			if (client.ixCraftingRecipe) then
				client:NotifyLocalized("CraftAlreadyInProgress")

				return false
			end

			local craftTime = recipeTable.GetCraftTime and recipeTable:GetCraftTime(client) or 0

			if (craftTime <= 0) then
				return CompleteCraft(client, recipeTable)
			end

			local actionText = recipeTable.GetCraftActionText and recipeTable:GetCraftActionText(client) or L("CraftingProgress", client, recipeTable:GetName())
			local actionEntity = recipeTable.GetCraftActionEntity and recipeTable:GetCraftActionEntity(client) or nil
			local craftSound = recipeTable.GetCraftSound and recipeTable:GetCraftSound(client) or nil
			local soundEntity = IsValid(actionEntity) and actionEntity or client

			client.ixCraftingRecipe = uniqueID

			if (craftSound and IsValid(soundEntity)) then
				soundEntity:EmitSound(craftSound, 60, 100, 0.5)
			end

			hook.Run("CraftRecipeStarted", client, recipeTable, craftTime, actionEntity)

			local function FinishCraft()
				if (!IsValid(client) or client.ixCraftingRecipe != uniqueID) then
					return
				end

				client.ixCraftingRecipe = nil
				CompleteCraft(client, recipeTable)
			end

			local function CancelCraft()
				if (!IsValid(client)) then
					return
				end

				ClearCraftState(client)
				hook.Run("CraftRecipeCancelled", client, recipeTable)
				RefreshCraftingMenu(client)
			end

			if (IsValid(actionEntity)) then
				client:SetAction(actionText, craftTime)
				client:DoStaredAction(actionEntity, FinishCraft, craftTime, CancelCraft, 100)
			else
				client:SetAction(actionText, craftTime, FinishCraft)
			end

			return true
		end
	end

	hook.Add("PlayerSpawn", "ixCraftingCancelCraft", function(client)
		if (client.ixCraftingRecipe) then
			ClearCraftState(client)
		end
	end)

	net.Receive("ixCraftRecipe", function(length, client)
		local uniqueID = net.ReadString()
		local stationID = net.ReadString()
		local stationEntIndex = net.ReadUInt(16)

		-- Store station context on the player for validation
		if (stationID and stationID != "") then
			client.ixCurrentStation = stationID
		else
			client.ixCurrentStation = nil
		end

		client.ixCurrentStationEnt = stationEntIndex > 0 and Entity(stationEntIndex) or nil

		PLUGIN.craft.CraftRecipe(client, uniqueID)
	end)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.string
	COMMAND.description = "@cmdCraftRecipe"

	function COMMAND:OnRun(client, recipe)
		PLUGIN.craft.CraftRecipe(client, PLUGIN.craft.FindByName(recipe))
	end

	ix.command.Add("CraftRecipe", COMMAND)
end

hook.Add("DoPluginIncludes", "ixCrafting", function(path, pluginTable)
	if (!PLUGIN.paths) then
		PLUGIN.paths = {}
	end

	table.insert(PLUGIN.paths, path)
end)
