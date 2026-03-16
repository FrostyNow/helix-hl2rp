
AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Forcefield"
ENT.Category = "HL2 RP"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.PhysgunDisabled = true
ENT.bNoPersist = true

-- Localization
ix.lang.AddTable("english", {
	ffModeTitle = "Barrier mode changed to: %s",
	ffModeOff = "Off",
	ffModeCID = "Only allow citizens with valid CID",
	ffModeNone = "Only allow Combine"
})

ix.lang.AddTable("korean", {
	ffModeTitle = "장벽 모드 변경: %s",
	ffModeOff = "꺼짐",
	ffModeCID = "유효한 ID 카드를 소지한 시민만 허용",
	ffModeNone = "콤바인만 허용"
})

local MODE_ALLOW_ALL = 1
local MODE_ALLOW_CID = 2
local MODE_ALLOW_NONE = 3
local FORCEFIELD_LOOP_SOUND = "ambient/machines/combine_shield_loop3.wav"
local FORCEFIELD_LOOP_VOLUME = 0.35
local FORCEFIELD_SOUND_CHECK_INTERVAL = 0.2

local MODES = {
	{
		function(client)
			return false
		end,
		"ffModeOff"
	},
	{
		function(client)
			local character = client:GetCharacter()

			if (character and character:GetInventory() and !character:GetInventory():HasItem("cid")) then
				return true
			else
				return false
			end
		end,
		"ffModeCID"
	},
	{
		function(client)
			return true
		end,
		"ffModeNone"
	}
}

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Mode")
	self:NetworkVar("Entity", 0, "Dummy")
end

-- Helper to check if a player is authorized (Combine or has Comkey)
-- Helper to create physics mesh with thickness to prevent "catching"
function ENT:CreateShieldPhysics(dummyPos)
	local thickness = 2
	
	-- Define 8 corners of the box
	local p1 = Vector(thickness, 0, -40)
	local p2 = Vector(thickness, dummyPos.y, -40)
	local p3 = Vector(thickness, dummyPos.y, 150)
	local p4 = Vector(thickness, 0, 150)
	local p5 = Vector(-thickness, 0, -40)
	local p6 = Vector(-thickness, dummyPos.y, -40)
	local p7 = Vector(-thickness, dummyPos.y, 150)
	local p8 = Vector(-thickness, 0, 150)
	
	local meshVerts = {
		-- Front
		{pos = p1}, {pos = p4}, {pos = p3},
		{pos = p3}, {pos = p2}, {pos = p1},
		-- Back
		{pos = p5}, {pos = p6}, {pos = p7},
		{pos = p7}, {pos = p8}, {pos = p5},
		-- Top
		{pos = p4}, {pos = p8}, {pos = p7},
		{pos = p7}, {pos = p3}, {pos = p4},
		-- Bottom
		{pos = p1}, {pos = p2}, {pos = p6},
		{pos = p6}, {pos = p5}, {pos = p1},
		-- Left side
		{pos = p1}, {pos = p5}, {pos = p8},
		{pos = p8}, {pos = p4}, {pos = p1},
		-- Right side
		{pos = p2}, {pos = p3}, {pos = p7},
		{pos = p7}, {pos = p6}, {pos = p2},
	}
	
	self:PhysicsFromMesh(meshVerts)
end

function ENT:SyncBarrierSkin(skin)
	local resolvedSkin = math.max(0, tonumber(skin) or self:GetSkin() or 0)
	local dummy = self.dummy

	if (!IsValid(dummy) and self.GetDummy) then
		dummy = self:GetDummy()
	end

	self:SetSkin(resolvedSkin)

	if (IsValid(dummy)) then
		dummy:SetSkin(resolvedSkin)
	end
end

if (SERVER) then
	function ENT:UpdateLoopSound(forceState)
		local isPowered = forceState

		if (isPowered == nil) then
			isPowered = self:GetMode() ~= MODE_ALLOW_ALL
		end

		self.ixLastPoweredState = isPowered
	end

	function ENT:SpawnFunction(client, trace)
		local pos = trace.HitPos
		local normal = trace.HitNormal

		-- 1. If hitting floor/ceiling, find the wall first
		if (math.abs(normal.z) > 0.7) then
			local aimDir = client:GetAimVector()
			aimDir.z = 0
			aimDir:Normalize()

			local wallTrace = util.TraceLine({
				start = trace.HitPos + Vector(0, 0, 16),
				endpos = trace.HitPos + aimDir * 512,
				filter = client
			})

			if (wallTrace.Hit and !wallTrace.HitSky) then
				pos = wallTrace.HitPos
				normal = wallTrace.HitNormal
			end
		end

		-- 2. From the wall point, trace down to find the floor
		local floorTrace = util.TraceLine({
			start = pos + normal * 10 + Vector(0, 0, 16),
			endpos = pos + normal * 10 - Vector(0, 0, 256),
			filter = client
		})

		local spawnZ = pos.z
		if (floorTrace.Hit) then
			spawnZ = floorTrace.HitPos.z
		end

		local angles = (client:GetPos() - pos):Angle()
		angles.p = 0
		angles.r = 0
		angles:RotateAroundAxis(angles:Up(), 270)

		local entity = ents.Create("ix_forcefield")
		entity:SetPos(pos + normal * 15 + Vector(0, 0, (spawnZ - pos.z) + 40))
		entity:SetAngles(angles:SnapTo("y", 90))
		entity:Spawn()
		entity:Activate()

		Schema:SaveForceFields()
		return entity
	end

	function ENT:Initialize()
		self:SetModel("models/props_combine/combine_fence01b.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:PhysicsInit(SOLID_VPHYSICS)

		local data = {}
			data.start = self:GetPos() + self:GetRight() * -16
			data.endpos = self:GetPos() + self:GetRight() * -480
			data.filter = self
		local trace = util.TraceLine(data)

		local angles = self:GetAngles()
		angles:RotateAroundAxis(angles:Up(), 90)

		self.dummy = ents.Create("prop_physics")
		self.dummy:SetModel("models/props_combine/combine_fence01a.mdl")
		self.dummy:SetPos(trace.HitPos)
		self.dummy:SetAngles(self:GetAngles())
		self.dummy:Spawn()
		self.dummy.PhysgunDisabled = true
		self:DeleteOnRemove(self.dummy)

		self:CreateShieldPhysics(self:WorldToLocal(self.dummy:GetPos()))

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(false)
			physObj:Sleep()
		end

		self:SetCustomCollisionCheck(true)
		self:EnableCustomCollisions(true)
		self:SetDummy(self.dummy)

		physObj = self.dummy:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(false)
			physObj:Sleep()
		end

		self:SetMoveType(MOVETYPE_NOCLIP)
		self:SetMoveType(MOVETYPE_PUSH)
		self:MakePhysicsObjectAShadow()
		self:SetMode(MODE_ALLOW_ALL)
		self:SyncBarrierSkin(self:GetSkin())
		self.ixLastPoweredState = self:GetMode() ~= MODE_ALLOW_ALL
		self:UpdateLoopSound(self.ixLastPoweredState)
	end

	function ENT:StartTouch(entity)
		if (!self.buzzer) then
			self.buzzer = CreateSound(entity, "ambient/machines/combine_shield_touch_loop1.wav")
			self.buzzer:Play()
			self.buzzer:ChangeVolume(0.8, 0)
		else
			self.buzzer:ChangeVolume(0.8, 0.5)
			self.buzzer:Play()
		end

		self.entities = (self.entities or 0) + 1
	end

	function ENT:EndTouch(entity)
		self.entities = math.max((self.entities or 0) - 1, 0)

		if (self.buzzer and self.entities == 0) then
			self.buzzer:FadeOut(0.5)
		end
	end

	function ENT:OnRemove()
		if (self.buzzer) then
			self.buzzer:Stop()
			self.buzzer = nil
		end

		if (!ix.shuttingDown and !self.ixIsSafe) then
			Schema:SaveForceFields()
		end
	end

	function ENT:Use(activator)
		if ((self.nextUse or 0) < CurTime()) then
			self.nextUse = CurTime() + 1.5
		else
			return
		end

		if (self:IsAuthorized(activator)) then
			self:SetMode(self:GetMode() + 1)

			if (self:GetMode() > #MODES) then
				self:SetMode(1)
				self:SyncBarrierSkin(1)
				self:EmitSound("npc/turret_floor/die.wav")
			else
				self:SyncBarrierSkin(0)
			end

			self:EmitSound("buttons/combine_button5.wav", 140, 100 + (self:GetMode() - 1) * 15)
			self:UpdateLoopSound()
			
			local modeKey = MODES[self:GetMode()][2]
			activator:NotifyLocalized("ffModeTitle", L(modeKey, activator))

			Schema:SaveForceFields()
		else
			self:EmitSound("buttons/combine_button3.wav")
		end
	end

	function ENT:Think()
		local isPowered = self:GetMode() ~= MODE_ALLOW_ALL

		if (self.ixLastPoweredState ~= isPowered) then
			self.ixLastPoweredState = isPowered
			self:UpdateLoopSound(isPowered)
		end

		self:NextThink(CurTime() + 0.2)
		return true
	end
else
	local SHIELD_MATERIAL = ix.util.GetMaterial("effects/combineshield/comshieldwall3")

	local function StopLoopSound(self, fadeTime)
		if (!self.loopSound) then
			return
		end

		if (fadeTime and fadeTime > 0) then
			self.loopSound:FadeOut(fadeTime)
		else
			self.loopSound:Stop()
		end
	end

	function ENT:UpdateLoopSound()
		local isPowered = self:GetMode() != MODE_ALLOW_ALL

		if (!isPowered) then
			StopLoopSound(self, 0.4)
			return
		end

		if (!self.loopSound) then
			self.loopSound = CreateSound(self, FORCEFIELD_LOOP_SOUND)
		end

		if (!self.loopSound) then
			return
		end

		if (!self.loopSound:IsPlaying()) then
			self.loopSound:PlayEx(0, 100)
		end

		self.loopSound:ChangeVolume(FORCEFIELD_LOOP_VOLUME, 0.25)
	end

	function ENT:Initialize()
		local data = {}
			data.start = self:GetPos() + self:GetRight()*-16
			data.endpos = self:GetPos() + self:GetRight()*-480
			data.filter = self
		local trace = util.TraceLine(data)

		self:CreateShieldPhysics(self:WorldToLocal(trace.HitPos))
		self:EnableCustomCollisions(true)
		self:UpdateLoopSound()
	end

	function ENT:Think()
		self:UpdateLoopSound()
		self:SetNextClientThink(CurTime() + FORCEFIELD_SOUND_CHECK_INTERVAL)

		return true
	end

	function ENT:Draw()
		self:DrawModel()

		if (self:GetMode() == 1 or (EyePos():DistToSqr(self:GetPos()) > 1048576)) then
			return
		end

		local angles = self:GetAngles()
		local matrix = Matrix()
		matrix:Translate(self:GetPos() + self:GetUp() * -40)
		matrix:Rotate(angles)

		render.SetMaterial(SHIELD_MATERIAL)

		local dummy = self:GetDummy()

		if (IsValid(dummy)) then
			local vertex = self:WorldToLocal(dummy:GetPos())
			self:SetRenderBounds(vector_origin, vertex + self:GetUp() * 150)

			cam.PushModelMatrix(matrix)
				self:DrawShield(vertex)
			cam.PopModelMatrix()

			matrix:Translate(vertex)
			matrix:Rotate(Angle(0, 180, 0))

			cam.PushModelMatrix(matrix)
				self:DrawShield(vertex)
			cam.PopModelMatrix()
		end
	end

	function ENT:DrawShield(vertex)
		mesh.Begin(MATERIAL_QUADS, 1)
			mesh.Position(vector_origin)
			mesh.TexCoord(0, 0, 0)
			mesh.AdvanceVertex()

			mesh.Position(self:GetUp() * 190)
			mesh.TexCoord(0, 0, 3)
			mesh.AdvanceVertex()

			mesh.Position(vertex + self:GetUp() * 190)
			mesh.TexCoord(0, 3, 3)
			mesh.AdvanceVertex()

			mesh.Position(vertex)
			mesh.TexCoord(0, 3, 0)
			mesh.AdvanceVertex()
		mesh.End()
	end

	function ENT:OnRemove()
		StopLoopSound(self)
		self.loopSound = nil
	end
end

local function PlayerHasCID(client)
	if (!IsValid(client) or !client:IsPlayer()) then
		return false
	end

	local character = client:GetCharacter()

	if (!character) then
		return false
	end

	local inventory = character:GetInventory()

	return inventory and inventory:HasItem("cid") or false
end

local function PlayerHasCombineAccess(client)
	if (!IsValid(client) or !client:IsPlayer()) then
		return false
	end

	if (client:IsCombine()) then
		return true
	end

	local character = client:GetCharacter()

	if (!character) then
		return false
	end

	local inventory = character:GetInventory()

	return inventory and inventory:HasItem("comkey") or false
end

function ENT:IsAuthorized(client)
	return PlayerHasCombineAccess(client)
end

local function GetRagdollOwner(ragdoll)
	if (!IsValid(ragdoll) or !ragdoll:IsRagdoll()) then
		return nil
	end

	local owner = ragdoll:GetNetVar("player")

	if (!IsValid(owner)) then
		owner = ragdoll.ixPlayer
	end

	if (!IsValid(owner) and ragdoll.GetNWEntity) then
		owner = ragdoll:GetNWEntity("player")
	end

	if (IsValid(owner) and owner:IsPlayer()) then
		return owner
	end

	return nil
end

local function GetVehicleDriver(vehicle)
	if (!IsValid(vehicle) or !vehicle:IsVehicle()) then
		return nil
	end

	local driver = vehicle.GetDriver and vehicle:GetDriver() or nil

	if (IsValid(driver) and driver:IsPlayer()) then
		return driver
	end

	return nil
end

local function CanPlayerPass(mode, client)
	if (!IsValid(client) or !client:IsPlayer()) then
		return false
	end

	if (PlayerHasCombineAccess(client)) then
		return true
	end

	if (mode == MODE_ALLOW_CID) then
		return PlayerHasCID(client)
	end

	return false
end

local function ShouldCollideWithUnauthorizedPlayer(mode, client)
	return !CanPlayerPass(mode, client)
end

local function ShouldCollideWithNPC(mode, npc)
	if (!IsValid(npc) or !npc:IsNPC()) then
		return false
	end

	if (Schema:IsCombineNPC(npc)) then
		return false
	end

	if (mode == MODE_ALLOW_CID) then
		return Schema:IsAntiCitizenNPC(npc) or Schema:IsHostileNPC(npc)
	end

	return true
end

local function GetForcefieldPair(a, b)
	if (IsValid(a) and a:GetClass() == "ix_forcefield") then
		return a, b
	end

	if (IsValid(b) and b:GetClass() == "ix_forcefield") then
		return b, a
	end

	return nil, nil
end

-- Shared hook to allow client-side prediction and smooth passing
hook.Add("ShouldCollide", "ix_forcefields", function(a, b)
	local entity, other = GetForcefieldPair(a, b)

	if (!IsValid(entity) or !IsValid(other)) then
		return
	end

	local mode = (entity.GetMode and entity:GetMode()) or MODE_ALLOW_ALL

	-- If forcefield is OFF (Mode 1), everyone and everything passes.
	if (mode == MODE_ALLOW_ALL) then
		return false
	end

	if (other:IsPlayer()) then
		return ShouldCollideWithUnauthorizedPlayer(mode, other)
	end

	if (other:IsVehicle()) then
		local driver = GetVehicleDriver(other)

		if (IsValid(driver)) then
			return ShouldCollideWithUnauthorizedPlayer(mode, driver)
		end

		return true
	end

	if (other:IsRagdoll()) then
		local owner = GetRagdollOwner(other)

		if (IsValid(owner)) then
			return ShouldCollideWithUnauthorizedPlayer(mode, owner)
		end

		return false
	end

	if (other:IsNPC()) then
		return ShouldCollideWithNPC(mode, other)
	end

	return false
end)
