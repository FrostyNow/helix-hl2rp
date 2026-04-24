local PLUGIN = PLUGIN

util.AddNetworkString("ixNpcSpawnerEdit")
util.AddNetworkString("ixNpcSpawnerSync")

local GUNSHIP_COMBAT_RADIUS = 3000
local GUNSHIP_TRACK_PREFIX = "ix_gstrk_"

local function GetFlightAltitude(pos)
	local groundTr = util.TraceLine({
		start = pos + Vector(0, 0, 50),
		endpos = pos - Vector(0, 0, 16384),
		mask = MASK_SOLID_BRUSHONLY
	})
	local groundZ = groundTr.Hit and groundTr.HitPos.z or (pos.z - 500)

	local skyTr = util.TraceLine({
		start = pos + Vector(0, 0, 50),
		endpos = pos + Vector(0, 0, 16384),
		mask = MASK_SOLID_BRUSHONLY
	})
	local skyZ = skyTr.Hit and skyTr.HitPos.z or (pos.z + 3000)

	return groundZ + (skyZ - groundZ) * 0.4
end

local function CheckSegmentClear(a, b, mins, maxs)
	local tr = util.TraceHull({
		start = a,
		endpos = b,
		mins = mins,
		maxs = maxs,
		mask = MASK_SOLID_BRUSHONLY
	})
	return not tr.Hit
end

local function FindGunshipRoute(targetPos, flightZ, mins, maxs)
	local hoverPos = targetPos + Vector(0, 0, 350)
	local allPlayers = player.GetAll()
	local bestRoute = nil

	for i = 1, 8 do
		local angle = math.rad((i - 1) * 45 + math.random(0, 44))
		local dir = Vector(math.cos(angle), math.sin(angle), 0)

		-- 비행 고도에서 맵 가장자리까지 trace
		local traceOrigin = Vector(targetPos.x, targetPos.y, flightZ)
		local edgeTr = util.TraceLine({
			start = traceOrigin,
			endpos = traceOrigin + dir * 32768,
			mask = MASK_SOLID_BRUSHONLY
		})

		local spawnPos
		if edgeTr.Hit then
			spawnPos = edgeTr.HitPos - dir * 300
		else
			spawnPos = traceOrigin + dir * 8000
		end
		spawnPos.z = flightZ

		-- 플레이어 시야 확인
		local visible = false
		for _, ply in ipairs(allPlayers) do
			if (not ply:Alive() or not ply:GetCharacter()) then continue end
			local visTr = util.TraceLine({
				start = ply:EyePos(),
				endpos = spawnPos,
				filter = ply,
				mask = MASK_VISIBLE
			})
			if (not visTr.Hit) then
				visible = true
				break
			end
		end

		-- 중간 웨이포인트 2개 배치 후 건쉽 히트박스 기준 경로 검증
		local wp1Base = LerpVector(0.33, spawnPos, hoverPos)
		local wp2Base = LerpVector(0.66, spawnPos, hoverPos)

		local routeWP1, routeWP2
		local routeValid = false

		for attempt = 0, 5 do
			local zOffset = attempt * 200
			local wp1 = Vector(wp1Base.x, wp1Base.y, flightZ + zOffset)
			local wp2 = Vector(wp2Base.x, wp2Base.y, flightZ + zOffset)

			if CheckSegmentClear(spawnPos, wp1, mins, maxs) and
			   CheckSegmentClear(wp1, wp2, mins, maxs) and
			   CheckSegmentClear(wp2, hoverPos, mins, maxs) then
				routeWP1 = wp1
				routeWP2 = wp2
				routeValid = true
				break
			end
		end

		if routeValid then
			local route = {
				spawnPos = spawnPos,
				waypoints = {routeWP1, routeWP2, hoverPos},
				visible = visible,
			}
			if (not visible) then return route end
			if (not bestRoute) then bestRoute = route end
		end
	end

	return bestRoute
end

function PLUGIN:CallFlyBy(targetPos, class)
	-- 실제 collision bounds 추출
	local tempEnt = ents.Create(class)
	tempEnt:SetPos(targetPos + Vector(0, 0, 8192))
	tempEnt:Spawn()
	local mins, maxs = tempEnt:GetCollisionBounds()
	tempEnt:Remove()

	local flightZ = GetFlightAltitude(targetPos)
	local route = FindGunshipRoute(targetPos, flightZ, mins, maxs)
	if (not route) then return false end

	-- path_track 체인 생성
	local uid = tostring(math.random(100000, 999999))
	local trackEnts = {}

	for idx, wp in ipairs(route.waypoints) do
		local track = ents.Create("path_track")
		track:SetPos(wp)
		track:SetName(GUNSHIP_TRACK_PREFIX .. uid .. "_" .. idx)
		local nextName = GUNSHIP_TRACK_PREFIX .. uid .. "_" .. (idx + 1)
		if (idx < #route.waypoints) then
			track:SetKeyValue("target", nextName)
		end
		track:Spawn()
		track:Activate()
		table.insert(trackEnts, track)
	end

	-- NPC 소환
	local npc = ents.Create(class)
	npc:SetPos(route.spawnPos)
	npc:SetKeyValue("target", GUNSHIP_TRACK_PREFIX .. uid .. "_1")
	npc:Spawn()
	npc:Activate()
	npc:Fire("OmniscientOff", "", 0)

	npc.ixGunshipTargetPos = targetPos

	local timerId = "ixFlyBy_" .. npc:EntIndex()
	local function CleanupTracks()
		for _, track in ipairs(trackEnts) do
			if (IsValid(track)) then track:Remove() end
		end
	end

	timer.Create(timerId, 0.5, 0, function()
		if (not IsValid(npc)) then
			CleanupTracks()
			timer.Remove(timerId)
			return
		end

		if (npc:GetPos():Distance(targetPos) <= GUNSHIP_COMBAT_RADIUS) then
			npc.ixGunshipTargetPos = nil
			CleanupTracks()
			timer.Remove(timerId)
		end
	end)

	return true
end

hook.Add("NPC_SeeEntity", "ixGunshipCombatSuppress", function(npc, entity)
	if (npc.ixGunshipTargetPos and npc:GetPos():Distance(npc.ixGunshipTargetPos) > GUNSHIP_COMBAT_RADIUS) then
		return false
	end
end)

function PLUGIN:AddSpawner(id, pos, template)
	if template then
		self.spawners[id] = {
			pos = pos,
			classes = table.Copy(template.classes or {}),
			maxSpawned = template.maxSpawned,
			maxNearby = template.maxNearby,
			spawnDelay = template.spawnDelay,
			minDistance = template.minDistance,
			activeRadius = template.activeRadius or 3000,
			useArea = template.useArea or false,
			visitCooldown = template.visitCooldown or 0,
			lastSpawn = 0,
			lastVisited = 0,
			spawnedNPCs = {}
		}
	else
		self.spawners[id] = {
			pos = pos,
			classes = {},
			maxSpawned = 5,
			maxNearby = 10,
			spawnDelay = 60,
			minDistance = 1000,
			activeRadius = 3000,
			useArea = false,
			visitCooldown = 0,
			lastSpawn = 0,
			lastVisited = 0,
			spawnedNPCs = {}
		}
	end

	self:SaveSpawners()
	self:SyncSpawners()
end

function PLUGIN:RemoveSpawner(id)
	self.spawners[id] = nil
	self:SaveSpawners()
	self:SyncSpawners()
end

function PLUGIN:SaveSpawners()
	local data = {}
	for id, spawner in pairs(self.spawners) do
		data[id] = {
			pos = spawner.pos,
			classes = spawner.classes,
			maxSpawned = spawner.maxSpawned,
			maxNearby = spawner.maxNearby,
			spawnDelay = spawner.spawnDelay,
			minDistance = spawner.minDistance,
			activeRadius = spawner.activeRadius,
			useArea = spawner.useArea,
			visitCooldown = spawner.visitCooldown
		}
	end
	self:SetData(data)
end

function PLUGIN:LoadData()
	local data = self:GetData() or {}
	for id, spawner in pairs(data) do
		self.spawners[id] = {
			pos = spawner.pos,
			classes = spawner.classes or {},
			maxSpawned = spawner.maxSpawned or 5,
			maxNearby = spawner.maxNearby or 10,
			spawnDelay = spawner.spawnDelay or 60,
			minDistance = spawner.minDistance or 1000,
			activeRadius = spawner.activeRadius or 3000,
			useArea = spawner.useArea or false,
			visitCooldown = spawner.visitCooldown or 0,
			lastSpawn = 0,
			lastVisited = 0,
			spawnedNPCs = {}
		}
	end
end

function PLUGIN:SyncSpawners(client)
	local data = {}
	for id, spawner in pairs(self.spawners) do
		data[id] = {
			pos = spawner.pos,
			classes = spawner.classes,
			maxSpawned = spawner.maxSpawned,
			maxNearby = spawner.maxNearby,
			spawnDelay = spawner.spawnDelay,
			minDistance = spawner.minDistance,
			activeRadius = spawner.activeRadius,
			useArea = spawner.useArea,
			visitCooldown = spawner.visitCooldown
		}
	end

	net.Start("ixNpcSpawnerSync")
	net.WriteTable(data)
	if (client) then
		net.Send(client)
	else
		net.Broadcast()
	end
end

function PLUGIN:PlayerInitialSpawn(client)
	self:SyncSpawners(client)
end

net.Receive("ixNpcSpawnerEdit", function(len, client)
	if (not client:IsSuperAdmin()) then return end

	local id = net.ReadString()
	local data = net.ReadTable()

	if (PLUGIN.spawners[id]) then
		PLUGIN.spawners[id].classes = data.classes
		PLUGIN.spawners[id].maxSpawned = data.maxSpawned
		PLUGIN.spawners[id].maxNearby = data.maxNearby
		PLUGIN.spawners[id].spawnDelay = data.spawnDelay
		PLUGIN.spawners[id].minDistance = data.minDistance
		PLUGIN.spawners[id].activeRadius = data.activeRadius
		PLUGIN.spawners[id].useArea = data.useArea or false
		PLUGIN.spawners[id].visitCooldown = data.visitCooldown or 0
		
		PLUGIN:SaveSpawners()
		PLUGIN:SyncSpawners()
		client:NotifyLocalized("spawnerEditedMsg")
	end
end)

function PLUGIN:GetGlobalNPCCount()
	local count = 0
	for _, ent in ipairs(ents.FindByClass("npc_*")) do
		if (ent:IsNPC() and not ent.ixIgnoreSpawner) then
			count = count + 1
		end
	end
	return count
end

function PLUGIN:IsNPCSafeToRemove(npc)
	local npcPos = npc:GetPos()

	local enemy = npc:GetEnemy()
	if (IsValid(enemy) and enemy:IsPlayer()) then return false end

	for _, ply in ipairs(player.GetAll()) do
		if (not ply:Alive() or not ply:GetCharacter() or ply:GetMoveType() == MOVETYPE_NOCLIP) then continue end

		if (ply:GetPos():Distance(npcPos) < 1500) then return false end

		local eyePos = ply:EyePos()
		local tr = util.TraceLine({start = eyePos, endpos = npcPos, filter = ply})
		if (not tr.HitWorld) then
			local dot = ply:GetAimVector():Dot((npcPos - eyePos):GetNormalized())
			if (dot > 0.5) then return false end
		end
	end

	return true
end

function PLUGIN:GetNearbyNPCCount(pos, radius)
	local count = 0
	for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
		if (ent:IsNPC() and not ent.ixIgnoreSpawner) then
			count = count + 1
		end
	end
	return count
end

local VISIT_PROXIMITY = 400

function PLUGIN:IsPlayerVisitingSpawner(spawner)
	for _, ply in ipairs(player.GetAll()) do
		if (not ply:Alive() or not ply:GetCharacter() or ply:GetMoveType() == MOVETYPE_NOCLIP) then continue end

		local dist = ply:GetPos():Distance(spawner.pos)

		if (dist <= VISIT_PROXIMITY) then return true end

		if (dist <= spawner.minDistance) then
			local eyePos = ply:EyePos()
			local tr = util.TraceLine({start = eyePos, endpos = spawner.pos, filter = ply})
			if (not tr.HitWorld) then
				local dot = ply:GetAimVector():Dot((spawner.pos - eyePos):GetNormalized())
				if (dot > 0.7) then return true end
			end
		end
	end
	return false
end

function PLUGIN:IsPlayerLookingOrNear(pos, minDistance)
	for _, ply in ipairs(player.GetAll()) do
		if (not ply:Alive() or not ply:GetCharacter() or ply:GetMoveType() == MOVETYPE_NOCLIP) then continue end
		
		local dist = ply:GetPos():Distance(pos)
		if (dist < minDistance) then
			return true
		end
		
		local tr = util.TraceLine({
			start = ply:EyePos(),
			endpos = pos,
			filter = ply
		})
		
		if (not tr.HitWorld) then 
			local aimVec = ply:GetAimVector()
			local dirToPos = (pos - ply:EyePos()):GetNormalized()
			local dot = aimVec:Dot(dirToPos)
			if (dot > 0.7) then
				return true
			end
		end
	end
	return false
end

function PLUGIN:SelectRandomClass(classes)
	local totalWeight = 0
	for _, weight in pairs(classes) do
		totalWeight = totalWeight + tonumber(weight)
	end
	
	if totalWeight <= 0 then return nil end
	
	local r = math.random() * totalWeight
	local current = 0
	for class, weight in pairs(classes) do
		current = current + tonumber(weight)
		if r <= current then
			return class
		end
	end
end

function PLUGIN:FindValidSpawnPos(pos, class)
	local function IsInWater(checkPos)
		-- Check for water in the immediate vicinity of the position
		local contents = util.PointContents(checkPos)
		if (bit.band(contents, CONTENTS_WATER) != 0) then return true end
		
		-- Also check a bit below to be sure
		local contentsBelow = util.PointContents(checkPos - Vector(0, 0, 10))
		return bit.band(contentsBelow, CONTENTS_WATER) != 0
	end

	local function IsEmpty(checkPos)
		if (IsInWater(checkPos)) then return false end

		local tr = util.TraceHull({
			start = checkPos + Vector(0, 0, 10),
			endpos = checkPos + Vector(0, 0, 10),
			mins = Vector(-16, -16, 0),
			maxs = Vector(16, 16, 72),
			mask = MASK_NPCSOLID
		})
		return not tr.Hit
	end

	if (class == "npc_barnacle") then
		local upTr = util.TraceLine({
			start = pos,
			endpos = pos + Vector(0, 0, 500),
			mask = MASK_SOLID_BRUSHONLY
		})
		
		if upTr.Hit then
			return upTr.HitPos - Vector(0, 0, 5)
		end
		return nil
	end

	-- Try to snap the base position to the actual floor first
	local groundTr = util.TraceLine({
		start = pos + Vector(0, 0, 64),
		endpos = pos - Vector(0, 0, 256),
		mask = MASK_NPCSOLID_BRUSHONLY
	})

	if (groundTr.Hit and !IsInWater(groundTr.HitPos)) then
		local finalPos = groundTr.HitPos + Vector(0, 0, 15) -- Spawn 15 units above ground
		if (IsEmpty(finalPos)) then
			return finalPos
		end
	end

	-- Fallback to original position (with elevation)
	local elevatedPos = pos + Vector(0, 0, 15)
	if (IsEmpty(elevatedPos)) then return elevatedPos end

	-- Search nearby
	for i = 1, 15 do
		local rad = math.rad(math.random(0, 360))
		local dist = math.random(40, 200)
		local offset = pos + Vector(math.cos(rad) * dist, math.sin(rad) * dist, 64)
		
		local dropTr = util.TraceLine({
			start = offset,
			endpos = offset - Vector(0, 0, 400),
			mask = MASK_NPCSOLID_BRUSHONLY
		})
		
		if (dropTr.Hit and !IsInWater(dropTr.HitPos)) then
			local finalPos = dropTr.HitPos + Vector(0, 0, 15) -- Spawn 15 units above ground
			if (IsEmpty(finalPos)) then
				return finalPos
			end
		end
	end
	
	return nil
end

function PLUGIN:Think()
	if ((self.nextSpawnCheck or 0) > CurTime()) then return end
	self.nextSpawnCheck = CurTime() + 2

	local globalLimit = ix.config.Get("npcSpawnerGlobalLimit", 50)
	local globalCount = self:GetGlobalNPCCount()

	for id, spawner in pairs(self.spawners) do
		local hasNearbyPlayer = false
		if (spawner.useArea and ix.area and ix.area.stored) then
			for _, area in pairs(ix.area.stored) do
				if (spawner.pos:WithinAABox(area.startPosition, area.endPosition)) then
					for _, ply in ipairs(player.GetAll()) do
						if (not ply:Alive() or not ply:GetCharacter() or ply:GetMoveType() == MOVETYPE_NOCLIP) then continue end
						if ((ply:GetPos() + ply:OBBCenter()):WithinAABox(area.startPosition, area.endPosition)) then
							hasNearbyPlayer = true
							break
						end
					end
					break
				end
			end
		else
			local activeRadius = spawner.activeRadius or 3000
			for _, ply in ipairs(player.GetAll()) do
				if (not ply:Alive() or not ply:GetCharacter() or ply:GetMoveType() == MOVETYPE_NOCLIP) then continue end
				if (ply:GetPos():Distance(spawner.pos) <= activeRadius) then
					hasNearbyPlayer = true
					break
				end
			end
		end

		local now = CurTime()
		local inVisitCooldown = spawner.visitCooldown > 0 and (now < (spawner.lastVisited + spawner.visitCooldown))

		local activeNPCs = 0
		local newSpawned = {}
		for _, ent in ipairs(spawner.spawnedNPCs) do
			if (IsValid(ent) and ent:IsNPC() and ent:Health() > 0) then
				local shouldRemove = false

				if (Schema.npcClassLists.scared[ent:GetClass()] and !self:IsPlayerLookingOrNear(ent:GetPos(), spawner.minDistance)) then
					shouldRemove = true
				end

				if (not hasNearbyPlayer and not inVisitCooldown and self:IsNPCSafeToRemove(ent)) then
					shouldRemove = true
				end

				if (shouldRemove) then
					ent:Remove()
					continue
				end

				activeNPCs = activeNPCs + 1
				table.insert(newSpawned, ent)
			end
		end
		spawner.spawnedNPCs = newSpawned

		if (activeNPCs > 0 and spawner.visitCooldown > 0 and self:IsPlayerVisitingSpawner(spawner)) then
			spawner.lastVisited = now
		end

		if (not hasNearbyPlayer) then continue end
		if (inVisitCooldown) then continue end
		if (globalCount >= globalLimit) then continue end
		if ((spawner.lastSpawn + spawner.spawnDelay) > CurTime()) then continue end
		if (activeNPCs >= spawner.maxSpawned) then continue end

		local nearbyCount = self:GetNearbyNPCCount(spawner.pos, 1000)
		if (nearbyCount >= spawner.maxNearby) then continue end

		if (self:IsPlayerLookingOrNear(spawner.pos, spawner.minDistance)) then continue end

		local class = self:SelectRandomClass(spawner.classes)
		if (not class) then continue end

		local spawnPos = self:FindValidSpawnPos(spawner.pos, class)
		if (not spawnPos) then continue end

		if (class == "npc_barnacle") then
			local bBlocked = false
			for _, ent in ipairs(ents.FindInSphere(spawnPos, 32)) do
				if (ent:GetClass() == "npc_barnacle" and ent:Health() <= 0) then
					bBlocked = true
					break
				end
			end
			if (bBlocked) then continue end
		end

		local ent = ents.Create(class)
		if (IsValid(ent)) then
			local flags = 1
			if (class == "npc_barnacle" and math.random(1, 100) <= 30) then
				flags = flags + 131072
			elseif (class == "npc_combine_s") then
				flags = flags + 65536
			end
			ent:SetKeyValue("spawnflags", flags)

			ent:SetPos(spawnPos)
			ent:Spawn()
			ent:Activate()

			table.insert(spawner.spawnedNPCs, ent)
			spawner.lastSpawn = CurTime()

			globalCount = globalCount + 1
		end
	end
end
