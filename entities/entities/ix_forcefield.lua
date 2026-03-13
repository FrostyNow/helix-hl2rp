
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
	ffModeNone = "Allow no citizens"
})

ix.lang.AddTable("korean", {
	ffModeTitle = "장벽 모드 변경: %s",
	ffModeOff = "꺼짐",
	ffModeCID = "유효한 ID 카드를 소지한 시민만 허용",
	ffModeNone = "시민 통과 불가"
})

local MODE_ALLOW_ALL = 1
local MODE_ALLOW_CID = 2
local MODE_ALLOW_NONE = 3

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
function ENT:IsAuthorized(client)
	if (!IsValid(client) or !client:IsPlayer()) then return false end
	
	if (client:IsCombine()) then
		return true
	end
	
	local character = client:GetCharacter()
	if (character) then
		local inventory = character:GetInventory()
		if (inventory and inventory:HasItem("comkey")) then
			return true
		end
	end
	
	return false
end

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

if (SERVER) then
	function ENT:UpdateLoopSound(forceState)
		local isPowered = forceState

		if (isPowered == nil) then
			isPowered = self:GetMode() ~= MODE_ALLOW_ALL
		end

		if (not self.loopSound) then
			self.loopSound = CreateSound(self, "ambient/energy/force_field_loop1.wav")
		end

		if (not self.loopSound) then
			return
		end

		if (isPowered) then
			self.loopSound:PlayEx(0.08, 100)
		else
			self.loopSound:FadeOut(0.4)
		end
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
		if (self.loopSound) then
			self.loopSound:Stop()
			self.loopSound = nil
		end

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

				self:SetSkin(1)
				self.dummy:SetSkin(1)
				self:EmitSound("npc/turret_floor/die.wav")
			else
				self:SetSkin(0)
				self.dummy:SetSkin(0)
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

	function ENT:Initialize()
		local data = {}
			data.start = self:GetPos() + self:GetRight()*-16
			data.endpos = self:GetPos() + self:GetRight()*-480
			data.filter = self
		local trace = util.TraceLine(data)

		self:CreateShieldPhysics(self:WorldToLocal(trace.HitPos))
		self:EnableCustomCollisions(true)
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

local function GetRagdollOwner(ragdoll)
	if (!IsValid(ragdoll) or !ragdoll:IsRagdoll()) then
		return nil
	end

	local owner = ragdoll:GetNetVar("player")

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

local function ShouldCollideWithUnauthorizedPlayer(entity, mode, client)
	if (!IsValid(client) or !client:IsPlayer()) then
		return false
	end

	if (entity.IsAuthorized and entity:IsAuthorized(client)) then
		return false
	end

	if (mode == MODE_ALLOW_CID) then
		return !client:IsCombine() and !PlayerHasCID(client)
	end

	return true
end

-- Shared hook to allow client-side prediction and smooth passing
hook.Add("ShouldCollide", "ix_forcefields", function(a, b)
	local client
	local entity
	local ragdoll
	local vehicle

	if (a:IsPlayer()) then
		client = a
		entity = b
	elseif (b:IsPlayer()) then
		client = b
		entity = a
	elseif (a:IsRagdoll()) then
		ragdoll = a
		entity = b
	elseif (b:IsRagdoll()) then
		ragdoll = b
		entity = a
	elseif (a:IsVehicle()) then
		vehicle = a
		entity = b
	elseif (b:IsVehicle()) then
		vehicle = b
		entity = a
	end

	if (IsValid(entity) and entity:GetClass() == "ix_forcefield") then
		local mode = (entity.GetMode and entity:GetMode()) or 1
		
		-- If forcefield is OFF (Mode 1), everyone and everything passes
		if (mode == 1) then
			return false
		end

		if (IsValid(ragdoll)) then
			local owner = GetRagdollOwner(ragdoll)

			if (!IsValid(owner)) then
				return mode != MODE_ALLOW_CID
			end

			return ShouldCollideWithUnauthorizedPlayer(entity, mode, owner)
		end

		if (IsValid(vehicle)) then
			local driver = GetVehicleDriver(vehicle)

			if (!IsValid(driver)) then
				return false
			end

			return ShouldCollideWithUnauthorizedPlayer(entity, mode, driver)
		end

		if (IsValid(client)) then
			return ShouldCollideWithUnauthorizedPlayer(entity, mode, client)
		else
			return false
		end
	end
end)
