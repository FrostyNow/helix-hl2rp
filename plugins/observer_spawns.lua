
local PLUGIN = PLUGIN

PLUGIN.name = "Observer Spawns"
PLUGIN.author = "Frosty with Antigravity"
PLUGIN.description = "Displays spawn points while in observer mode."

ix.lang.AddTable("english", {
	optObserverSpawnpointESP = "Show Spawnpoint ESP",
	optdObserverSpawnpointESP = "Shows the names and locations of each faction spawnpoint in the server.",
})
ix.lang.AddTable("korean", {
	optObserverSpawnpointESP = "시작지점 ESP 보기",
	optdObserverSpawnpointESP = "서버에 있는 각 세력의 시작지점의 이름과 위치를 표시합니다.",
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

	local dimDistance = 1024

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

						surface.SetDrawColor(drawColor.r, drawColor.g, drawColor.b, alpha)
						surface.DrawOutlinedRect(x - size / 2, y - size / 2, size, size)
						surface.DrawOutlinedRect(x - size / 2 + 1, y - size / 2 + 1, size - 2, size - 2)

						local text = factionName

						if (classID != "default" and className:lower() != "default") then
							text = string.format("%s (%s)", factionName, className)
						end

						ix.util.DrawText(text, x, y - size, ColorAlpha(drawColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, nil, alpha)
					end
				end
			end
		end
	end
end
