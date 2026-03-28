
AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Union Lock"
ENT.Category = "HL2 RP"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PhysgunDisable = true
ENT.bNoPersist = true
local PLUGIN = PLUGIN
function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Locked")
	self:NetworkVar("Bool", 1, "DisplayError")
	self:NetworkVar("Bool", 2, "Detonating")
	self:NetworkVar("Float", 0, "DisabledUntil")

	if SERVER then
		self:NetworkVarNotify("Locked", self.OnLockChanged)
	end
end

function ENT:IsLockDisabled()
	return self:GetDetonating() or self:GetDisabledUntil() > CurTime()
end

if (SERVER) then
	local DETONATE_ARM_TIME = 1.5
	local DETONATE_DURATION = 10
	local DISABLE_DURATION = 300

	function ENT:GetLockPosition(door, normal, fallback)
		local index = door:LookupBone("handle")
		local position = fallback or door:GetPos()
		normal = normal or door:GetForward():Angle()

		if (index and index >= 0) then
			local bonePos = door:GetBonePosition(index)

			if (bonePos and bonePos ~= vector_origin) then
				position = bonePos
			end
		end

		position = position + normal:Forward() * 7.2 + normal:Up() * 10 + normal:Right() * 2

		normal:RotateAroundAxis(normal:Up(), 90)
		normal:RotateAroundAxis(normal:Forward(), 180)
		normal:RotateAroundAxis(normal:Right(), 180)

		return position, normal
	end

	function ENT:SetDoor(door, position, angles)
		if (!IsValid(door) or !door:IsDoor()) then
			return
		end

		local doorPartner = door:GetDoorPartner()

		self.door = door
		self.door:DeleteOnRemove(self)
		door.ixLock = self

		if (IsValid(doorPartner)) then
			self.doorPartner = doorPartner
			self.doorPartner:DeleteOnRemove(self)
			doorPartner.ixLock = self
		end

		self:SetPos(position)
		self:SetAngles(angles)
		self:SetParent(door)

		local index = door:FindBodygroupByName("handle01")

		if (index != -1) then
			if (self.ixOldBodygroup == nil) then
				self.ixOldBodygroup = door:GetBodygroup(index)
			end

			door:SetBodygroup(index, 0)
		end

		if (IsValid(doorPartner)) then
			local partnerIndex = doorPartner:FindBodygroupByName("handle01")

			if (partnerIndex != -1) then
				if (self.ixOldPartnerBodygroup == nil) then
					self.ixOldPartnerBodygroup = doorPartner:GetBodygroup(partnerIndex)
				end

				doorPartner:SetBodygroup(partnerIndex, 0)
			end
		end
	end

	function ENT:SpawnFunction(client, trace)
		local door = trace.Entity

		if (!IsValid(door) or !door:IsDoor() or IsValid(door.ixLock)) then
			return client:NotifyLocalized("dNotValid")
		end

		local normal = trace.HitNormal:Angle()
		local position, angles = self:GetLockPosition(door, normal, trace.HitPos)

		local entity = ents.Create("ix_unionlock")
		entity:SetPos(trace.HitPos)
		entity:Spawn()
		entity:Activate()
		entity:SetDoor(door, position, angles)

		PLUGIN:SaveUnionLocks()
		return entity
	end

	function ENT:Initialize()
		self:SetModel("models/props_combine/combine_lock01.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		self:SetUseType(SIMPLE_USE)

		self.nextUseTime = 0
	end

	function ENT:OnRemove()
		if (IsValid(self)) then
			self:SetParent(nil)
		end

		if (IsValid(self.door)) then
			self.door:Fire("unlock")
			self.door.ixLock = nil

			local index = self.door:FindBodygroupByName("handle01")

			if (index != -1) then
				self.door:SetBodygroup(index, self.ixOldBodygroup or 1)
			end
		end

		if (IsValid(self.doorPartner)) then
			self.doorPartner:Fire("unlock")
			self.doorPartner.ixLock = nil

			local partnerIndex = self.doorPartner:FindBodygroupByName("handle01")

			if (partnerIndex != -1) then
				self.doorPartner:SetBodygroup(partnerIndex, self.ixOldPartnerBodygroup or 1)
			end
		end

		if (!ix.shuttingDown) then
			PLUGIN:SaveUnionLocks()
		end
	end

	function ENT:OnLockChanged(name, bWasLocked, bLocked)
		if (!IsValid(self.door)) then
			return
		end

		if (bLocked) then
			self:EmitSound("buttons/combine_button2.wav")
			self.door:Fire("lock")
			self.door:Fire("close")

			if (IsValid(self.doorPartner)) then
				self.doorPartner:Fire("lock")
				self.doorPartner:Fire("close")
			end
		else
			self:EmitSound("buttons/combine_button7.wav")
			self.door:Fire("unlock")

			if (IsValid(self.doorPartner)) then
				self.doorPartner:Fire("unlock")
			end
		end
	end

	function ENT:DisplayError()
		self:EmitSound("buttons/combine_button_locked.wav")
		self:SetDisplayError(true)

		timer.Simple(1.2, function()
			if (IsValid(self)) then
				self:SetDisplayError(false)
			end
		end)
	end

	function ENT:Ping()
		self:SetDisplayError(true)
		self:EmitSound("npc/turret_floor/ping.wav")

		timer.Simple(0.1, function()
			if (IsValid(self)) then
				self:SetDisplayError(false)
			end
		end)
	end

	function ENT:HasAccess(client)
		local character = client:GetCharacter()
		local inventory = character and character:GetInventory()
		local hasCombineKey = inventory and inventory:HasItem("comkey")
		local hasUnionKey = inventory and inventory:HasItem("unionkey")

		if (inventory) then
			for _, item in pairs(inventory:GetItems()) do
				if (item.uniqueID == "cid" and item:GetData("class") == "Civil Worker's Union") then
					hasUnionKey = true
					break
				end
			end
		end

		return client:IsCombine() or hasCombineKey or hasUnionKey
	end

	function ENT:Detonate(client)
		if (self.nextUseTime > CurTime() or self:IsLockDisabled()) then
			return
		end

		if (!self:HasAccess(client)) then
			self:DisplayError()
			self.nextUseTime = CurTime() + 2

			return
		end

		self:SetDetonating(true)
		self:SetDisplayError(false)
		self.detonateStartTime = CurTime()
		self.detonateEndTime = self.detonateStartTime + DETONATE_DURATION
		self.explodeDir = client:GetAimVector() * 500
		self.nextPing = 0
		self.nextUseTime = self.detonateEndTime
	end

	function ENT:StartDetonationAction(client)
		if (self.nextUseTime > CurTime() or self:IsLockDisabled() or self.detonatePreparing) then
			return
		end

		if (!self:HasAccess(client)) then
			self:DisplayError()
			self.nextUseTime = CurTime() + 2

			return
		end

		self.detonatePreparing = client
		client:SetAction("@prepareDetonation", DETONATE_ARM_TIME)
		client:DoStaredAction(self, function()
			if (!IsValid(self) or !IsValid(client) or self.detonatePreparing != client) then
				return
			end

			self.detonatePreparing = nil
			client:SetAction()
			self:Detonate(client)
		end, DETONATE_ARM_TIME, function()
			if (IsValid(self) and self.detonatePreparing == client) then
				self.detonatePreparing = nil
			end

			if (IsValid(client)) then
				client:SetAction()
			end
		end)
	end

	function ENT:FinishDetonation()
		self:SetDetonating(false)
		self:SetDisplayError(false)
		self:SetDisabledUntil(CurTime() + DISABLE_DURATION)
		self.nextUseTime = self:GetDisabledUntil()

		local effect = EffectData()
			effect:SetOrigin(self:GetPos())
		util.Effect("Explosion", effect)

		if (self:GetLocked()) then
			self:SetLocked(false)
		else
			if (IsValid(self.door)) then
				self.door:Fire("unlock")
			end

			if (IsValid(self.doorPartner)) then
				self.doorPartner:Fire("unlock")
			end
		end

		if (IsValid(self.door)) then
			self.door:EmitSound("physics/wood/wood_crate_break"..math.random(1, 5)..".wav", 150)
			self.door:Fire("open")
		end

		if (IsValid(self.doorPartner)) then
			self.doorPartner:Fire("open")
		end
	end

	function ENT:Think()
		if (!self:GetDetonating()) then
			return
		end

		local curTime = CurTime()

		if (self.detonateEndTime <= curTime) then
			self:FinishDetonation()
			return
		end

		if ((self.nextPing or 0) >= curTime) then
			return
		end

		local fraction = 1 - math.Clamp(math.TimeFraction(
			self.detonateStartTime,
			self.detonateEndTime,
			curTime
		), 0, 1)

		self.nextPing = curTime + fraction
		self:Ping()
	end

	function ENT:Toggle(client)
		if (self.nextUseTime > CurTime() or self:IsLockDisabled()) then
			return
		end

		if (!self:HasAccess(client)) then
			self:DisplayError()
			self.nextUseTime = CurTime() + 2

			return
		end

		self:SetLocked(!self:GetLocked())
		self.nextUseTime = CurTime() + 2
	end

	function ENT:Use(client)
		if (client:KeyDown(IN_WALK)) then
			self:StartDetonationAction(client)
			return
		end

		self:Toggle(client)
	end
else
	local glowMaterial = ix.util.GetMaterial("sprites/glow04_noz")
	local color_orange = Color(255, 125, 0, 255)
	local color_yellow = Color(224, 208, 117)
	local color_red = Color(255, 50, 50, 255)

	function ENT:Draw()
		self:DrawModel()

		-- allow the light to draw while detonating so we can see the red flash
		if (self:IsLockDisabled() and !self:GetDetonating()) then
			return
		end

		local color = color_yellow
		local bDisplayError = self:GetDisplayError()
		local bLocked = self:GetLocked()
		local bDetonating = self:GetDetonating()

		if (bDisplayError) then
			color = color_red
		elseif (bDetonating) then
			-- don't draw anything unless we're flashing red (which is handled by DisplayError)
			return
		elseif (bLocked) then
			color = color_orange
		end

		local position = self:GetPos() + self:GetUp() * -8.7 + self:GetForward() * -3.85 + self:GetRight() * -6

		render.SetMaterial(glowMaterial)
		render.DrawSprite(position, 10, 10, color)

		local dlight = DynamicLight(self:EntIndex())

		if (dlight) then
			dlight.pos = position
			dlight.r = color.r
			dlight.g = color.g
			dlight.b = color.b
			dlight.brightness = 2
			dlight.Decay = 1000
			dlight.Size = bDisplayError and 128 or 64
			dlight.DieTime = CurTime() + 0.1
		end
	end
end
