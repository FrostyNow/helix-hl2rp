local PLUGIN = PLUGIN

ix.util.Include("derma/cl_spawner.lua")

net.Receive("ixNpcSpawnerSync", function()
	PLUGIN.spawners = net.ReadTable()
end)

net.Receive("ixNpcSpawnerEdit", function()
	local id = net.ReadString()
	local data = net.ReadTable()
	
	if (IsValid(ix.gui.npcSpawnerEdit)) then
		ix.gui.npcSpawnerEdit:Remove()
	end
	
	ix.gui.npcSpawnerEdit = vgui.Create("ixNpcSpawnerEdit")
	ix.gui.npcSpawnerEdit:SetSpawner(id, data)
end)

local CIRCLE_SEGMENTS = 64
local CIRCLE_COLOR = Color(100, 200, 255, 200)
local MIN_DIST_COLOR = Color(255, 80, 80, 200)

local function DrawCircle(center, radius, color)
	local prev = nil
	for i = 0, CIRCLE_SEGMENTS do
		local angle = (i / CIRCLE_SEGMENTS) * math.pi * 2
		local point = center + Vector(math.cos(angle) * radius, math.sin(angle) * radius, 0)
		if (prev) then
			render.DrawLine(prev, point, color, false)
		end
		prev = point
	end
end

hook.Add("PostDrawTranslucentRenderables", "ixNpcSpawnerActiveRadius", function()
	if (not ix.option.Get("npcSpawnerESP", true)) then return end

	local client = LocalPlayer()
	if (not client:IsAdmin() or client:InVehicle() or client:GetMoveType() ~= MOVETYPE_NOCLIP) then return end

	local eyePos = client:EyePos()
	local aimVec = client:GetAimVector()
	local bestDot = 0.97
	local bestSpawner = nil

	for id, spawner in pairs(PLUGIN.spawners or {}) do
		local dist = eyePos:Distance(spawner.pos)
		if (dist > 8192) then continue end

		local dot = aimVec:Dot((spawner.pos - eyePos):GetNormalized())
		if (dot > bestDot) then
			bestDot = dot
			bestSpawner = spawner
		end
	end

	if (not bestSpawner) then return end

	render.SetColorMaterial()

	local center = bestSpawner.pos

	if (not bestSpawner.useArea) then
		DrawCircle(center, bestSpawner.activeRadius or 4500, CIRCLE_COLOR)
	end

	local minDist = bestSpawner.minDistance or 0
	if (minDist > 0) then
		DrawCircle(center, minDist, MIN_DIST_COLOR)
	end
end)

function PLUGIN:HUDPaint()
	if (not ix.option.Get("npcSpawnerESP", true)) then return end

	local client = LocalPlayer()
	if (not client:IsAdmin() or client:InVehicle() or client:GetMoveType() ~= MOVETYPE_NOCLIP) then
		return
	end

	for id, spawner in pairs(self.spawners or {}) do
		local dist = client:GetPos():Distance(spawner.pos)

		if (dist > 4096) then continue end

		local pos = spawner.pos:ToScreen()
		
		if (pos.visible) then
			if (dist < 500) then
				draw.SimpleText(L("npcSpawnerESPPrefix", id), "BudgetLabel", pos.x, pos.y, Color(255, 100, 100, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				
				local delayText = L("npcSpawnerESPInfo", spawner.spawnDelay or 0, spawner.maxSpawned or 0, spawner.maxNearby or 0)
				draw.SimpleText(delayText, "BudgetLabel", pos.x, pos.y + 15, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

				local modeText = spawner.useArea and "Area mode" or ("Radius: " .. (spawner.activeRadius or 3000))
				local cooldownText = (spawner.visitCooldown and spawner.visitCooldown > 0) and (" | Visit CD: " .. spawner.visitCooldown .. "s") or ""
				draw.SimpleText(modeText .. cooldownText, "BudgetLabel", pos.x, pos.y + 30, Color(100, 200, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

				local classLines = {L("npcSpawnerESPClasses") .. ":"}
				local count = 0
				for class, weight in pairs(spawner.classes or {}) do
					table.insert(classLines, class .. " (" .. L("spawnerColumnWeight") .. " " .. weight .. ")")
					count = count + 1
				end

				if count == 0 then
					table.insert(classLines, L("npcSpawnerESPNone"))
				end

				for i, line in ipairs(classLines) do
					draw.SimpleText(line, "BudgetLabel", pos.x, pos.y + 30 + (i * 15), Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
				end
			else
				draw.SimpleText(L("npcSpawnerESPPrefix", id), "BudgetLabel", pos.x, pos.y, Color(255, 100, 100, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end
end
