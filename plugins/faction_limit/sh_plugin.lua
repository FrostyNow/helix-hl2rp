
PLUGIN.name = "Faction Member Limit"
PLUGIN.author = "Frosty"
PLUGIN.description = "Limits the number of players that can be in a specific faction at once."

ix.lang.AddTable("english", {
	factionLimitReached = "The faction you are trying to join has reached its maximum limit, %s."
})

ix.lang.AddTable("korean", {
	factionLimitReached = "해당 세력에 접속 중인 인원이 최대치 %s명에 도달했습니다."
})

-- Configuration
ix.config.Add("factionLimitEnabled", false, "Whether or not to limit the number of players in a specific faction.", nil, {
	category = "Faction Limit"
})

ix.config.Add("factionLimitTarget", "metropolice, ota, administrator, conscript, vortigaunt", "The uniqueID of the faction to limit.", nil, {
	category = "Faction Limit"
})

ix.config.Add("factionLimitMax", 5, "The maximum number of players allowed in the limited faction.", nil, {
	data = {min = 1, max = 128},
	category = "Faction Limit"
})

-- Helper function to check if a faction has reached its limit
local function IsFactionFull(factionIndex)
	local factionData = ix.faction.indices[factionIndex]
	if (!factionData) then return false end

	local limitedFactionsRaw = ix.config.Get("factionLimitTarget", "metropolice")
	local maxLimit = ix.config.Get("factionLimitMax", 5)

	-- Split the comma-separated string into a table of uniqueIDs
	local limitedFactions = string.Explode(",", limitedFactionsRaw)
	local isLimited = false

	for _, v in ipairs(limitedFactions) do
		if (factionData.uniqueID == string.Trim(v)) then
			isLimited = true
			break
		end
	end

	if (isLimited) then
		local count = 0

		for _, v in ipairs(player.GetAll()) do
			local targetChar = v:GetCharacter()

			if (targetChar and targetChar:GetFaction() == factionIndex) then
				count = count + 1
			end
		end

		return count >= maxLimit
	end

	return false
end

-- Hook: When a player tries to select a character from the main menu
function PLUGIN:CanPlayerSelectCharacter(client, character)
	if (!ix.config.Get("factionLimitEnabled", false)) then
		return
	end

	-- Administrators override the limit
	if (client:IsAdmin()) then
		return
	end

	if (IsFactionFull(character:GetFaction())) then
		client:NotifyLocalized("factionLimitReached", ix.get.Config("factionLimitMax", 5))
		return false
	end
end

-- Hook: Prevent equipping transfer items if the target faction is full
-- This prevents the "broken model" bug where model changes but faction change is blocked.
function PLUGIN:CanPlayerEquipItem(client, item)
	if (!ix.config.Get("factionLimitEnabled", false)) then
		return
	end

	-- Administrators override the limit
	if (client:IsAdmin()) then
		return
	end

	-- Determine target faction based on item flags or names
	-- In this schema, 'M' flag is for Metropolice, 'C' flag is for Conscript
	local targetFaction = nil

	if (isfunction(item.HasFlags)) then
		if (item:HasFlags("M")) then targetFaction = FACTION_MPF end
		if (item:HasFlags("C")) then targetFaction = FACTION_CONSCRIPT end
	end

	-- Fallback to name/uniqueID check for known items
	if (!targetFaction) then
		local name = item.name or ""
		local uid = item.uniqueID or ""

		if (name == "Metropolice Uniform" or uid == "metropolice") then
			targetFaction = FACTION_MPF
		elseif (name == "Conscript Fatigue" or uid == "conscript") then
			targetFaction = FACTION_CONSCRIPT
		end
	end

	if (targetFaction and IsFactionFull(targetFaction)) then
		client:NotifyLocalized("factionLimitReached", ix.get.Config("factionLimitMax", 5))
		return false
	end
end