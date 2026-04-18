local PLUGIN = PLUGIN

PLUGIN.name = "Territory Control"
PLUGIN.author = "Frosty"
PLUGIN.description = "Adds capturable area properties with persistent territory ownership."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.util.Include("languages/sh_english.lua")
ix.util.Include("languages/sh_korean.lua")
ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")

PLUGIN.captureTickInterval = 1
PLUGIN.defaultCaptureTime = 20
PLUGIN.captureTeams = PLUGIN.captureTeams or {}
PLUGIN.captureTeamPresets = {
	{
		id = "overwatch",
		name = "territoryTeamOverwatch",
		color = Color(43, 64, 116),
		factions = {
			"FACTION_ADMIN",
			"FACTION_OTA",
			"FACTION_MPF",
			"FACTION_CONSCRIPT"
		}
	},
	{
		id = "resistance",
		name = "territoryTeamResistance",
		color = Color(243, 123, 33),
		factions = {
			"FACTION_CITIZEN",
			"FACTION_VORT"
		}
	}
}

function PLUGIN:SetupAreaProperties()
	ix.area.AddProperty("capturable", ix.type.bool, false, {
		category = "Territory Control"
	})
end

function PLUGIN:BuildDefaultCaptureTeams()
	local teams = {}

	for _, preset in ipairs(self.captureTeamPresets or {}) do
		local resolvedFactions = {}

		for _, factionGlobalName in ipairs(preset.factions or {}) do
			local factionID = _G[factionGlobalName]

			if (factionID != nil) then
				resolvedFactions[factionID] = true
			end
		end

		if (!table.IsEmpty(resolvedFactions)) then
			teams[preset.id] = {
				name = preset.name,
				color = preset.color,
				factions = resolvedFactions
			}
		end
	end

	return teams
end

function PLUGIN:InitializedPlugins()
	if (table.IsEmpty(self.captureTeams or {})) then
		self.captureTeams = self:BuildDefaultCaptureTeams()
	end

	self.areaStates = self.areaStates or {}
	self.territorySpawns = self.territorySpawns or {}
end

function PLUGIN:GetCaptureAreas()
	local captureAreas = {}

	if (!ix.area or !ix.area.stored) then
		return captureAreas
	end

	for areaID, area in pairs(ix.area.stored) do
		if (area.properties and area.properties.capturable) then
			captureAreas[areaID] = area
		end
	end

	return captureAreas
end

function PLUGIN:GetAreaName(areaID)
	if (!areaID or !ix.area or !ix.area.stored) then
		return nil
	end

	local area = ix.area.stored[areaID]
	if (!area) then
		return nil
	end

	return area.name or areaID
end

function PLUGIN:GetCaptureTeam(teamID)
	if (!teamID) then
		return nil
	end

	return self.captureTeams and self.captureTeams[teamID] or nil
end

function PLUGIN:GetCaptureTeamName(teamID, client)
	local teamData = self:GetCaptureTeam(teamID)

	if (!teamData) then
		return L("territoryUnclaimed", client)
	end

	return L(teamData.name or teamID, client)
end

function PLUGIN:GetCaptureTeamColor(teamID)
	local teamData = self:GetCaptureTeam(teamID)
	return teamData and teamData.color or Color(200, 200, 200)
end

function PLUGIN:GetPlayerCaptureTeamID(client)
	if (!IsValid(client) or !client.GetCharacter or !client:GetCharacter()) then
		return nil
	end

	local faction = client:Team()

	for teamID, teamData in pairs(self.captureTeams or {}) do
		if (teamData.factions and teamData.factions[faction]) then
			return teamID
		end
	end
end

function PLUGIN:IsCapturableArea(areaID)
	if (!areaID or !ix.area or !ix.area.stored) then
		return false
	end

	local area = ix.area.stored[areaID]
	return area and area.properties and area.properties.capturable == true
end

function PLUGIN:GetAreaState(areaID)
	self.areaStates = self.areaStates or {}
	self.areaStates[areaID] = self.areaStates[areaID] or {
		ownerTeamID = nil,
		progressTeamID = nil,
		progress = 0,
		contested = false
	}

	return self.areaStates[areaID]
end

function PLUGIN:GetCaptureStatusText(areaID, ownerTeamID, progressTeamID, contested, client)
	if (contested) then
		return L("territoryStatusContested", client)
	end

	if (progressTeamID) then
		return L("territoryStatusCapturing", client, self:GetCaptureTeamName(progressTeamID, client))
	end

	if (ownerTeamID) then
		return L("territoryStatusHeldBy", client, self:GetCaptureTeamName(ownerTeamID, client))
	end

	return L("territoryStatusUnclaimed", client)
end

function PLUGIN:GetTerritorySpawns()
	self.territorySpawns = self.territorySpawns or {}
	return self.territorySpawns
end

ix.command.Add("AreaSetNeutral", {
	description = "@cmdAreaSetNeutral",
	adminOnly = true,
	OnRun = function(self, client)
		local areaID = client:GetArea()

		if (!PLUGIN:IsCapturableArea(areaID)) then
			return "@territoryAreaRequired"
		end

		PLUGIN:ClearAreaOwner(areaID)
		PLUGIN:SyncPlayersInArea(areaID)

		return "@territoryAreaNeutralized", PLUGIN:GetAreaName(areaID) or areaID
	end
})

ix.command.Add("AreaSetController", {
	description = "@cmdAreaSetController",
	adminOnly = true,
	arguments = {
		ix.type.text
	},
	OnRun = function(self, client, teamID)
		local areaID = client:GetArea()

		if (!PLUGIN:IsCapturableArea(areaID)) then
			return "@territoryAreaRequired"
		end

		if (!PLUGIN:GetCaptureTeam(teamID)) then
			return "@territoryUnknownTeam", teamID
		end

		PLUGIN:SetAreaOwner(areaID, teamID)
		PLUGIN:SyncPlayersInArea(areaID)

		return "@territoryAreaControlledBy", PLUGIN:GetAreaName(areaID) or areaID, PLUGIN:GetCaptureTeamName(teamID, client)
	end
})

ix.command.Add("TerritorySpawnAdd", {
	description = "@cmdTerritorySpawnAdd",
	adminOnly = true,
	arguments = {
		ix.type.text,
		ix.type.text
	},
	OnRun = function(self, client, teamID, areaID)
		if (!PLUGIN:GetCaptureTeam(teamID)) then
			return "@territoryUnknownTeam", teamID
		end

		if (!PLUGIN:IsCapturableArea(areaID)) then
			return "@territoryAreaInvalid", areaID
		end

		local spawnID = PLUGIN:AddTerritorySpawn(client:GetPos(), client:EyeAngles(), teamID, areaID)
		return "@territorySpawnAdded", spawnID, PLUGIN:GetCaptureTeamName(teamID, client), PLUGIN:GetAreaName(areaID) or areaID
	end
})

ix.command.Add("TerritorySpawnRemove", {
	description = "@cmdTerritorySpawnRemove",
	adminOnly = true,
	arguments = bit.bor(ix.type.number, ix.type.optional),
	OnRun = function(self, client, radius)
		local removed = PLUGIN:RemoveTerritorySpawnsInRadius(client:GetPos(), radius or 120)
		return "@territorySpawnRemoved", removed
	end
})
