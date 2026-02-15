
local PLUGIN = PLUGIN

PLUGIN.name = "Observer Spawns"
PLUGIN.author = "Frosty with Antigravity"
PLUGIN.description = "Displays spawn points while in observer mode."


if (SERVER) then
	util.AddNetworkString("ixSpawnSync")

	function PLUGIN:SyncSpawns(client)
		local spawnsPlugin = ix.plugin.list["spawns"]
		if (!spawnsPlugin) then return end

		net.Start("ixSpawnSync")
			net.WriteTable(spawnsPlugin.spawns or {})
		if (client) then
			net.Send(client)
		else
			local admins = {}
			for _, v in player.Iterator() do
				if (CAMI.PlayerHasAccess(v, "Helix - Observer", nil)) then
					admins[#admins + 1] = v
				end
			end

			if (#admins > 0) then
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
else
	PLUGIN.spawns = {}

	net.Receive("ixSpawnSync", function()
		PLUGIN.spawns = net.ReadTable()
	end)

	local dimDistance = 1024

	function PLUGIN:HUDPaint()
		local client = LocalPlayer()

		if (ix.option.Get("observerESP", true) and client:GetMoveType() == MOVETYPE_NOCLIP and
			!client:InVehicle() and CAMI.PlayerHasAccess(client, "Helix - Observer", nil)) then
			
			local clientPos = client:GetPos()
			local scrW, scrH = ScrW(), ScrH()
			local marginX, marginY = scrH * .1, scrH * .1

			for factionID, classes in pairs(self.spawns) do
				local faction = ix.faction.teams[factionID]
				local factionColor = faction and faction.color or color_white
				local factionName = faction and L(faction.name) or factionID

				for classID, points in pairs(classes) do
					local class = ix.class.list[classID]
					local className = class and L(class.name) or classID

					for _, pos in pairs(points) do
						local distance = clientPos:Distance(pos)
						if (distance > dimDistance * 2) then continue end

						local screenPosition = pos:ToScreen()
						if (!screenPosition.visible) then continue end

						local x, y = math.Clamp(screenPosition.x, marginX, scrW - marginX), math.Clamp(screenPosition.y, marginY, scrH - marginY)
						
						local factor = 1 - math.Clamp(distance / dimDistance, 0, 1)
						local size = math.max(10, 32 * factor)
						local alpha = math.max(255 * factor, 80)

						surface.SetDrawColor(factionColor.r, factionColor.g, factionColor.b, alpha)
						surface.DrawOutlinedRect(x - size / 2, y - size / 2, size, size)
						surface.DrawOutlinedRect(x - size / 2 + 1, y - size / 2 + 1, size - 2, size - 2)

						local text = factionName

						if (classID != "default" and className:lower() != "default") then
							text = string.format("%s (%s)", factionName, className)
						end
						surface.SetFont("ixGenericFont")
						local textWidth, textHeight = surface.GetTextSize(text)

						ix.util.DrawText(text, x, y - size, ColorAlpha(factionColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, nil, alpha)
					end
				end
			end
		end
	end
end
