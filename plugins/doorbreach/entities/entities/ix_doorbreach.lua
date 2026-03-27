
AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Door Breach"
ENT.Category = "HL2 RP"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PhysgunDisable = true
ENT.bNoPersist = true

if (SERVER) then

	function ENT:GetLockPosition(door, normal)
		local index = door:LookupBone("handle") or door:LookupBone("handle_l") or door:LookupBone("handle_r") or door:LookupBone("door_handle")
		local position = door:GetPos()
		normal = normal or door:GetForward():Angle()

		if (index and index >= 0) then
			position = door:GetBonePosition(index)
		else
			local attachment = door:LookupAttachment("handle") or door:LookupAttachment("handle_l") or door:LookupAttachment("handle_r")

			if (attachment and attachment > 0) then
				position = door:GetAttachment(attachment).Pos
			else
				-- fallback to middle-ish of the door if no handle bone/attachment found
				local mins, maxs = door:GetModelBounds()
				position = door:LocalToWorld(Vector(0, (mins.y + maxs.y) * 0.5, (mins.z + maxs.z) * 0.5))
			end
		end

		position = position + normal:Forward() * 4 + normal:Up() * 8 + normal:Right()

		if (IsValid(door.ixLock)) then
			position = position + normal:Forward() * 6 + normal:Up() * 8 + normal:Right() * -1
		end

		normal:RotateAroundAxis(normal:Up(), 180)
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
		door.ixBreach = self

		if (IsValid(doorPartner)) then
			self.doorPartner = doorPartner
			self.doorPartner:DeleteOnRemove(self)
			doorPartner.ixBreach = self
		end

		self:SetPos(position)
		angles.x = angles.x + 90
		self:SetAngles(angles)
		self:SetParent(door)
	end

	function ENT:SpawnFunction(client, trace, class)
		local door = trace.Entity
		local entity = ents.Create(class or "ix_doorbreach")
		entity:SetPos(trace.HitPos + trace.HitNormal * 4)
		entity:Spawn()
		entity:Activate()

		if (IsValid(door) and door:IsDoor() and !IsValid(door.ixBreach)) then
			local normal = trace.HitNormal:Angle()
			local position, angles = self:GetLockPosition(door, normal)
			entity:SetDoor(door, position, angles)
		else
			local angles = trace.HitNormal:Angle()
			angles.p = angles.p + 90
			entity:SetAngles(angles)
		end

		return entity
	end

	function ENT:OnRemove()
		if (IsValid(self)) then
			self:SetParent(nil)
		end

		if (IsValid(self.door)) then
			self.door:Fire("unlock")
			self.door.ixBreach = nil
		end

		if (IsValid(self.doorPartner)) then
			self.doorPartner:Fire("unlock")
			self.doorPartner.ixBreach = nil
		end
	end

	function ENT:Initialize()
		self:SetModel("models/weapons/w_slam.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		self:SetUseType(SIMPLE_USE)

		self.nextUseTime = 0
	end

	function ENT:Explode( )
		local eff = EffectData( )
		eff:SetStart( self:GetPos( ) )
		eff:SetOrigin( self:GetPos( ) )
		eff:SetScale( 6 )
		util.Effect( "Explosion", eff, true, true )

		-- This determines if and how much damage the surrounding entities (namely, players) take from the blast.
		util.BlastDamage( self, self, self:GetPos(), 40, 15)
		self:EmitSound( "physics/wood/wood_furniture_break" .. math.random( 1, 2 ) .. ".wav" )
	end

	function ENT:Use(client)
		if (self.nextUseTime > CurTime()) then
			return
		end

		if (!IsValid(self.door)) then
			local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 96
			data.filter = client

			local trace = util.TraceLine(data)
			local entity = trace.Entity

			if (IsValid(entity) and entity:IsDoor() and !IsValid(entity.ixBreach)) then
				local normal = trace.HitNormal:Angle()
				local position, angles = self:GetLockPosition(entity, normal)

				self:SetDoor(entity, position, angles)
				self:EmitSound("physics/metal/weapon_impact_soft2.wav", 75, 80)
			end

			self.nextUseTime = CurTime() + 1
			return
		end

		self:SetNWBool("beep", true)
		self:EmitSound("buttons/blip1.wav")
		timer.Simple(1, function()
			if (!IsValid(self)) then return end
			self:EmitSound("buttons/blip1.wav")
			timer.Simple(1, function()
				if (!IsValid(self)) then return end
				self:EmitSound("buttons/blip1.wav")
				timer.Simple(0.8, function()
					if (!IsValid(self)) then return end
					self:EmitSound("buttons/blip1.wav")
					timer.Simple(0.6, function()
						if (!IsValid(self)) then return end
						self:EmitSound("buttons/blip1.wav")
						timer.Simple(0.4, function()
							if (!IsValid(self)) then return end
							self:EmitSound("buttons/blip1.wav")
							timer.Simple(0.4, function()
								if (!IsValid(self)) then return end
								self:EmitSound("buttons/blip1.wav")
								timer.Simple(0.3, function()
									if (!IsValid(self)) then return end
									self:EmitSound("buttons/blip1.wav")
									timer.Simple(0.3, function()
										if (!IsValid(self)) then return end
										self:EmitSound("buttons/blip1.wav")
										timer.Simple(0.2, function()
											if (!IsValid(self)) then return end
											self:EmitSound("buttons/blip1.wav")
											timer.Simple(0.2, function()
												if (!IsValid(self)) then return end
												self:EmitSound("buttons/blip1.wav")
												timer.Simple(0.1, function()
													if (!IsValid(self)) then return end
													self:EmitSound("buttons/blip1.wav")
													timer.Simple(0.1, function()
														if (!IsValid(self)) then return end
														if (IsValid(self.door)) then
															self:EmitSound("buttons/blip1.wav")
															self:EmitSound("weapons/explode3.wav")
															self:Explode()
															self.door:Fire("unlock")
															self.door:Fire("open")
															self:Remove()
															if (IsValid(self.doorPartner)) then
																self.doorPartner:Fire("unlock")
																self.doorPartner:Fire("open")
															end
														end
													end )
												end )
											end )
										end	)
									end )
								end )
							end )
						end )
					end	)
				end )
			end )
		end	)
	self.nextUseTime = CurTime() + 10
	end
else
	local glowMaterial = ix.util.GetMaterial("sprites/glow04_noz")
	local color_green = Color(0, 255, 0, 255)
	local color_blue = Color(0, 100, 255, 255)
	local color_red = Color(255, 50, 50, 255)

	function ENT:Draw()
		self:DrawModel()

		local color = color_green

		if (self:GetNWBool("beep", false)) then
			color = color_red
		else
			color = color_green
		end

		local position = self:GetPos() + self:GetForward() * 1.5 + self:GetUp() * 3

		render.SetMaterial(glowMaterial)
		render.DrawSprite(position, 10, 10, color)
	end
end
