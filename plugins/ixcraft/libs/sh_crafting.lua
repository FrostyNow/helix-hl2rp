
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

		if (v:OnCanSee(client)) then
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

	function PLUGIN.craft.CraftRecipe(client, uniqueID)
		local recipeTable = PLUGIN.craft.recipes[uniqueID]

		if (recipeTable) then
			local bCanCraft, failString, c, d, e, f = recipeTable:OnCanCraft(client)

			if (!bCanCraft) then
				if (failString) then
					if (failString:sub(1, 1) == "@") then
						failString = L(failString:sub(2), client, c, d, e, f)
					end

					client:Notify(failString)
				end

				return false
			end

			local success, craftString, c, d, e, f = recipeTable:OnCraft(client)

			if (craftString) then
				if (craftString:sub(1, 1) == "@") then
					craftString = L(craftString:sub(2), client, c, d, e, f)
				end

				client:Notify(craftString)
			end

			return success
		end
	end

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

		timer.Simple(0.2, function()
			net.Start("ixCraftRefresh")
			net.Send(client)
		end)
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
