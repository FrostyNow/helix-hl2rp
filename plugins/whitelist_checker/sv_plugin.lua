local PLUGIN = PLUGIN

function PLUGIN:FetchWhitelistData(client, faction)
	local factionID = faction.uniqueID
	local factionIndex = faction.index
	
	local results = {}

	-- 1. Query all players to find whitelists
	local playerQuery = mysql:Select("ix_players")
	playerQuery:Select("_steamID64")
	playerQuery:Select("_steamName")
	playerQuery:Select("_userGroup")
	playerQuery:Select("_data")
	playerQuery:Callback(function(data)
		if (istable(data)) then
			for _, row in ipairs(data) do
				local steamID = row._steamID64
				local steamName = row._steamName or "Unknown"
				local userGroup = row._userGroup or "user"
				local pData = util.JSONToTable(row._data or "[]")
				
				if (pData and pData.whitelists and pData.whitelists[factionID]) then
					results[steamID] = {
						name = steamName,
						whitelisted = true,
						rank = userGroup,
						online = false,
						characters = {}
					}
				end
			end
		end

		-- 2. Query characters for the specific faction
		local charQuery = mysql:Select("ix_characters")
		charQuery:Select("_name")
		charQuery:Select("_steamID64")
		charQuery:Where("_faction", factionIndex)
		charQuery:Callback(function(charData)
			if (istable(charData)) then
				for _, row in ipairs(charData) do
					local steamID = row._steamID64
					local charName = row._name
					
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
	playerQuery:Select("_steamID64")
	playerQuery:Select("_steamName")
	playerQuery:Select("_userGroup")
	playerQuery:Select("_flags")
	playerQuery:Callback(function(data)
		if (istable(data)) then
			for _, row in ipairs(data) do
				local steamID = row._steamID64
				results[steamID] = {
					name = row._steamName or "Unknown",
					rank = row._userGroup or "user",
					online = false,
					playerFlags = row._flags or "",
					characters = {}
				}
			end
		end

		-- 2. Query all characters for character-level flags
		local charQuery = mysql:Select("ix_characters")
		charQuery:Select("_id")
		charQuery:Select("_name")
		charQuery:Select("_steamID64")
		charQuery:Select("_flags")
		charQuery:Callback(function(charData)
			if (istable(charData)) then
				for _, row in ipairs(charData) do
					local steamID = row._steamID64
					if (!results[steamID]) then
						results[steamID] = { name = "Offline", rank = "user", online = false, playerFlags = "", characters = {} }
					end
					
					table.insert(results[steamID].characters, {
						id = row._id,
						name = row._name,
						flags = row._flags or ""
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
		local query = mysql:Update("ix_players")
		query:Update("_flags", flags)
		query:Where("_steamID64", steamID)
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
		local query = mysql:Update("ix_characters")
		query:Update("_flags", flags)
		query:Where("_id", charID)
		query:Execute()
	end

	client:NotifyLocalized("flCheckerFlagsUpdated")
	PLUGIN:FetchFlagData(client)
end)
