local PLUGIN = PLUGIN

function PLUGIN:FetchWhitelistData(client, faction)
	local factionID = faction.uniqueID
	local results = {}

	-- 1. Query all players to find whitelists
	local playerQuery = mysql:Select("ix_players")
	playerQuery:Select("steamid")
	playerQuery:Select("steam_name")
	playerQuery:Select("data")
	playerQuery:Callback(function(data)
		if (istable(data)) then
			for _, row in ipairs(data) do
				local steamID = row.steamid
				local steamName = row.steam_name or "Unknown"
				local pData = util.JSONToTable(row.data or "[]")
				
				if (pData and pData.whitelists and pData.whitelists[factionID]) then
					results[steamID] = {
						name = steamName,
						whitelisted = true,
						rank = "user", -- Standard Helix doesn't have rank column
						online = false,
						characters = {}
					}
				end
			end
		end

		-- 2. Query characters for the specific faction
		local charQuery = mysql:Select("ix_characters")
		charQuery:Select("name")
		charQuery:Select("steamid")
		charQuery:Where("faction", factionID)
		charQuery:Callback(function(charData)
			if (istable(charData)) then
				for _, row in ipairs(charData) do
					local steamID = row.steamid
					local charName = row.name
					
					if (!results[steamID]) then
						results[steamID] = {
							name = "Offline/Unknown",
							whitelisted = false,
							rank = "user",
							online = false,
							characters = {}
						}
						
						local ply = player.GetBySteamID64(steamID)
						if (IsValid(ply)) then
							results[steamID].name = ply:SteamName()
							results[steamID].rank = ply:GetUserGroup()
							results[steamID].online = true
						end
					end
					
					table.insert(results[steamID].characters, charName)
				end
			end

			-- 3. Final merge with online player data
			for _, ply in ipairs(player.GetAll()) do
				local sid = ply:SteamID64()
				if (results[sid]) then
					results[sid].name = ply:SteamName()
					results[sid].rank = ply:GetUserGroup()
					results[sid].online = true
				end
			end

			-- 4. Send to Client
			netstream.Start(client, "OpenWhitelistChecker", factionID, results)
		end)
		charQuery:Execute()
	end)
	playerQuery:Execute()
end

netstream.Hook("RemoveWhitelist", function(client, steamID64, factionID)
	if (!client:IsAdmin()) then return end
	
	local faction = ix.faction.teams[factionID]
	if (!faction) then return end

	-- Helix handles both online and offline whitelist setting through this library function
	ix.faction.SetWhitelist(steamID64, faction.index, false)
	
	client:NotifyLocalized("wlCheckerRemovedLocal", steamID64, L(faction.name, client))
	
	-- Re-fetch data to reflect changes
	PLUGIN:FetchWhitelistData(client, faction)
end)

function PLUGIN:FetchFlagData(client)
	local results = {}

	-- 1. Query all players for player-level flags
	local playerQuery = mysql:Select("ix_players")
	playerQuery:Select("steamid")
	playerQuery:Select("steam_name")
	playerQuery:Select("data")
	playerQuery:Callback(function(data)
		if (istable(data)) then
			for _, row in ipairs(data) do
				local steamID = row.steamid
				local pData = util.JSONToTable(row.data or "[]")

				results[steamID] = {
					name = row.steam_name or "Unknown",
					rank = "user",
					online = false,
					playerFlags = pData.flags or "",
					characters = {}
				}
			end
		end

		-- 2. Query all characters for character-level flags
		local charQuery = mysql:Select("ix_characters")
		charQuery:Select("id")
		charQuery:Select("name")
		charQuery:Select("steamid")
		charQuery:Select("data")
		charQuery:Callback(function(charData)
			if (istable(charData)) then
				for _, row in ipairs(charData) do
					local steamID = row.steamid
					if (!results[steamID]) then
						results[steamID] = { name = "Offline", rank = "user", online = false, playerFlags = "", characters = {} }
					end
					
					local cData = util.JSONToTable(row.data or "[]")
					table.insert(results[steamID].characters, {
						id = row.id,
						name = row.name,
						flags = cData.f or "" -- Character flags are stored in 'f' key in data
					})
				end
			end

			-- Online sync for active players
			for _, ply in ipairs(player.GetAll()) do
				local sid = ply:SteamID64()
				if (results[sid]) then
					results[sid].name = ply:SteamName()
					results[sid].rank = ply:GetUserGroup()
					results[sid].online = true
					-- Use actual data for online players
					results[sid].playerFlags = ply:GetData("flags", results[sid].playerFlags)
					
					local char = ply:GetCharacter()
					if (char) then
						for _, cInfo in ipairs(results[sid].characters) do
							if (cInfo.id == char:GetID()) then
								cInfo.flags = char:GetFlags()
							end
						end
					end
				end
			end

			netstream.Start(client, "OpenFlagChecker", results)
		end)
		charQuery:Execute()
	end)
	playerQuery:Execute()
end

netstream.Hook("UpdatePlayerFlags", function(client, steamID, flags)
	if (!client:IsAdmin()) then return end
	
	local target = player.GetBySteamID64(steamID)
	if (IsValid(target)) then
		target:SetData("flags", flags)
	else
		-- Need to update JSON data for offline player
		local query = mysql:Select("ix_players")
		query:Select("data")
		query:Where("steamid", steamID)
		query:Callback(function(data)
			if (istable(data) and #data > 0) then
				local pData = util.JSONToTable(data[1].data or "[]")
				pData.flags = flags

				local updateQuery = mysql:Update("ix_players")
				updateQuery:Update("data", util.TableToJSON(pData))
				updateQuery:Where("steamid", steamID)
				updateQuery:Execute()
			end
		end)
		query:Execute()
	end

	client:NotifyLocalized("flCheckerFlagsUpdated")
	PLUGIN:FetchFlagData(client)
end)

netstream.Hook("UpdateCharFlags", function(client, charID, flags)
	if (!client:IsAdmin()) then return end
	
	charID = tonumber(charID)
	local character = ix.char.loaded[charID]
	if (character) then
		character:SetFlags(flags)
	else
		-- Need to update JSON data for offline character
		local query = mysql:Select("ix_characters")
		query:Select("data")
		query:Where("id", charID)
		query:Callback(function(data)
			if (istable(data) and #data > 0) then
				local cData = util.JSONToTable(data[1].data or "[]")
				cData.f = flags

				local updateQuery = mysql:Update("ix_characters")
				updateQuery:Update("data", util.TableToJSON(cData))
				updateQuery:Where("id", charID)
				updateQuery:Execute()
			end
		end)
		query:Execute()
	end

	client:NotifyLocalized("flCheckerFlagsUpdated")
	PLUGIN:FetchFlagData(client)
end)
