local PLUGIN = PLUGIN

PLUGIN.fullRescanInterval = 30

function PLUGIN:SaveData()
	local data = {
		owners = {},
		territorySpawns = self.territorySpawns or {}
	}

	for areaID, state in pairs(self.areaStates or {}) do
		if (state.ownerTeamID and self:IsCapturableArea(areaID)) then
			data.owners[areaID] = {
				ownerTeamID = state.ownerTeamID
			}
		end
	end

	self:SetData(data)
end

function PLUGIN:LoadData()
	local data = self:GetData() or {}
	self.areaStates = self.areaStates or {}
	self.territorySpawns = {}

	local owners = data.owners or data

	for areaID, savedState in pairs(owners) do
		local state = self:GetAreaState(areaID)
		state.ownerTeamID = savedState.ownerTeamID
		state.progressTeamID = nil
		state.progress = 0
		state.contested = false
	end

	for spawnID, spawnData in pairs(data.territorySpawns or {}) do
		if (isvector(spawnData.pos) and isangle(spawnData.ang) and isstring(spawnData.teamID) and isstring(spawnData.areaID)) then
			self.territorySpawns[tonumber(spawnID) or spawnID] = spawnData
		end
	end
end

function PLUGIN:GetCaptureTime(areaID)
	return self.defaultCaptureTime
end

function PLUGIN:GetAreaPlayers(areaID)
	local playersInArea = {}

	for _, client in ipairs(player.GetAll()) do
		if (!IsValid(client) or !client:Alive()) then
			continue
		end

		if (!client:GetCharacter() or client:GetMoveType() == MOVETYPE_NOCLIP) then
			continue
		end

		if (client:GetArea() == areaID) then
			playersInArea[#playersInArea + 1] = client
		end
	end

	return playersInArea
end

function PLUGIN:ResetPlayerAreaTracking(client)
	if (!IsValid(client)) then
		return
	end

	local previousAreaID = client.ixTerritoryTrackedAreaID

	if (previousAreaID and self.activeAreaCounts and self.activeAreaCounts[previousAreaID]) then
		self.activeAreaCounts[previousAreaID] = math.max(self.activeAreaCounts[previousAreaID] - 1, 0)

		if (self.activeAreaCounts[previousAreaID] <= 0) then
			self.activeAreaCounts[previousAreaID] = nil
			self.activeCaptureAreas[previousAreaID] = nil
			self:ResetAreaCaptureProgress(previousAreaID)
		end
	end

	client.ixTerritoryTrackedAreaID = nil
end

function PLUGIN:UpdatePlayerAreaTracking(client)
	self.activeCaptureAreas = self.activeCaptureAreas or {}
	self.activeAreaCounts = self.activeAreaCounts or {}

	local previousAreaID = client.ixTerritoryTrackedAreaID
	local nextAreaID

	if (IsValid(client) and client:Alive() and client:GetCharacter() and client:GetMoveType() != MOVETYPE_NOCLIP) then
		local areaID = client:GetArea()

		if (self:IsCapturableArea(areaID)) then
			nextAreaID = areaID
		end
	end

	if (previousAreaID == nextAreaID) then
		return
	end

	if (previousAreaID and self.activeAreaCounts[previousAreaID]) then
		self.activeAreaCounts[previousAreaID] = math.max(self.activeAreaCounts[previousAreaID] - 1, 0)

		if (self.activeAreaCounts[previousAreaID] <= 0) then
			self.activeAreaCounts[previousAreaID] = nil
			self.activeCaptureAreas[previousAreaID] = nil
			self:ResetAreaCaptureProgress(previousAreaID)
		end
	end

	client.ixTerritoryTrackedAreaID = nextAreaID

	if (nextAreaID) then
		self.activeAreaCounts[nextAreaID] = (self.activeAreaCounts[nextAreaID] or 0) + 1
		self.activeCaptureAreas[nextAreaID] = true
	end
end

function PLUGIN:RebuildActiveCaptureAreas()
	self.activeCaptureAreas = {}
	self.activeAreaCounts = {}

	for _, client in ipairs(player.GetAll()) do
		client.ixTerritoryTrackedAreaID = nil
		self:UpdatePlayerAreaTracking(client)
	end
end

function PLUGIN:GetActiveCaptureAreas()
	self.activeCaptureAreas = self.activeCaptureAreas or {}
	return self.activeCaptureAreas
end

function PLUGIN:GetAreaLeader(areaID)
	local counts = {}
	local highest = 0
	local highestTeamID
	local tied = false

	for _, client in ipairs(self:GetAreaPlayers(areaID)) do
		local teamID = self:GetPlayerCaptureTeamID(client)

		if (!teamID) then
			continue
		end

		counts[teamID] = (counts[teamID] or 0) + 1

		if (counts[teamID] > highest) then
			highest = counts[teamID]
			highestTeamID = teamID
			tied = false
		elseif (counts[teamID] == highest and highest > 0 and highestTeamID != teamID) then
			tied = true
		end
	end

	if (highest <= 0) then
		return nil, counts, false
	end

	if (tied) then
		return nil, counts, true
	end

	return highestTeamID, counts, false
end

function PLUGIN:SetAreaOwner(areaID, teamID)
	local state = self:GetAreaState(areaID)
	state.ownerTeamID = teamID
	state.progressTeamID = nil
	state.progress = 0
	state.contested = false
	self:SaveData()
end

function PLUGIN:ClearAreaOwner(areaID)
	local state = self:GetAreaState(areaID)
	state.ownerTeamID = nil
	state.progressTeamID = nil
	state.progress = 0
	state.contested = false
	self:SaveData()
end

function PLUGIN:ResetAreaCaptureProgress(areaID)
	local state = self:GetAreaState(areaID)
	state.progressTeamID = nil
	state.progress = 0
	state.contested = false
end

function PLUGIN:GetNextTerritorySpawnID()
	local highestID = 0

	for spawnID in pairs(self:GetTerritorySpawns()) do
		highestID = math.max(highestID, tonumber(spawnID) or 0)
	end

	return highestID + 1
end

function PLUGIN:AddTerritorySpawn(pos, ang, teamID, areaID)
	local spawnID = self:GetNextTerritorySpawnID()

	self:GetTerritorySpawns()[spawnID] = {
		pos = pos,
		ang = ang,
		teamID = teamID,
		areaID = areaID
	}

	self:SaveData()

	return spawnID
end

function PLUGIN:RemoveTerritorySpawnsInRadius(position, radius)
	local removed = 0
	local radiusSqr = radius * radius

	for spawnID, spawnData in pairs(self:GetTerritorySpawns()) do
		if (spawnData.pos:DistToSqr(position) <= radiusSqr) then
			self.territorySpawns[spawnID] = nil
			removed = removed + 1
		end
	end

	if (removed > 0) then
		self:SaveData()
	end

	return removed
end

function PLUGIN:IsTerritorySpawnActive(spawnData)
	if (!spawnData or !self:IsCapturableArea(spawnData.areaID)) then
		return false
	end

	local state = self:GetAreaState(spawnData.areaID)
	return state.ownerTeamID == spawnData.teamID and state.ownerTeamID != nil
end

function PLUGIN:GetActiveTerritorySpawnsForClient(client)
	if (!ix.config.Get("territoryControlEnabled", false)) then
		return {}
	end

	local teamID = self:GetPlayerCaptureTeamID(client)

	if (!teamID) then
		return {}
	end

	local spawns = {}

	for _, spawnData in pairs(self:GetTerritorySpawns()) do
		if (spawnData.teamID == teamID and self:IsTerritorySpawnActive(spawnData)) then
			spawns[#spawns + 1] = spawnData
		end
	end

	return spawns
end

function PLUGIN:PostPlayerLoadout(client)
	local spawns = self:GetActiveTerritorySpawnsForClient(client)

	if (table.IsEmpty(spawns)) then
		return
	end

	local spawnData = spawns[math.random(#spawns)]
	client:SetPos(spawnData.pos)
	client:SetEyeAngles(Angle(0, spawnData.ang.y, 0))
end

function PLUGIN:ProcessAreaCapture(areaID)
	local state = self:GetAreaState(areaID)
	local leaderTeamID, _, contested = self:GetAreaLeader(areaID)

	state.contested = contested

	if (contested) then
		state.progressTeamID = nil
		state.progress = 0
		return
	end

	if (!leaderTeamID) then
		state.progressTeamID = nil
		state.progress = 0
		return
	end

	if (state.ownerTeamID == leaderTeamID) then
		state.progressTeamID = nil
		state.progress = 0
		return
	end

	if (state.progressTeamID != leaderTeamID) then
		state.progressTeamID = leaderTeamID
		state.progress = 0
	end

	state.progress = math.Clamp(
		state.progress + (self.captureTickInterval / math.max(self:GetCaptureTime(areaID), 1)),
		0,
		1
	)

	if (state.progress >= 1) then
		state.ownerTeamID = leaderTeamID
		state.progressTeamID = nil
		state.progress = 0
		state.contested = false
		self:SaveData()
	end
end

function PLUGIN:SyncTerritoryHUD(client)
	if (!IsValid(client)) then
		return
	end

	if (!ix.config.Get("territoryControlEnabled", false)) then
		local previousHUD = client.ixTerritoryHUDState or {}

		if (!table.IsEmpty(previousHUD)) then
			client:SetLocalVar("territoryAreaID", nil)
			client:SetLocalVar("territoryAreaName", nil)
			client:SetLocalVar("territoryOwnerTeamID", nil)
			client:SetLocalVar("territoryProgressTeamID", nil)
			client:SetLocalVar("territoryProgress", 0)
			client:SetLocalVar("territoryContested", false)
			client.ixTerritoryHUDState = {}
		end

		return
	end

	local areaID = client:IsInArea() and client:GetArea() or nil

	if (!self:IsCapturableArea(areaID)) then
		local previousHUD = client.ixTerritoryHUDState or {}

		if (!table.IsEmpty(previousHUD)) then
			client:SetLocalVar("territoryAreaID", nil)
			client:SetLocalVar("territoryAreaName", nil)
			client:SetLocalVar("territoryOwnerTeamID", nil)
			client:SetLocalVar("territoryProgressTeamID", nil)
			client:SetLocalVar("territoryProgress", 0)
			client:SetLocalVar("territoryContested", false)
			client.ixTerritoryHUDState = {}
		end

		return
	end

	local state = self:GetAreaState(areaID)
	local nextHUD = {
		areaID = areaID,
		areaName = self:GetAreaName(areaID),
		ownerTeamID = state.ownerTeamID,
		progressTeamID = state.progressTeamID,
		progress = math.Round(state.progress or 0, 3),
		contested = state.contested == true
	}
	local previousHUD = client.ixTerritoryHUDState or {}

	if (previousHUD.areaID == nextHUD.areaID
	and previousHUD.areaName == nextHUD.areaName
	and previousHUD.ownerTeamID == nextHUD.ownerTeamID
	and previousHUD.progressTeamID == nextHUD.progressTeamID
	and previousHUD.progress == nextHUD.progress
	and previousHUD.contested == nextHUD.contested) then
		return
	end

	client:SetLocalVar("territoryAreaID", nextHUD.areaID)
	client:SetLocalVar("territoryAreaName", nextHUD.areaName)
	client:SetLocalVar("territoryOwnerTeamID", nextHUD.ownerTeamID)
	client:SetLocalVar("territoryProgressTeamID", nextHUD.progressTeamID)
	client:SetLocalVar("territoryProgress", nextHUD.progress)
	client:SetLocalVar("territoryContested", nextHUD.contested)
	client.ixTerritoryHUDState = nextHUD
end

function PLUGIN:SyncPlayersInArea(areaID)
	for _, client in ipairs(player.GetAll()) do
		if (client:GetArea() == areaID) then
			self:SyncTerritoryHUD(client)
		end
	end
end

function PLUGIN:Think()
	self.ixNextTerritoryTick = self.ixNextTerritoryTick or 0
	self.ixNextTerritoryFullRescan = self.ixNextTerritoryFullRescan or 0

	if (!ix.config.Get("territoryControlEnabled", false)) then
		return
	end

	if (self.ixNextTerritoryFullRescan <= CurTime()) then
		self:RebuildActiveCaptureAreas()
		self.ixNextTerritoryFullRescan = CurTime() + self.fullRescanInterval
	end

	if (self.ixNextTerritoryTick > CurTime()) then
		return
	end

	self.ixNextTerritoryTick = CurTime() + self.captureTickInterval

	for areaID in pairs(self:GetActiveCaptureAreas()) do
		self:ProcessAreaCapture(areaID)
		self:SyncPlayersInArea(areaID)
	end
end

function PLUGIN:PlayerTick(client)
	local previousAreaID = client.ixTerritoryTrackedAreaID
	self:UpdatePlayerAreaTracking(client)
	local nextAreaID = client.ixTerritoryTrackedAreaID

	local previousHUDAreaID = client.ixTerritoryHUDAreaID
	local nextHUDAreaID = client:IsInArea() and client:GetArea() or nil
	client.ixTerritoryHUDAreaID = nextHUDAreaID

	if (previousAreaID != nextAreaID or previousHUDAreaID != nextHUDAreaID) then
		self:SyncTerritoryHUD(client)
	end
end

function PLUGIN:PlayerLoadedCharacter(client)
	timer.Simple(0.25, function()
		if (IsValid(client)) then
			self:UpdatePlayerAreaTracking(client)
			self:SyncTerritoryHUD(client)
		end
	end)
end

function PLUGIN:PlayerSpawn(client)
	timer.Simple(0.25, function()
		if (IsValid(client)) then
			self:UpdatePlayerAreaTracking(client)
			self:SyncTerritoryHUD(client)
		end
	end)
end

function PLUGIN:PlayerDisconnected(client)
	self:ResetPlayerAreaTracking(client)
end

function PLUGIN:PlayerDeath(client)
	self:ResetPlayerAreaTracking(client)
	self:SyncTerritoryHUD(client)
end
