ENT.Type = "anim"
ENT.PrintName = "Stove"
ENT.Author = "Black Tea"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Helix"

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_c17/furnitureStove001a.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetNetVar("active", false)
		self:SetUseType(SIMPLE_USE)

		local physicsObject = self:GetPhysicsObject()

		if (IsValid(physicsObject)) then
			physicsObject:Wake()
		end
	end

	function ENT:OnRemove()
	end

	function ENT:Use(activator)
		local bActive = !self:GetNetVar("active", false)
		self:SetNetVar("active", bActive)

		if bActive then
			self:EmitSound("ambient/fire/mtov_flame2.wav", 60, 100, 0.8)
		else
			self:EmitSound("ambient/fire/mtov_flame2.wav", 60, 250, 0.8)
		end
	end
else
	local MAX_LIGHT_DIST = 800 * 800
	local MAX_PARTICLE_DIST = 500 * 500

	function ENT:Initialize()
		self.emitter = ParticleEmitter(self:GetPos())
		self.emittime = CurTime()
	end

	function ENT:Think()
		if self:GetNetVar("active") then
			if (!self.loopsound) then
				self.loopsound = CreateSound(self, "ambient/fire/fire_small_loop1.wav")
				self.loopsound:SetSoundLevel(60)
				self.loopsound:PlayEx(0.8, 100)
			elseif (!self.loopsound:IsPlaying()) then
				self.loopsound:PlayEx(0.8, 100)
			end

			-- Point 3: PVS Check - skip lighting if the entity is not in a potentially visible set
			if (!self:TestPVS()) then return end

			-- Point 4: Performance - only create heavy dynamic light when the player is close
			if (EyePos():DistToSqr(self:GetPos()) <= MAX_LIGHT_DIST) then
				local dlight = DynamicLight(self:EntIndex())
				
				if (dlight) then
					dlight.pos = self:GetPos() + self:GetUp() * 20 + self:GetRight() * 11 + self:GetForward() * 3
					dlight.r = 255
					dlight.g = 162
					dlight.b = 76
					dlight.brightness = 2
					dlight.Decay = 1000
					dlight.Size = 128
					dlight.DieTime = CurTime() + 0.1
				end
			end
		elseif (self.loopsound) then
			self.loopsound:Stop()
			self.loopsound = nil
		end
	end

	function ENT:OnRemove()
		if (self.loopsound) then
			self.loopsound:Stop()
			self.loopsound = nil
		end

		if (IsValid(self.emitter)) then
			self.emitter:Finish()
		end
	end
	
	local GLOW_MATERIAL = Material("sprites/glow04_noz.vmt")
	function ENT:Draw()
		self:DrawModel()
		
		if self:GetNetVar("active") then
			-- Point 3: PVS Check - skip expensive rendering if not in a potentially visible set
			if (!self:TestPVS()) then return end

			local position = self:GetPos() + (self:GetUp() * 20) + (self:GetRight() * 11) + (self:GetForward() * 3)
			local size = 20 + math.sin(RealTime() * 15) * 5
			
			-- Level 2: Glow Sprite - visible light source
			render.SetMaterial(GLOW_MATERIAL)
			render.DrawSprite(position, size, size, Color(255, 162, 76, 255))
			
			-- Level 1: Particles - extra detail when close
			if (self.emittime < CurTime() and EyePos():DistToSqr(position) <= MAX_PARTICLE_DIST) then
				if (!IsValid(self.emitter)) then
					self.emitter = ParticleEmitter(self:GetPos())
				end

				if (IsValid(self.emitter)) then
					local smoke = self.emitter:Add("particle/smokesprites_000" .. math.random(1, 9), position)
					if (smoke) then
						smoke:SetVelocity(Vector(0, 0, 120))
						smoke:SetDieTime(math.Rand(0.2, 1.3))
						smoke:SetStartAlpha(math.Rand(150, 200))
						smoke:SetEndAlpha(0)
						smoke:SetStartSize(math.random(0, 5))
						smoke:SetEndSize(math.random(20, 30))
						smoke:SetRoll(math.Rand(180, 480))
						smoke:SetRollDelta(math.Rand(-3, 3))
						smoke:SetColor(50, 50, 50)
						smoke:SetGravity(Vector(0, 0, 10))
						smoke:SetAirResistance(200)
					end
					self.emittime = CurTime() + 0.1
				end
			end
		end
	end

	ENT.PopulateEntityInfo = true
	function ENT:OnPopulateEntityInfo(stove)
		local name = stove:AddRow("name")
		name:SetImportant()
		name:SetText(L(self:GetClass()))
		name:SetBackgroundColor(ix.config.Get("color"))
		name:SizeToContents()

		local description = stove:AddRow("description")
		description:SetText(L"stove_desc")
		description:SizeToContents()
	end
end
