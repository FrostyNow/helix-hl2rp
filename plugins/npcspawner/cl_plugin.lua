local PLUGIN = PLUGIN

ix.util.Include("derma/cl_spawner.lua")

-- Dropship / APC placement mode ------------------------------------------------
local dsPlacement = {
	active    = false,
	type      = "dropship",  -- "dropship" | "apc"
	count     = 0,
	landPos   = nil,
	landYaw   = 0,
}

local CONTAINER_HALF_LEN = 150
local CONTAINER_HALF_WID = 80
local APC_HALF_LEN       = 200
local APC_HALF_WID       = 110
local PLACEMENT_COLOR     = Color(100, 220, 255, 180)
local PLACEMENT_APC_COLOR = Color(255, 160, 60, 180)
local PLACEMENT_ARROW_COL = Color(255, 220, 60, 220)
local PLACEMENT_FILL_COL  = Color(60, 140, 200, 40)
local PLACEMENT_APC_FILL  = Color(200, 100, 40, 40)

local function DrawPlacementGhost(pos, yaw)
	local rad   = math.rad(yaw)
	local fwd   = Vector(math.cos(rad), math.sin(rad), 0)
	local right = Vector(-fwd.y, fwd.x, 0)
	local zOff  = Vector(0, 0, 2)

	render.SetColorMaterial()

	if (dsPlacement.type == "apc") then
		-- APC footprint: larger rectangle, no directional arrow (landing yaw is engine-determined)
		local corners = {
			pos + fwd * APC_HALF_LEN + right * APC_HALF_WID + zOff,
			pos + fwd * APC_HALF_LEN - right * APC_HALF_WID + zOff,
			pos - fwd * APC_HALF_LEN - right * APC_HALF_WID + zOff,
			pos - fwd * APC_HALF_LEN + right * APC_HALF_WID + zOff,
		}
		render.DrawQuad(corners[1], corners[2], corners[3], corners[4], PLACEMENT_APC_FILL)
		for i = 1, 4 do
			render.DrawLine(corners[i], corners[i % 4 + 1], PLACEMENT_APC_COLOR, false)
		end
		-- crosshair at center
		render.DrawLine(pos + fwd * 60 + zOff, pos - fwd * 60 + zOff, PLACEMENT_APC_COLOR, false)
		render.DrawLine(pos + right * 60 + zOff, pos - right * 60 + zOff, PLACEMENT_APC_COLOR, false)
	else
		-- dropship container footprint with door-direction arrow
		local corners = {
			pos + fwd * CONTAINER_HALF_LEN + right * CONTAINER_HALF_WID + zOff,
			pos + fwd * CONTAINER_HALF_LEN - right * CONTAINER_HALF_WID + zOff,
			pos - fwd * CONTAINER_HALF_LEN - right * CONTAINER_HALF_WID + zOff,
			pos - fwd * CONTAINER_HALF_LEN + right * CONTAINER_HALF_WID + zOff,
		}
		render.DrawQuad(corners[1], corners[2], corners[3], corners[4], PLACEMENT_FILL_COL)
		for i = 1, 4 do
			render.DrawLine(corners[i], corners[i % 4 + 1], PLACEMENT_COLOR, false)
		end
		local arrowTip = pos + fwd * (CONTAINER_HALF_LEN + 60) + zOff
		local arrowL   = arrowTip - fwd * 40 + right * 25 + zOff
		local arrowR   = arrowTip - fwd * 40 - right * 25 + zOff
		render.DrawLine(pos + zOff, arrowTip, PLACEMENT_ARROW_COL, false)
		render.DrawLine(arrowTip, arrowL, PLACEMENT_ARROW_COL, false)
		render.DrawLine(arrowTip, arrowR, PLACEMENT_ARROW_COL, false)
	end
end

net.Receive("ixDropshipPlacement", function()
	dsPlacement.count  = net.ReadInt(4)
	dsPlacement.type   = "dropship"
	dsPlacement.active = true
end)

net.Receive("ixDropshipAPCPlacement", function()
	dsPlacement.type   = "apc"
	dsPlacement.active = true
end)

hook.Add("PostDrawTranslucentRenderables", "ixDropshipPlacementGhost", function()
	if (not dsPlacement.active) then return end
	if (not dsPlacement.landPos) then return end
	DrawPlacementGhost(dsPlacement.landPos, dsPlacement.landYaw)
end)

hook.Add("Think", "ixDropshipPlacementTrace", function()
	if (not dsPlacement.active) then return end

	local client = LocalPlayer()
	local tr = util.TraceLine({
		start  = client:EyePos(),
		endpos = client:EyePos() + client:GetAimVector() * 8192,
		filter = client,
		mask   = MASK_SOLID_BRUSHONLY,
	})

	if (tr.Hit) then
		dsPlacement.landPos = tr.HitPos
		dsPlacement.landYaw = client:EyeAngles().y
	end
end)

local function ConfirmPlacement()
	if (not dsPlacement.active or not dsPlacement.landPos) then return end
	if (dsPlacement.type == "apc") then
		net.Start("ixDropshipAPCPlacementResult")
		net.WriteBool(true)
		net.WriteVector(dsPlacement.landPos)
	else
		net.Start("ixDropshipPlacementResult")
		net.WriteBool(true)
		net.WriteInt(dsPlacement.count, 4)
		net.WriteVector(dsPlacement.landPos)
		net.WriteFloat(dsPlacement.landYaw)
	end
	net.SendToServer()
	dsPlacement.active  = false
	dsPlacement.landPos = nil
end

local function CancelPlacement()
	if (not dsPlacement.active) then return end
	if (dsPlacement.type == "apc") then
		net.Start("ixDropshipAPCPlacementResult")
		net.WriteBool(false)
	else
		net.Start("ixDropshipPlacementResult")
		net.WriteBool(false)
		net.WriteInt(dsPlacement.count, 4)
	end
	net.SendToServer()
	dsPlacement.active  = false
	dsPlacement.landPos = nil
end

hook.Add("PlayerBindPress", "ixDropshipPlacementInput", function(client, bind, pressed)
	if (not dsPlacement.active or not pressed) then return end

	if (bind == "+attack") then
		ConfirmPlacement()
		return true
	elseif (bind == "+attack2" or bind == "cancelselect") then
		CancelPlacement()
		return true
	end
end)

hook.Add("HUDPaint", "ixDropshipPlacementHint", function()
	if (not dsPlacement.active) then return end
	local key  = dsPlacement.type == "apc" and "dropshipAPCPlacementMode" or "dropshipPlacementMode"
	local col  = dsPlacement.type == "apc" and Color(255, 160, 60, 230) or Color(100, 220, 255, 230)
	draw.SimpleText(L(key), "DermaDefaultBold", ScrW() * 0.5, ScrH() * 0.1, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
--------------------------------------------------------------------------------

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


-- FlyBy route visualisation (admin + noclip + not in vehicle only) --------------
local flyByRoutes = {}  -- [entIndex] = { entIndex, spawnPos, approach[], patrol[] }

net.Receive("ixFlyByRoute", function()
	local entIndex  = net.ReadInt(16)
	local spawnPos  = net.ReadVector()
	local approachN = net.ReadUInt(4)
	local approach  = {}
	for i = 1, approachN do approach[i] = net.ReadVector() end
	local patrolN   = net.ReadUInt(8)
	local patrol    = {}
	for i = 1, patrolN do patrol[i] = net.ReadVector() end

	flyByRoutes[entIndex] = {
		entIndex    = entIndex,
		spawnPos    = spawnPos,
		approach    = approach,
		patrol      = patrol,
		receiveTime = RealTime(),
	}
end)

hook.Add("Think", "ixFlyByRouteCleanup", function()
	local now = RealTime()
	for idx, r in pairs(flyByRoutes) do
		if (now - r.receiveTime > 2 and not IsValid(Entity(r.entIndex))) then
			flyByRoutes[idx] = nil
		end
	end
end)

local ROUTE_APPROACH_COLOR   = Color(255, 200, 60,  255)
local ROUTE_TRANSITION_COLOR = Color(255, 120, 60,  200)
local ROUTE_PATROL_COLOR     = Color(60,  200, 255, 255)
local ROUTE_NPC_COLOR        = Color(255, 80,  80,  255)

hook.Add("PostDrawTranslucentRenderables", "ixFlyByRouteVis", function()
	local client = LocalPlayer()
	if (not client:IsAdmin() or client:InVehicle() or client:GetMoveType() ~= MOVETYPE_NOCLIP) then return end
	if (not next(flyByRoutes)) then return end

	render.SetColorMaterial()

	for _, r in pairs(flyByRoutes) do
		-- approach: spawnPos → wp1 → wp2 → hoverPos
		local prev = r.spawnPos
		for _, wp in ipairs(r.approach) do
			render.DrawLine(prev, wp, ROUTE_APPROACH_COLOR, false)
			prev = wp
		end

		-- transition: hoverPos → patrol[1]
		if (r.patrol[1]) then
			render.DrawLine(prev, r.patrol[1], ROUTE_TRANSITION_COLOR, false)
		end

		-- patrol loop using actual node positions
		local pCount = #r.patrol
		for i = 1, pCount do
			render.DrawLine(r.patrol[i], r.patrol[(i % pCount) + 1], ROUTE_PATROL_COLOR, false)
		end

		-- NPC position cross
		local npc = Entity(r.entIndex)
		if (IsValid(npc)) then
			local p = npc:GetPos()
			render.DrawLine(p - Vector(0, 0, 60), p + Vector(0, 0, 60), ROUTE_NPC_COLOR, false)
			render.DrawLine(p - Vector(60, 0, 0), p + Vector(60, 0, 0), ROUTE_NPC_COLOR, false)
			render.DrawLine(p - Vector(0, 60, 0), p + Vector(0, 60, 0), ROUTE_NPC_COLOR, false)
		end
	end
end)
--------------------------------------------------------------------------------

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
