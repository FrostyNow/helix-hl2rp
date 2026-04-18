
local PLUGIN = PLUGIN

PLUGIN.name = "Observer Spawns"
PLUGIN.author = "Frosty"
PLUGIN.description = "Displays spawn points while in observer mode."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.lang.AddTable("english", {
	optObserverSpawnpointESP = "Show Spawnpoint ESP",
	optdObserverSpawnpointESP = "Shows the names and locations of each faction spawnpoint in the server.",
	territorySpawnLabel = "%s Territory Spawn (%s)",
})
ix.lang.AddTable("korean", {
	optObserverSpawnpointESP = "시작지점 ESP 보기",
	optdObserverSpawnpointESP = "서버에 있는 각 세력의 시작지점의 이름과 위치를 표시합니다.",
	territorySpawnLabel = "%s 점령 스폰 (%s)",
})

ix.option.Add("observerSpawnpointESP", ix.type.bool, true, {
	category = "observer",
	hidden = function()
		return !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Observer", nil)
	end
})

if (SERVER) then
	util.AddNetworkString("ixSpawnSync")

	function PLUGIN:SyncSpawns(client)
		local spawnsPlugin = ix.plugin.list["spawns"]
		if (!spawnsPlugin) then return end

		if (client) then
			net.Start("ixSpawnSync")
				net.WriteTable(spawnsPlugin.spawns or {})
			net.Send(client)
		else
			local admins = {}
			for _, v in player.Iterator() do
				if (CAMI.PlayerHasAccess(v, "Helix - Observer", nil)) then
					admins[#admins + 1] = v
				end
			end

			if (#admins > 0) then
				net.Start("ixSpawnSync")
					net.WriteTable(spawnsPlugin.spawns or {})
				net.Send(admins)
			end
		end
	end

	function PLUGIN:PlayerLoadedCharacter(client, character, lastCharacter)
		if (CAMI.PlayerHasAccess(client, "Helix - Observer", nil)) then
			self:SyncSpawns(client)
		end
	end

	-- Hook into spawns plugin saving
	function PLUGIN:OnSavedSpawns()
		self:SyncSpawns()
	end

	-- Since the spawns plugin doesn't have a hook for when spawns are saved,
	-- we'll wrap the SaveSpawns function if it exists.
	function PLUGIN:InitializedPlugins()
		local spawnsPlugin = ix.plugin.list["spawns"]
		if (spawnsPlugin) then
			local oldSaveSpawns = spawnsPlugin.SaveSpawns
			spawnsPlugin.SaveSpawns = function(this)
				oldSaveSpawns(this)
				hook.Run("OnSavedSpawns")
			end
		end
	end

	function PLUGIN:InitPostEntity()
		self:SyncSpawns()
	end

	function PLUGIN:OnReloaded()
		timer.Simple(0.1, function()
			self:SyncSpawns()
		end)
	end
else
	PLUGIN.spawns = PLUGIN.spawns or {}

	net.Receive("ixSpawnSync", function()
		PLUGIN.spawns = net.ReadTable()
	end)

	local dimDistance = 2048
	local territoryMarkerColor = Color(255, 215, 80)

	local function DrawSpawnMarker(x, y, size, color, alpha)
		surface.SetDrawColor(color.r, color.g, color.b, alpha)
		surface.DrawOutlinedRect(x - size / 2, y - size / 2, size, size)
		surface.DrawOutlinedRect(x - size / 2 + 1, y - size / 2 + 1, size - 2, size - 2)
	end

	function PLUGIN:HUDPaint()
		local client = LocalPlayer()

		if (ix.option.Get("observerSpawnpointESP", true) and client:GetMoveType() == MOVETYPE_NOCLIP and
			!client:InVehicle() and CAMI.PlayerHasAccess(client, "Helix - Observer", nil) and ix.option.Get("observerSpawnpointESP", true)) then
			
			local clientPos = client:GetPos()
			local scrW, scrH = ScrW(), ScrH()
			local marginX, marginY = scrH * .1, scrH * .1

			for factionID, classes in pairs(self.spawns) do
				local faction = ix.faction.teams[factionID]
				local factionColor = faction and faction.color or color_white
				local factionName = faction and L(faction.name) or factionID

				for classID, points in pairs(classes) do
					local class
					for _, v in pairs(ix.class.list) do
						if (v.uniqueID == classID) then
							class = v
							break
						end
					end

					local className = class and L(class.name) or classID
					local drawColor = (class and class.color) and class.color or factionColor

					for _, pos in pairs(points) do
						local distance = clientPos:Distance(pos)
						if (distance > dimDistance * 4) then continue end

						local screenPosition = pos:ToScreen()
						if (!screenPosition.visible) then continue end

						local x, y = screenPosition.x, screenPosition.y
						
						local factor = 1 - math.Clamp(distance / dimDistance, 0, 1)
						local size = math.max(10, 32 * factor)
						local alpha = math.max(255 * factor, 80)

						DrawSpawnMarker(x, y, size, drawColor, alpha)

						local text = factionName

						if (classID != "default" and className:lower() != "default") then
							text = string.format("%s (%s)", factionName, className)
						end

						ix.util.DrawText(text, x, y - size, ColorAlpha(drawColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, nil, alpha)
					end
				end
			end

			local territoryPlugin = ix.plugin.list["territorycontrol"]

			if (territoryPlugin and territoryPlugin.GetTerritorySpawns) then
				for _, spawnData in pairs(territoryPlugin:GetTerritorySpawns()) do
					if (!spawnData.pos) then
						continue
					end

					local distance = clientPos:Distance(spawnData.pos)
					if (distance > dimDistance * 4) then
						continue
					end

					local screenPosition = spawnData.pos:ToScreen()
					if (!screenPosition.visible) then
						continue
					end

					local x, y = screenPosition.x, screenPosition.y
					local factor = 1 - math.Clamp(distance / dimDistance, 0, 1)
					local size = math.max(12, 28 * factor)
					local alpha = math.max(255 * factor, 80)
					local teamName = territoryPlugin.GetCaptureTeamName and territoryPlugin:GetCaptureTeamName(spawnData.teamID, client) or spawnData.teamID
					local areaName = territoryPlugin.GetAreaName and (territoryPlugin:GetAreaName(spawnData.areaID) or spawnData.areaID) or spawnData.areaID
					local drawColor = territoryPlugin.GetCaptureTeamColor and territoryPlugin:GetCaptureTeamColor(spawnData.teamID) or territoryMarkerColor
					local label = L("territorySpawnLabel", client, teamName, areaName)

					DrawSpawnMarker(x, y, size, drawColor, alpha)
					ix.util.DrawText(label, x, y - size, ColorAlpha(drawColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, nil, alpha)
				end
			end
		end
	end
end
