local PLUGIN = PLUGIN

--[[
	NPC Spawner — Server Plugin
	===========================

	DROPSHIP SYSTEM — KEY DESIGN DECISIONS
	---------------------------------------

	Soldier deployment (CrateType 1 / CallDropship):
	  The npc_combinedropship NPCTemplate keyvalue does not work when set via Lua
	  (same limitation as SMOD mapadd scripts — template flag is ignored at runtime).
	  To work around this, a fake prop_dropship_container is parented to the real container
	  and the real one is hidden. The fake container plays the open/close animations and
	  soldiers are spawned manually via scripted_sequence ("Dropship_Deploy" animation).

	  IMPORTANT: the fake container must remain as a prop_dropship_container entity in the
	  world while soldiers are deploying. The dropship AI uses the presence of this entity
	  to determine whether to stay or depart — if it is removed too early, the dropship
	  leaves immediately. The fake container is world-fixed (SetParent(nil), MOVETYPE_NONE)
	  after the real container touches down, and a sway hook weakly mirrors the dropship's
	  pitch/roll to give a subtle visual connection. It is only removed after the close
	  animation finishes, at which point BeginDropshipDeparture() is called manually.

	APC deployment (CrateType -2 / CallDropshipAPC):
	  The standard LandLeaveCrate input is used (not DropAPC) so the dropship follows
	  its full landing sequence before releasing the APC. OnFinishedDropOff fires when
	  done and is caught by the EntityFireOutput hook ("ixDropshipMonitor"), which
	  initiates departure. No fake container is needed.
	  prop_vehicle_apc and npc_apcdriver must be created before the dropship spawns,
	  with no position set — the engine parents the APC to the dropship automatically
	  via the APCVehicleName keyvalue on Spawn/Activate.

	Landing yaw:
	  info_target angle controls the dropship's landing orientation. FindLandingZone
	  sweeps 8 yaw directions (45° steps) to find one where the 4m×4m area in front
	  of the dropship is flat and has sufficient soldier headroom (~108u = 1.5× soldier
	  height). APC mode skips this directional check — only the body footprint matters.

	NPC_SeeEntity / ShouldCollide hooks:
	  Deployed soldiers are flagged with ixDropshipDeployedSoldier to prevent them
	  from fighting the dropship/container they just jumped out of, and to prevent
	  mutual collision during the deploy sequence.

	Charging / ForceSpawned NPCs:
	  NPCs flagged with ixCharging or ixForceSpawned are exempt from the spawner's
	  automatic removal logic (distance / no nearby player). ixCharging is set by
	  ChargeNPCsAtPlayer; ixForceSpawned is set by ForceSpawnFromSpawner.
	  ForceRemoveIdleNPCs ignores both flags (debug/admin tool — removes everything
	  that passes IsNPCSafeToRemove, except whitelisted entities like cameras/turrets).
]]

util.AddNetworkString("ixNpcSpawnerEdit")
util.AddNetworkString("ixNpcSpawnerSync")

local GUNSHIP_COMBAT_RADIUS = 3000
local GUNSHIP_TRACK_PREFIX = "ix_gstrk_"

local DROPSHIP_TRACK_PREFIX			= "ix_dstrk_"
local DROPSHIP_TEMPL_PREFIX			= "ix_dstempl_"
local DROPSHIP_LAND_PREFIX			= "ix_dsland_"
local DROPSHIP_FLAT_RADIUS			= 150
local DROPSHIP_FLAT_TOLERANCE		= 40
local DROPSHIP_CLEARANCE			= 800
local DROPSHIP_DEPLOY_TOLERANCE		= 70   -- relaxed tolerance for dropship landing footprint
local DROPSHIP_FRONT_DEPTH			= 200  -- front flat area depth (4m ≈ 200u)
local DROPSHIP_FRONT_WIDTH			= 200  -- front flat area width (4m ≈ 200u)
local DROPSHIP_SOLDIER_CLEARANCE	= 108  -- 1.5x soldier height (72u)
local DROPSHIP_TEMPLATE_COUNT		= 6
local DROPSHIP_DEPLOY_STEP			= 0.8
local DROPSHIP_MIN_GROUND_NORMAL_Z	= 0.96

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

local function FindEdgeFlightPoint(origin, dir, flightZ, inset)
	local traceOrigin = Vector(origin.x, origin.y, flightZ)
	local edgeTr = util.TraceLine({
		start = traceOrigin,
		endpos = traceOrigin + dir * 32768,
		mask = MASK_SOLID_BRUSHONLY
	})

	local edgePos
	if edgeTr.Hit then
		edgePos = edgeTr.HitPos - dir * (inset or 300)
	else
		edgePos = traceOrigin + dir * 8000
	end

	edgePos.z = flightZ
	return edgePos
end

local function FindGunshipRoute(targetPos, flightZ, mins, maxs)
	local hoverPos = targetPos + Vector(0, 0, 350)
	local allPlayers = player.GetAll()
	local bestRoute = nil

	for i = 1, 8 do
		local angle = math.rad((i - 1) * 45 + math.random(0, 44))
		local dir = Vector(math.cos(angle), math.sin(angle), 0)

		-- trace from flight altitude to map edge
		local spawnPos = FindEdgeFlightPoint(targetPos, dir, flightZ, 300)

		-- check player visibility
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

		-- place 2 intermediate waypoints and validate route against gunship hitbox
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

-- checks flatness and soldier clearance of the 4m×4m area in front of the given yaw direction
local function CheckFrontArea(groundPos, yawDeg)
	local rad = math.rad(yawDeg)
	local fwd   = Vector(math.cos(rad), math.sin(rad), 0)
	local right = Vector(-fwd.y, fwd.x, 0)

	local halfW = DROPSHIP_FRONT_WIDTH * 0.5
	-- sample front area in a 4×3 grid (4 depth steps, 3 lateral columns)
	for di = 1, 4 do
		for wi = -1, 1 do
			local samplePos = groundPos
				+ fwd   * (di * (DROPSHIP_FRONT_DEPTH / 4))
				+ right * (wi * (halfW / 2))

			local groundTr = util.TraceLine({
				start = samplePos + Vector(0, 0, 200),
				endpos = samplePos - Vector(0, 0, 400),
				mask = MASK_SOLID_BRUSHONLY
			})
			if (not groundTr.Hit) then return false end
			if (math.abs(groundTr.HitPos.z - groundPos.z) > DROPSHIP_FLAT_TOLERANCE) then return false end

			local headTr = util.TraceLine({
				start = groundTr.HitPos + Vector(0, 0, 4),
				endpos = groundTr.HitPos + Vector(0, 0, DROPSHIP_SOLDIER_CLEARANCE),
				mask = MASK_SOLID_BRUSHONLY
			})
			if (headTr.Hit) then return false end
		end
	end

	return true
end

local function FindLandingZone(targetPos, apcMode)
	for i = 1, 16 do
		local angle = math.rad((i - 1) * 22.5 + math.random(0, 22))
		local dist = math.random(400, 2500)
		local candidate = Vector(
			targetPos.x + math.cos(angle) * dist,
			targetPos.y + math.sin(angle) * dist,
			targetPos.z
		)

		local groundTr = util.TraceLine({
			start = candidate + Vector(0, 0, 500),
			endpos = candidate - Vector(0, 0, 8192),
			mask = MASK_SOLID_BRUSHONLY
		})
		if (not groundTr.Hit) then continue end
		local groundPos = groundTr.HitPos

		-- prevent landing on water
		if (bit.band(util.PointContents(groundPos + Vector(0, 0, 2)), CONTENTS_WATER) ~= 0) then continue end
		if (groundTr.HitNormal.z < DROPSHIP_MIN_GROUND_NORMAL_Z) then continue end

		-- dropship body footprint (4 directions × 150u) — relaxed criteria
		local flat = true
		for _, offset in ipairs({
			Vector(DROPSHIP_FLAT_RADIUS, 0, 0),
			Vector(-DROPSHIP_FLAT_RADIUS, 0, 0),
			Vector(0, DROPSHIP_FLAT_RADIUS, 0),
			Vector(0, -DROPSHIP_FLAT_RADIUS, 0),
		}) do
			local cornerTr = util.TraceLine({
				start = groundPos + offset + Vector(0, 0, 200),
				endpos = groundPos + offset - Vector(0, 0, 200),
				mask = MASK_SOLID_BRUSHONLY
			})
			if (not cornerTr.Hit
				or cornerTr.HitNormal.z < DROPSHIP_MIN_GROUND_NORMAL_Z
				or math.abs(cornerTr.HitPos.z - groundPos.z) > DROPSHIP_DEPLOY_TOLERANCE) then
				flat = false
				break
			end
		end
		if (not flat) then continue end

		local clearTr = util.TraceLine({
			start = groundPos + Vector(0, 0, 10),
			endpos = groundPos + Vector(0, 0, DROPSHIP_CLEARANCE),
			mask = MASK_SOLID_BRUSHONLY
		})
		if (clearTr.Hit) then continue end

		if (apcMode) then
			return groundPos, nil
		end

		-- sweep 8 yaw directions to find one where the front 4m×4m area satisfies flatness and clearance
		local baseYaw = math.random(0, 44)
		for step = 0, 7 do
			local yaw = (baseYaw + step * 45) % 360
			if (CheckFrontArea(groundPos, yaw)) then
				return groundPos, yaw
			end
		end
	end

	return nil, nil
end

function PLUGIN:GetDropshipTemplateName(index)
	return DROPSHIP_TEMPL_PREFIX .. "global_" .. index
end

function PLUGIN:EnsureDropshipTemplates()
	self.ixDropshipTemplates = self.ixDropshipTemplates or {}

	local basePos = Vector(0, 0, -16300)

	for i = 1, DROPSHIP_TEMPLATE_COUNT do
		local templateName = self:GetDropshipTemplateName(i)
		local existing = ents.FindByName(templateName)[1]

		if (IsValid(existing)) then
			existing.ixDropshipTemplate = true
			self.ixDropshipTemplates[i] = existing
			continue
		end

		local soldier = ents.Create("npc_combine_s")
		if (not IsValid(soldier)) then
			continue
		end

		soldier.ixDropshipTemplate = true
		soldier:SetPos(basePos + Vector(i * 48, 0, 0))
		soldier:SetAngles(Angle(0, 0, 0))
		soldier:SetKeyValue("targetname", templateName)
		soldier:SetKeyValue("spawnflags", "2049")
		soldier:SetKeyValue("additionalequipment", "weapon_ar2")
		soldier:Spawn()
		soldier:Activate()
		soldier:SetName(templateName)
		soldier:SetNoDraw(true)
		soldier:AddFlags(FL_NOTARGET)

		local weapon = soldier:GetActiveWeapon()
		if (IsValid(weapon)) then
			weapon:SetNoDraw(true)
		end

		self.ixDropshipTemplates[i] = soldier
	end
end

function PLUGIN:GetDropshipDeployAttachment(dropship)
	for _, name in ipairs({
		"deploy_landpoint",
		"deploy_origin",
		"cargo",
		"body",
		"muzzle",
	}) do
		local attachmentID = dropship:LookupAttachment(name)
		if (attachmentID and attachmentID > 0) then
			local attachment = dropship:GetAttachment(attachmentID)
			if (attachment and attachment.Pos) then
				return attachment
			end
		end
	end
end

function PLUGIN:GetDropshipDeployPos(dropship, landPos, index, total)
	local mins, maxs = dropship:OBBMins(), dropship:OBBMaxs()
	local forward = dropship:GetForward()
	local right = dropship:GetRight()

	forward.z = 0
	right.z = 0

	if (forward:LengthSqr() == 0) then
		forward = Vector(1, 0, 0)
	else
		forward:Normalize()
	end

	if (right:LengthSqr() == 0) then
		right = Vector(0, 1, 0)
	else
		right:Normalize()
	end

	local laneOffset = (index - ((total + 1) * 0.5)) * 42
	local basePos

	basePos = dropship:LocalToWorld(Vector(maxs.x - 32, 0, mins.z + 18))
	basePos = basePos + forward * 26

	basePos.z = math.max(basePos.z, landPos.z + 8)

	return basePos + right * laneOffset
end

function PLUGIN:GetDropshipDeployStartPos(dropship, landPos, index, total)
	local mins, maxs = dropship:OBBMins(), dropship:OBBMaxs()
	local right = dropship:GetRight()
	local forward = dropship:GetForward()

	right.z = 0
	forward.z = 0

	if (right:LengthSqr() == 0) then
		right = Vector(0, 1, 0)
	else
		right:Normalize()
	end

	if (forward:LengthSqr() == 0) then
		forward = Vector(1, 0, 0)
	else
		forward:Normalize()
	end

	local laneOffset = (index - ((total + 1) * 0.5)) * 42
	local basePos

	basePos = dropship:LocalToWorld(Vector(maxs.x - 92, 0, mins.z + 86))
	basePos = basePos - forward * 8

	basePos.z = math.max(basePos.z, landPos.z + 52)

	return basePos + right * laneOffset
end

function PLUGIN:LookupDropshipDeploySequence(npc)
	for _, sequenceName in ipairs(DROPSHIP_DEPLOY_ANIM_CANDIDATES) do
		local sequenceID = npc:LookupSequence(sequenceName)
		if (sequenceID and sequenceID >= 0) then
			return sequenceID
		end
	end

	return nil
end

function PLUGIN:CallFlyBy(targetPos, class)
	-- get actual collision bounds
	local tempEnt = ents.Create(class)
	tempEnt:SetPos(targetPos + Vector(0, 0, 8192))
	tempEnt:Spawn()
	local mins, maxs = tempEnt:GetCollisionBounds()
	tempEnt:Remove()

	local flightZ = GetFlightAltitude(targetPos)
	local route = FindGunshipRoute(targetPos, flightZ, mins, maxs)
	if (not route) then return false end

	local PATROL_RADIUS = 2000
	local PATROL_COUNT  = 10
	local uid = tostring(math.random(100000, 999999))
	local trackEnts = {}

	-- create patrol tracks first (chain loop: p1→p2→...→p10→p1)
	-- align start angle with approach direction for a natural entry
	local approachDir = (targetPos - route.spawnPos)
	approachDir.z = 0
	approachDir:Normalize()
	local startAngle = math.atan2(approachDir.y, approachDir.x)

	local patrolTrackNames = {}
	for i = 1, PATROL_COUNT do
		patrolTrackNames[i] = GUNSHIP_TRACK_PREFIX .. uid .. "_p" .. i
	end

	for i = 1, PATROL_COUNT do
		local angle = startAngle + math.rad((i - 1) * (360 / PATROL_COUNT))
		local wp = Vector(
			targetPos.x + math.cos(angle) * PATROL_RADIUS,
			targetPos.y + math.sin(angle) * PATROL_RADIUS,
			flightZ
		)
		local track = ents.Create("path_track")
		track:SetPos(wp)
		track:SetName(patrolTrackNames[i])
		track:SetKeyValue("target", patrolTrackNames[(i % PATROL_COUNT) + 1])
		track:SetKeyValue("radius", "300")
		track:Spawn()
		track:Activate()
		table.insert(trackEnts, track)
	end

	-- approach tracks: last WP chains automatically into first patrol track
	local approachTrackNames = {}
	for idx, wp in ipairs(route.waypoints) do
		local name = GUNSHIP_TRACK_PREFIX .. uid .. "_" .. idx
		approachTrackNames[idx] = name
		local nextName = (idx < #route.waypoints) and (GUNSHIP_TRACK_PREFIX .. uid .. "_" .. (idx + 1)) or patrolTrackNames[1]

		local track = ents.Create("path_track")
		track:SetPos(wp)
		track:SetName(name)
		track:SetKeyValue("target", nextName)
		track:SetKeyValue("radius", "200")
		track:Spawn()
		track:Activate()
		table.insert(trackEnts, track)
	end

	-- spawn NPC
	local npc = ents.Create(class)
	npc:SetPos(route.spawnPos)
	npc:Spawn()
	npc:Activate()
	npc:Fire("OmniscientOff", "", 0)

	npc.ixGunshipTargetPos = targetPos

	-- start approach track chain → automatically transitions into patrol loop
	npc:Fire("FlyToSpecificTrackViaPath", approachTrackNames[1], 0.1)

	local timerId = "ixFlyBy_" .. npc:EntIndex()
	local inPatrol = false

	timer.Create(timerId, 0.5, 0, function()
		if (not IsValid(npc)) then
			for _, track in ipairs(trackEnts) do
				if (IsValid(track)) then track:Remove() end
			end
			timer.Remove(timerId)
			return
		end

		if (not inPatrol) then
			-- approaching: check for transition to patrol once within combat radius
			if (npc:GetPos():Distance(targetPos) <= GUNSHIP_COMBAT_RADIUS) then
				npc.ixGunshipTargetPos = nil
				inPatrol = true
			end
		end
	end)

	return true
end

function PLUGIN:FlyOut(originPos, radius)
	local flyOutClasses = { npc_combinegunship = true, npc_helicopter = true }
	local count = 0

	for _, npc in ipairs(ents.FindInSphere(originPos, radius or 8192)) do
		if (not IsValid(npc) or not flyOutClasses[npc:GetClass()]) then continue end

		local npcPos  = npc:GetPos()
		local exitDir = npc:GetForward()
		exitDir.z = 0
		if (exitDir:LengthSqr() < 0.01) then
			exitDir = (npcPos - originPos)
			exitDir.z = 0
		end
		if (exitDir:LengthSqr() < 0.01) then
			exitDir = Vector(1, 0, 0)
		else
			exitDir:Normalize()
		end

		-- find map boundary then extend 3000u further to place track outside the map
		local edgePos	= FindEdgeFlightPoint(npcPos, exitDir, npcPos.z, 0)
		local exitPos	= edgePos + exitDir * 3000
		local trackName	= GUNSHIP_TRACK_PREFIX .. "flyout_" .. npc:EntIndex()

		local track = ents.Create("path_track")
		track:SetPos(exitPos)
		track:SetName(trackName)
		track:SetKeyValue("radius", "500")
		track:Spawn()
		track:Activate()

		npc:Fire("FlyToSpecificTrackViaPath", trackName, 0)

		local timerId	= "ixFlyOut_" .. npc:EntIndex()
		local deadline = CurTime() + 35

		timer.Create(timerId, 0.4, 0, function()
			-- NPC already removed, just clean up track
			if (not IsValid(npc)) then
				if (IsValid(track)) then track:Remove() end
				timer.Remove(timerId)
				return
			end

			local pos = npc:GetPos()

			-- detect reaching skybox/out-of-map: if downward trace misses the world, we're outside
			local worldTr = util.TraceLine({
				start  = pos,
				endpos = pos - Vector(0, 0, 4096),
				mask   = MASK_SOLID_BRUSHONLY
			})
			local outOfWorld = not worldTr.Hit

			-- out of map, near exitPos, or timed out
			if (outOfWorld
				or pos:DistToSqr(exitPos) <= (800 * 800)
				or CurTime() >= deadline) then
				npc:Remove()
				if (IsValid(track)) then track:Remove() end
				timer.Remove(timerId)
				return
			end

			-- re-fire to maintain path
			npc:Fire("FlyToSpecificTrackViaPath", trackName, 0)
		end)

		count = count + 1
	end

	return count
end

function PLUGIN:CallDropship(targetPos, soldierCount)
	local tempEnt = ents.Create("npc_combinedropship")
	tempEnt:SetPos(targetPos + Vector(0, 0, 8192))
	tempEnt:Spawn()
	local mins, maxs = tempEnt:GetCollisionBounds()
	tempEnt:Remove()

	local landPos, landYaw = FindLandingZone(targetPos)
	if (not landPos) then return false end

	local flightZ = GetFlightAltitude(landPos)
	local route = FindGunshipRoute(landPos, flightZ, mins, maxs)
	if (not route) then return false end

	local uid = tostring(math.random(100000, 999999))
	local allEnts = {}

	local function CleanupSupportEnts()
		if (IsValid(dropship) and dropship.ixDropshipDetectHook) then
			hook.Remove("Think", dropship.ixDropshipDetectHook)
		end
		for _, e in ipairs(allEnts) do
			if (IsValid(e)) then e:Remove() end
		end
	end

	-- landing point info_target — sets yaw to control dropship landing orientation
	local landTargetName = DROPSHIP_LAND_PREFIX .. uid
	local landTarget = ents.Create("info_target")
	landTarget:SetPos(landPos)
	landTarget:SetAngles(Angle(0, landYaw or 0, 0))
	landTarget:SetKeyValue("targetname", landTargetName)
	landTarget:Spawn()
	landTarget:Activate()
	table.insert(allEnts, landTarget)

	-- approach path_tracks
	local track1Name = DROPSHIP_TRACK_PREFIX .. uid .. "_1"
	for idx, wp in ipairs(route.waypoints) do
		local track = ents.Create("path_track")
		track:SetPos(wp)
		track:SetKeyValue("targetname", DROPSHIP_TRACK_PREFIX .. uid .. "_" .. idx)
		track:SetKeyValue("radius", "100")
		track:Spawn()
		track:Activate()
		table.insert(allEnts, track)
	end

	local dropship = ents.Create("npc_combinedropship")
	if (not IsValid(dropship)) then
		CleanupSupportEnts()
		return false
	end

	dropship:SetPos(route.spawnPos)
	dropship:SetKeyValue("CrateType", "1")
	dropship:SetKeyValue("LandTarget", landTargetName)
	dropship:SetKeyValue("GunRange", "2000")
	dropship:SetKeyValue("spawnflags", tostring(bit.bor(32, 1024)))
	dropship:Spawn()
	dropship:Activate()

	dropship.ixDropshipTargetPos		= landPos
	dropship.ixDropshipState			= "approaching"
	dropship.ixDropshipReturnTrackName	= track1Name

	-- dustoff position table, used when spawning soldiers
	local dustoffPositions = {}
	for i = 1, soldierCount do
		dustoffPositions[i] = nil
	end

	local function SpawnDropshipSoldier(index, container)
		if (not IsValid(container)) then return end

		local contForward = container:GetForward()
		local contRight = container:GetRight()

		contForward.z = 0
		contRight.z = 0

		if (contForward:LengthSqr() == 0) then
			contForward = Vector(1, 0, 0)
		else
			contForward:Normalize()
		end

		if (contRight:LengthSqr() == 0) then
			contRight = Vector(0, 1, 0)
		else
			contRight:Normalize()
		end

		local runForward = Vector(contForward.x, contForward.y, contForward.z)
		local runRight = Vector(contRight.x, contRight.y, contRight.z)
 
		local spawnPos = container:GetPos()
			+ contForward * -42
			+ Vector(0, 0, 0)

		local soldierName	= DROPSHIP_TEMPL_PREFIX .. uid .. "_s" .. index
		local soldier		= ents.Create("npc_combine_s")
		soldier:SetPos(spawnPos)
		soldier:SetAngles(container:GetAngles())
		soldier:SetKeyValue("spawnflags", "644")
		soldier:SetKeyValue("additionalequipment", "weapon_ar2")
		soldier:Spawn()
		soldier:Activate()
		soldier:SetName(soldierName)
		soldier:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
		soldier.ixDropshipDeployedSoldier = true
		soldier:SetCustomCollisionCheck(true)

		local seq = ents.Create("scripted_sequence")
		seq:SetName(soldierName .. "_seq")
		seq:SetKeyValue("spawnflags", "624")
		seq:SetKeyValue("m_iszEntity", soldierName)
		seq:SetKeyValue("m_iszIdle", "idle1")
		seq:SetKeyValue("m_fMoveTo", "4")
		seq:SetKeyValue("m_iszPlay", "Dropship_Deploy")
		seq:SetPos(spawnPos)
		seq:SetAngles(container:GetAngles())
		seq:Spawn()
		seq:Activate()
		seq:SetParent(soldier)
		seq:Fire("BeginSequence", "", 0)

		local dustPos = dustoffPositions[index]
		timer.Simple(2.7, function()
			if (IsValid(soldier)) then
				soldier:ExitScriptedSequence()
				if (IsValid(seq)) then seq:Remove() end

				if (not dustPos) then
					local bestDustPos
					for _ = 1, 8 do
						local forwardOffset = math.random(260, 420)
						local lateralOffset = math.random(-150, 150)
						local candidate = soldier:GetPos() + runForward * forwardOffset + runRight * lateralOffset
						local dTr = util.TraceLine({
							start = candidate + Vector(0, 0, 100),
							endpos = candidate - Vector(0, 0, 500),
							mask = MASK_SOLID_BRUSHONLY
						})
						if (dTr.Hit) then
							bestDustPos = dTr.HitPos
							break
						end
					end

					if (not bestDustPos) then
						local fallbackPos = soldier:GetPos() + runForward * 320
						local fallbackTr = util.TraceLine({
							start = fallbackPos + Vector(0, 0, 100),
							endpos = fallbackPos - Vector(0, 0, 500),
							mask = MASK_SOLID_BRUSHONLY
						})
						bestDustPos = fallbackTr.Hit and fallbackTr.HitPos or fallbackPos
					end

					dustPos = bestDustPos
					dustoffPositions[index] = bestDustPos
				end

				if (dustPos) then
						-- force move via scripted_sequence: SetSchedule is unreliable as NPC AI overwrites it immediately after ExitScriptedSequence
					local moveSeq = ents.Create("scripted_sequence")
					moveSeq:SetPos(dustPos)
					moveSeq:SetKeyValue("m_iszEntity", soldierName)
					moveSeq:SetKeyValue("m_fMoveTo", "1")
					moveSeq:SetKeyValue("m_iszIdle", "idle1")
					moveSeq:SetKeyValue("m_iszPlay", "idle1")
					moveSeq:SetKeyValue("spawnflags", "512")
					moveSeq:Spawn()
					moveSeq:Activate()
					moveSeq:Fire("BeginSequence", "", 0.05)

					timer.Simple(12, function()
						if (IsValid(soldier)) then
							soldier:ExitScriptedSequence()
							soldier:SetCollisionGroup(COLLISION_GROUP_NPC)
						end
						if (IsValid(moveSeq)) then moveSeq:Remove() end
					end)
				end
			end
			if (IsValid(seq)) then seq:Remove() end
		end)
	end

	local landHoverPos	= route.waypoints[#route.waypoints]
	local currentWP		= 1
	dropship:Fire("FlyToSpecificTrackViaPath", track1Name, 0.1)

	local timerId = "ixDropship_" .. dropship:EntIndex()

	local function BuildDepartureTrackName(index)
		return DROPSHIP_TRACK_PREFIX .. uid .. "_depart_" .. index
	end

	local function CreateDepartureTracks()
		if (not IsValid(dropship)) then return false end
		if (dropship.ixDropshipDepartureTracksBuilt) then return true end

		local departPos = dropship:GetPos()
		local departDir = (route.spawnPos - departPos)
		departDir.z = 0

		if (departDir:LengthSqr() == 0) then
			departDir = dropship:GetForward()
			departDir.z = 0
		end

		if (departDir:LengthSqr() == 0) then
			departDir = Vector(1, 0, 0)
		else
			departDir:Normalize()
		end

		local risePos = departPos + Vector(0, 0, 700)
		local exitPos = FindEdgeFlightPoint(risePos, departDir, route.spawnPos.z, 200)

		for idx, wp in ipairs({risePos, exitPos}) do
			local track = ents.Create("path_track")
			if (not IsValid(track)) then return false end

			track:SetPos(wp)
			track:SetKeyValue("targetname", BuildDepartureTrackName(idx))
			track:SetKeyValue("radius", "100")
			track:Spawn()
			track:Activate()
			table.insert(allEnts, track)
		end

		dropship.ixDropshipDepartureTracksBuilt = true
		dropship.ixDropshipDepartureRiseTrackName = BuildDepartureTrackName(1)
		dropship.ixDropshipDepartureExitTrackName = BuildDepartureTrackName(2)
		dropship.ixDropshipDepartureExitPos = exitPos
		dropship.ixDropshipDepartureRisePos = risePos
		dropship.ixDropshipDepartureStart = CurTime()

		return true
	end

	local function BeginDropshipDeparture()
		if (not IsValid(dropship) or dropship.ixDropshipState == "departing") then return end
		if (not dropship.ixDropshipAllowDeparture) then return end

		CreateDepartureTracks()

		dropship.ixDropshipState = "departing"
		dropship.ixDropshipDeparturePhase = "rising"
		dropship.ixDropshipTargetPos = nil

		if (dropship.ixDropshipDepartureRiseTrackName) then
			dropship:Fire("FlyToSpecificTrackViaPath", dropship.ixDropshipDepartureRiseTrackName, 0)
		end
	end

	timer.Create(timerId, 0.5, 0, function()
		if (not IsValid(dropship)) then
			CleanupSupportEnts()
			timer.Remove(timerId)
			return
		end

		local pos	= dropship:GetPos()
		local state	= dropship.ixDropshipState

		if (state == "approaching") then
			if (currentWP < #route.waypoints and pos:Distance(route.waypoints[currentWP]) < 600) then
				currentWP = currentWP + 1
			end

			if (pos:Distance(landHoverPos) <= 800) then
				-- find and hide the real container, parent the fake one to it for automatic sway sync
				local realCont = nil
				for _, e in ipairs(ents.FindByClass("prop_dropship_container")) do
					if (e:GetParent() == dropship) then
						realCont = e
						break
					end
				end

				if (IsValid(realCont)) then
					realCont:SetNoDraw(true)
					dropship.ixDropshipRealContainer = realCont

					local fakeCont = ents.Create("prop_dropship_container")
					fakeCont:SetMoveType(MOVETYPE_NONE)
					fakeCont:SetSolid(SOLID_NONE)
					fakeCont:SetPos(realCont:GetPos())
					fakeCont:SetAngles(realCont:GetAngles())
					fakeCont:Spawn()
					fakeCont:Activate()
					fakeCont:SetParent(realCont)
					fakeCont:SetLocalPos(Vector(0, 0, 0))
					fakeCont:SetLocalAngles(Angle(0, 0, 0))

					local phys = fakeCont:GetPhysicsObject()
					if (IsValid(phys)) then
						phys:EnableGravity(false)
						phys:EnableMotion(false)
					end

					dropship.ixDropshipFakeContainer = fakeCont
					table.insert(allEnts, fakeCont)
				end

				dropship:Fire("OmniscientOff", "", 0)
				dropship:Fire("LandTakeCrate", tostring(soldierCount), 0)
				dropship.ixDropshipState	= "landing"
				dropship.ixDropshipTargetPos	= nil
				dropship.ixLandingStart		= CurTime()

				-- container landing detection: detach and freeze once fully grounded
				local detectHookId = "ixDSLandDetect_" .. dropship:EntIndex()
				dropship.ixDropshipDetectHook = detectHookId
				hook.Add("Think", detectHookId, function()
					if (not IsValid(dropship) or dropship.ixDropshipContainerDeployed) then
						hook.Remove("Think", detectHookId)
						return
					end

					local c = dropship.ixDropshipRealContainer
					if (not IsValid(c)) then
						hook.Remove("Think", detectHookId)
						return
					end

					-- retrace actual ground from current container position
					local groundTr = util.TraceLine({
						start = c:GetPos() + Vector(0, 0, 10),
						endpos = c:GetPos() - Vector(0, 0, 500),
						mask  = MASK_SOLID_BRUSHONLY,
					})
					local contPos = c:GetPos()
					local contAng = c:GetAngles()
					local contMins, contMaxs = c:OBBMins(), c:OBBMaxs()
					local samplePoints = {
						Vector(contMins.x, contMins.y, contMins.z),
						Vector(contMins.x, contMaxs.y, contMins.z),
						Vector(contMaxs.x, contMins.y, contMins.z),
						Vector(contMaxs.x, contMaxs.y, contMins.z),
						Vector(0, 0, contMins.z),
					}
					local groundedSamples = 0

					for _, localPoint in ipairs(samplePoints) do
						local worldPoint = LocalToWorld(localPoint, angle_zero, contPos, contAng)
						local sampleTr = util.TraceLine({
							start = worldPoint + Vector(0, 0, 12),
							endpos = worldPoint - Vector(0, 0, 64),
							mask = MASK_SOLID_BRUSHONLY,
						})

						if (sampleTr.Hit and math.abs(worldPoint.z - sampleTr.HitPos.z) <= 24) then
							groundedSamples = groundedSamples + 1
						end
					end

					if (groundedSamples >= 3
						and CurTime() - dropship.ixLandingStart > 2) then

						dropship.ixDropshipContainerDeployed = true
						dropship.ixLockedYaw = dropship:GetAngles().y
						hook.Remove("Think", detectHookId)

						local fc = dropship.ixDropshipFakeContainer
						local realContainer = dropship.ixDropshipRealContainer

						-- disable collision on dropship and real container while soldiers deploy, so they don't block NPC paths
						dropship:SetNotSolid(true)
						dropship:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

						if (IsValid(realContainer)) then
							realContainer:SetNotSolid(true)
							realContainer:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
						end

						if (IsValid(fc)) then
							-- fix in world to keep container on the ground; weakly reflect dropship angle changes for a sway effect
							-- the dropship AI will not depart on its own while a prop_dropship_container entity exists
							local worldPos = fc:GetPos()
							local worldAng = fc:GetAngles()
							local refShipAng = dropship:GetAngles()
							local swayHookId = "ixDSFakeSway_" .. fc:EntIndex()

							fc:SetParent(nil)
							fc:SetPos(worldPos)
							fc:SetAngles(worldAng)

							local phys2 = fc:GetPhysicsObject()
							if (IsValid(phys2)) then
								phys2:EnableGravity(false)
								phys2:EnableMotion(false)
							end

							dropship.ixDropshipFakeSwayHook = swayHookId
							hook.Add("Think", swayHookId, function()
								if (not IsValid(fc) or not IsValid(dropship)) then
									hook.Remove("Think", swayHookId)
									return
								end

								local shipAng = dropship:GetAngles()
								local deltaPitch = math.AngleDifference(shipAng.p, refShipAng.p)
								local deltaRoll = math.AngleDifference(shipAng.r, refShipAng.r)
								local deltaYaw = math.AngleDifference(shipAng.y, refShipAng.y)

								local swayPos = worldPos
									+ dropship:GetRight() * math.Clamp(deltaRoll * 0.7, -8, 8)
									+ dropship:GetForward() * math.Clamp(deltaPitch * -0.45, -5, 5)

								fc:SetPos(swayPos)
								fc:SetAngles(Angle(
									worldAng.p + math.Clamp(deltaPitch * 0.35, -8, 8),
									worldAng.y + math.Clamp(deltaYaw * 0.1, -4, 4),
									worldAng.r + math.Clamp(deltaRoll * 0.65, -14, 14)
								))
							end)

							-- Open → Open Idle → spawn soldiers → Close → Close Idle
							timer.Simple(0.15, function()
								if (not IsValid(fc)) then return end

								local openSeq = fc:LookupSequence("open")
								if (openSeq < 0) then return end

								fc:ResetSequence(openSeq)
								fc:SetCycle(0)
								fc:SetPlaybackRate(1)

								local openDur		= fc:SequenceDuration(openSeq)
								local spawnStart	= openDur + 0.1

								-- immediately play Open Idle once Open finishes
								timer.Simple(openDur, function()
									if (IsValid(fc)) then
										local s = fc:LookupSequence("open_idle")
										if (s >= 0) then fc:ResetSequence(s) ; fc:SetPlaybackRate(1) end
									end
								end)

								-- spawn soldiers sequentially once Open Idle begins
								for i = 1, soldierCount do
									timer.Simple(spawnStart + (i - 1) * DROPSHIP_DEPLOY_STEP, function()
										SpawnDropshipSoldier(i, fc)
									end)
								end

								-- trigger Close after the last soldier's animation finishes
								local closeTrigger = spawnStart + (soldierCount - 1) * DROPSHIP_DEPLOY_STEP + 2.7 + 1.2
								timer.Simple(closeTrigger, function()
									if (not IsValid(fc)) then return end
									local closeSeq = fc:LookupSequence("close")
									if (closeSeq < 0) then return end

									fc:ResetSequence(closeSeq)
									fc:SetCycle(0)
									fc:SetPlaybackRate(1)

									-- play Close Idle once Close finishes
									timer.Simple(fc:SequenceDuration(closeSeq), function()
										local realContainer = dropship.ixDropshipRealContainer

										if (IsValid(realContainer)) then
											realContainer:SetNoDraw(false)
											realContainer:SetNotSolid(false)
											realContainer:SetCollisionGroup(COLLISION_GROUP_NONE)
										end

										if (IsValid(dropship)) then
											dropship:SetNotSolid(false)
											dropship:SetCollisionGroup(COLLISION_GROUP_NONE)
										end

										if (dropship.ixDropshipFakeSwayHook) then
											hook.Remove("Think", dropship.ixDropshipFakeSwayHook)
											dropship.ixDropshipFakeSwayHook = nil
										end

										if (IsValid(fc)) then
											fc:Remove()
										end

										dropship.ixDropshipFakeContainer = nil
										dropship.ixDropshipAllowDeparture = true
										BeginDropshipDeparture()
									end)
								end)
							end)
						end
					end
				end)
			else
				dropship:Fire("FlyToSpecificTrackViaPath", DROPSHIP_TRACK_PREFIX .. uid .. "_" .. currentWP, 0)
			end

		elseif (state == "landing") then
			if (dropship.ixLockedYaw) then
				local ang = dropship:GetAngles()
				dropship:SetAngles(Angle(ang.p, dropship.ixLockedYaw, ang.r))
			end

			-- landing detection and soldier spawning are handled by the Think hook
			-- 60-second safety timeout
			if (dropship.ixDropshipAllowDeparture and CurTime() - dropship.ixLandingStart > 60) then
				BeginDropshipDeparture()
			end

		elseif (state == "departing") then
			local risePos = dropship.ixDropshipDepartureRisePos
			local exitPos = dropship.ixDropshipDepartureExitPos or route.spawnPos

			if (dropship.ixDropshipDeparturePhase == "rising") then
				if (risePos and pos:Distance(risePos) <= 500) then
					dropship.ixDropshipDeparturePhase = "exiting"
				end
			end

			if ((dropship.ixDropshipDeparturePhase == "exiting" and pos:Distance(exitPos) <= 700)
				or (dropship.ixDropshipDepartureStart and CurTime() - dropship.ixDropshipDepartureStart >= 25 and pos:Distance(exitPos) <= 3000)) then
				CleanupSupportEnts()
				if (IsValid(dropship)) then dropship:Remove() end
				timer.Remove(timerId)
			else
				if (dropship.ixDropshipDeparturePhase == "rising" and dropship.ixDropshipDepartureRiseTrackName) then
					dropship:Fire("FlyToSpecificTrackViaPath", dropship.ixDropshipDepartureRiseTrackName, 0)
				elseif (dropship.ixDropshipDepartureExitTrackName) then
					dropship:Fire("FlyToSpecificTrackViaPath", dropship.ixDropshipDepartureExitTrackName, 0)
				end
			end
		end
	end)

	return true
end

function PLUGIN:CallDropshipAPC(targetPos)
	local tempEnt = ents.Create("npc_combinedropship")
	tempEnt:SetPos(targetPos + Vector(0, 0, 8192))
	tempEnt:Spawn()
	local mins, maxs = tempEnt:GetCollisionBounds()
	tempEnt:Remove()

	local landPos = FindLandingZone(targetPos, true)
	if (not landPos) then return false end

	local flightZ = GetFlightAltitude(landPos)
	local route = FindGunshipRoute(landPos, flightZ, mins, maxs)
	if (not route) then return false end

	local uid = tostring(math.random(100000, 999999))
	local allEnts = {}
	local dropship

	local function CleanupSupportEnts()
		for _, e in ipairs(allEnts) do
			if (IsValid(e)) then e:Remove() end
		end
	end

	local apcName = "ix_dsapc_" .. uid
	local apc = ents.Create("prop_vehicle_apc")
	apc:SetKeyValue("targetname", apcName)
	apc:SetKeyValue("model", "models/combine_apc.mdl")
	apc:SetKeyValue("vehiclescript", "scripts/vehicles/apc_npc.txt")
	apc:SetKeyValue("VehicleLocked", "1")
	apc:Spawn()
	apc:Activate()
	table.insert(allEnts, apc)

	local apcDriver = ents.Create("npc_apcdriver")
	apcDriver:SetKeyValue("vehicle", apcName)
	apcDriver:SetKeyValue("spawnflags", "256")
	apcDriver:Spawn()
	apcDriver:Activate()
	table.insert(allEnts, apcDriver)

	local landTargetName = DROPSHIP_LAND_PREFIX .. uid
	local landTarget = ents.Create("info_target")
	landTarget:SetPos(landPos)
	landTarget:SetKeyValue("targetname", landTargetName)
	landTarget:Spawn()
	landTarget:Activate()
	table.insert(allEnts, landTarget)

	local track1Name = DROPSHIP_TRACK_PREFIX .. uid .. "_1"
	for idx, wp in ipairs(route.waypoints) do
		local track = ents.Create("path_track")
		track:SetPos(wp)
		track:SetKeyValue("targetname", DROPSHIP_TRACK_PREFIX .. uid .. "_" .. idx)
		track:SetKeyValue("radius", "100")
		track:Spawn()
		track:Activate()
		table.insert(allEnts, track)
	end

	dropship = ents.Create("npc_combinedropship")
	dropship:SetPos(route.spawnPos)
	dropship:SetKeyValue("CrateType", "-2")
	dropship:SetKeyValue("APCVehicleName", apcName)
	dropship:SetKeyValue("LandTarget", landTargetName)
	dropship:SetKeyValue("spawnflags", tostring(bit.bor(32, 1024)))
	dropship:Spawn()
	dropship:Activate()

	dropship.ixDropshipState = "approaching"
	dropship.ixDropshipReturnTrackName = track1Name

	local landHoverPos = route.waypoints[#route.waypoints]
	local currentWP = 1
	local timerId = "ixDropshipAPC_" .. dropship:EntIndex()
	dropship:Fire("FlyToSpecificTrackViaPath", track1Name, 0.1)

	local function BuildDepartureTrackName(index)
		return DROPSHIP_TRACK_PREFIX .. uid .. "_apc_depart_" .. index
	end

	local function CreateDepartureTracks()
		if (not IsValid(dropship)) then return false end
		if (dropship.ixDropshipDepartureTracksBuilt) then return true end

		local departPos = dropship:GetPos()
		local departDir = (route.spawnPos - departPos)
		departDir.z = 0
		if (departDir:LengthSqr() == 0) then
			departDir = dropship:GetForward()
			departDir.z = 0
		end
		if (departDir:LengthSqr() == 0) then
			departDir = Vector(1, 0, 0)
		else
			departDir:Normalize()
		end

		local risePos = departPos + Vector(0, 0, 700)
		local exitPos = FindEdgeFlightPoint(risePos, departDir, route.spawnPos.z, 200)

		for idx, wp in ipairs({risePos, exitPos}) do
			local track = ents.Create("path_track")
			if (not IsValid(track)) then return false end
			track:SetPos(wp)
			track:SetKeyValue("targetname", BuildDepartureTrackName(idx))
			track:SetKeyValue("radius", "100")
			track:Spawn()
			track:Activate()
			table.insert(allEnts, track)
		end

		dropship.ixDropshipDepartureTracksBuilt = true
		dropship.ixDropshipDepartureRiseTrackName = BuildDepartureTrackName(1)
		dropship.ixDropshipDepartureExitTrackName = BuildDepartureTrackName(2)
		dropship.ixDropshipDepartureRisePos = risePos
		dropship.ixDropshipDepartureExitPos = exitPos
		dropship.ixDropshipDepartureStart = CurTime()
		return true
	end

	timer.Create(timerId, 0.5, 0, function()
		if (not IsValid(dropship)) then
			CleanupSupportEnts()
			timer.Remove(timerId)
			return
		end

		local pos = dropship:GetPos()
		local state = dropship.ixDropshipState

		if (state == "approaching") then
			if (currentWP < #route.waypoints and pos:Distance(route.waypoints[currentWP]) < 600) then
				currentWP = currentWP + 1
				dropship:Fire("FlyToSpecificTrackViaPath", DROPSHIP_TRACK_PREFIX .. uid .. "_" .. currentWP, 0)
			end

			if (pos:Distance(landHoverPos) <= 800) then
				dropship:Fire("OmniscientOff", "", 0)
				-- start landing and APC drop sequence; OnFinishedDropOff fires via EntityFireOutput hook to trigger departure
				CreateDepartureTracks()
				dropship.ixDropshipAllowDeparture = true
				dropship.ixDropshipDeparturePhase = "rising"
				dropship.ixDropshipLandingStart = CurTime()
				dropship:Fire("LandLeaveCrate", "0", 0)
				dropship.ixDropshipState = "landing"
			end

		elseif (state == "departing") then
			local risePos = dropship.ixDropshipDepartureRisePos
			local exitPos = dropship.ixDropshipDepartureExitPos or route.spawnPos

			if (dropship.ixDropshipDeparturePhase == "rising") then
				if (risePos and pos:Distance(risePos) <= 500) then
					dropship.ixDropshipDeparturePhase = "exiting"
				end
			end

			if ((dropship.ixDropshipDeparturePhase == "exiting" and pos:Distance(exitPos) <= 700)
				or (dropship.ixDropshipDepartureStart and CurTime() - dropship.ixDropshipDepartureStart >= 25 and pos:Distance(exitPos) <= 3000)) then
				CleanupSupportEnts()
				if (IsValid(dropship)) then dropship:Remove() end
				timer.Remove(timerId)
			else
				if (dropship.ixDropshipDeparturePhase == "rising" and dropship.ixDropshipDepartureRiseTrackName) then
					dropship:Fire("FlyToSpecificTrackViaPath", dropship.ixDropshipDepartureRiseTrackName, 0)
				elseif (dropship.ixDropshipDepartureExitTrackName) then
					dropship:Fire("FlyToSpecificTrackViaPath", dropship.ixDropshipDepartureExitTrackName, 0)
				end
			end
		end
	end)

	return true
end


hook.Add("EntityFireOutput", "ixDropshipMonitor", function(ent, output)
	if (not IsValid(ent)) then return end
	if (output ~= "OnFinishedDropOff" and output ~= "OnFinishedDropoff") then return end
	if (ent:GetClass() ~= "npc_combinedropship") then return end
	if (ent.ixDropshipState ~= "landing") then return end
	if (not ent.ixDropshipAllowDeparture) then return end

	local fc = ent.ixDropshipFakeContainer
	if (IsValid(fc)) then
		return
	end

	ent.ixDropshipState = "departing"
	ent.ixDropshipDeparturePhase = ent.ixDropshipDeparturePhase or "exiting"
	ent.ixDropshipTargetPos = nil
	if (ent.ixDropshipDeparturePhase == "rising" and ent.ixDropshipDepartureRiseTrackName) then
		ent:Fire("FlyToSpecificTrackViaPath", ent.ixDropshipDepartureRiseTrackName, 0)
	elseif (ent.ixDropshipDepartureExitTrackName) then
		ent:Fire("FlyToSpecificTrackViaPath", ent.ixDropshipDepartureExitTrackName, 0)
	elseif (ent.ixDropshipReturnTrackName) then
		ent:Fire("FlyToSpecificTrackViaPath", ent.ixDropshipReturnTrackName, 0)
	end
end)

hook.Add("NPC_SeeEntity", "ixGunshipCombatSuppress", function(npc, entity)
	if (npc:GetClass() == "npc_combinedropship"
		and IsValid(entity)
		and entity.ixDropshipDeployedSoldier) then
		return false
	end

	if (npc.ixDropshipDeployedSoldier
		and IsValid(entity)
		and (entity:GetClass() == "npc_combinedropship" or entity:GetClass() == "prop_dropship_container")) then
		return false
	end

	if (npc.ixGunshipTargetPos and npc:GetPos():Distance(npc.ixGunshipTargetPos) > GUNSHIP_COMBAT_RADIUS) then
		return false
	end
	if (npc.ixDropshipTargetPos and npc:GetPos():Distance(npc.ixDropshipTargetPos) > GUNSHIP_COMBAT_RADIUS) then
		return false
	end
end)

hook.Add("ShouldCollide", "ixDropshipSoldierNoCollide", function(ent1, ent2)
	if (not IsValid(ent1) or not IsValid(ent2)) then return end

	local ent1IsDropshipSoldier = ent1.ixDropshipDeployedSoldier
	local ent2IsDropshipSoldier = ent2.ixDropshipDeployedSoldier
	local ent1IsDropshipPart = ent1:GetClass() == "npc_combinedropship" or ent1:GetClass() == "prop_dropship_container"
	local ent2IsDropshipPart = ent2:GetClass() == "npc_combinedropship" or ent2:GetClass() == "prop_dropship_container"

	if (ent1IsDropshipSoldier and ent2IsDropshipSoldier) then
		return false
	end

	if ((ent1IsDropshipSoldier and ent2IsDropshipPart) or (ent2IsDropshipSoldier and ent1IsDropshipPart)) then
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

function PLUGIN:ForceSpawnFromSpawner(id)
	local spawner = self.spawners[id]
	if (not spawner) then return 0 end

	local spawned = 0
	local slots = spawner.maxSpawned

	local activeNPCs = 0
	for _, ent in ipairs(spawner.spawnedNPCs) do
		if (IsValid(ent) and ent:IsNPC() and ent:Health() > 0) then
			activeNPCs = activeNPCs + 1
		end
	end

	for i = 1, (slots - activeNPCs) do
		local class = self:SelectRandomClass(spawner.classes)
		if (not class) then break end

		local spawnPos = self:FindValidSpawnPos(spawner.pos, class)
		if (not spawnPos) then continue end

		local ent = ents.Create(class)
		if (not IsValid(ent)) then continue end

		local flags = 1
		if (class == "npc_barnacle" and math.random(1, 100) <= 30) then
			flags = flags + 131072
		elseif (class == "npc_combine_s") then
			flags = flags + 65536
			local roll = math.random(1, 120)
			local weapon = roll <= 80 and "weapon_smg1" or roll <= 110 and "weapon_ar2" or "weapon_shotgun"
			ent:SetKeyValue("additionalequipment", weapon)
		end
		ent:SetKeyValue("spawnflags", flags)

		ent:SetPos(spawnPos)
		ent:Spawn()
		ent:Activate()

		ent.ixForceSpawned = true
		table.insert(spawner.spawnedNPCs, ent)
		spawner.lastSpawn = CurTime()
		spawned = spawned + 1
	end

	return spawned
end

local forceRemoveWhitelist = {
	npc_combine_camera = true,
	npc_turret_floor = true,
}

function PLUGIN:ForceRemoveIdleNPCs()
	-- build a lookup of all spawner-tracked NPCs
	local spawnerNPCs = {}
	for _, spawner in pairs(self.spawners) do
		for _, ent in ipairs(spawner.spawnedNPCs) do
			if (IsValid(ent)) then
				spawnerNPCs[ent] = true
			end
		end
	end

	local count = 0

	for _, npc in ipairs(ents.GetAll()) do
		if (not IsValid(npc) or not npc:IsNPC()) then continue end
		if (npc:Health() <= 0) then continue end
		if (forceRemoveWhitelist[npc:GetClass()]) then continue end

		local owner = npc:GetOwner()
		local playerOwned = IsValid(owner) and owner:IsPlayer()
		local spawnerOwned = spawnerNPCs[npc]

		if (not playerOwned and not spawnerOwned) then continue end
		if (not self:IsNPCSafeToRemove(npc)) then continue end

		npc:Remove()
		count = count + 1
	end

	return count
end

function PLUGIN:ChargeNPCsAtPlayer(client)
	local count = 0

	for _, npc in ipairs(ents.GetAll()) do
		if (not IsValid(npc) or not npc:IsNPC()) then continue end
		if (npc:Health() <= 0) then continue end
		if (bit.band(npc:CapabilitiesGet(), CAP_MOVE_FLY) ~= 0) then continue end

		npc:AddEntityRelationship(client, D_HT, 99)
		npc:UpdateEnemyMemory(client, client:GetPos())
		npc:SetEnemy(client)
		npc:SetSchedule(SCHED_CHASE_ENEMY)
		npc.ixCharging = true

		count = count + 1
	end

	return count
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

				if (not hasNearbyPlayer and not inVisitCooldown and not ent.ixCharging and not ent.ixForceSpawned and self:IsNPCSafeToRemove(ent)) then
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
				local roll = math.random(1, 120)
				local weapon = roll <= 80 and "weapon_smg1" or roll <= 110 and "weapon_ar2" or "weapon_shotgun"
				ent:SetKeyValue("additionalequipment", weapon)
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
