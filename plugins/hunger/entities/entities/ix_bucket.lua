ENT.Type = "anim"
ENT.PrintName = "Bucket"
ENT.Author = "Black Tea"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Helix"
ENT.RenderGroup = RENDERGROUP_BOTH

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_junk/MetalBucket01a.mdl")
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
		local bActive = self:GetNetVar("active", false)
		local action = bActive and "extinguishing" or "lighting"

		activator:SetAction(L(action, activator), 1.5)
		activator:DoStaredAction(self, function()
			if (!IsValid(self) or !IsValid(activator) or activator:GetPos():DistToSqr(self:GetPos()) > 6400) then
				activator:SetAction()
				activator:NotifyLocalized("tooFar")
				return
			end

			local bNewActive = !self:GetNetVar("active", false)
			self:SetNetVar("active", bNewActive)

			if bNewActive then
				self:EmitSound("ambient/fire/mtov_flame2.wav", 60, 100, 0.8)
			else
				self:EmitSound("ambient/fire/mtov_flame2.wav", 60, 250, 0.8)
			end
		end, 1.5, function()
			activator:SetAction()
		end)
	end

	function ENT:Think()
		if (self:GetNetVar("active", false)) then
			local pos = self:GetPos()

			for _, v in ipairs(ents.FindInSphere(pos, 40)) do
				if (v:IsPlayer() and v:Alive()) then
					local relPos = self:WorldToLocal(v:GetPos())

					if (relPos:Length2D() < 12 and relPos.z >= 0 and relPos.z < 40) then
						local dmgInfo = DamageInfo()
						dmgInfo:SetDamage(5)
						dmgInfo:SetDamageType(DMG_BURN)
						dmgInfo:SetAttacker(self)
						dmgInfo:SetInflictor(self)
						dmgInfo:SetDamagePosition(pos)

						v:TakeDamageInfo(dmgInfo)
					end
				end
			end
		end

		self:NextThink(CurTime() + 0.5)
		return true
	end
else
	local MAX_LIGHT_DIST = 1200 * 1200
	local MAX_PARTICLE_DIST = 800 * 800

	function ENT:Initialize()
		self.emitter = ParticleEmitter(self:GetPos(), false)
		self.nextParticle = CurTime()
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

			local firepos = self:GetPos() + self:GetUp() * 5
			
			-- Point 4: Performance - only create heavy dynamic light when the player is close
			if (EyePos():DistToSqr(firepos) <= MAX_LIGHT_DIST) then
				local dlight = DynamicLight(self:EntIndex())
				
				if (dlight) then
					dlight.Pos = firepos
					dlight.r = 255
					dlight.g = 100
					dlight.b = 20
					dlight.Brightness = 2
					dlight.Size = 150
					dlight.Decay = 1000
					dlight.DieTime = CurTime() + 0.1
				end
			end
		elseif (self.loopsound) then
			self.loopsound:Stop()
			self.loopsound = nil
		end
	end
	
	local GLOW_MATERIAL = Material("sprites/glow04_noz.vmt")
	function ENT:Draw()
		self:DrawModel()
	end

	function ENT:DrawTranslucent()
		if not self:GetNetVar("active") then return end

		-- Point 3: PVS Check - skip expensive rendering if not in a potentially visible set
		if (!self:TestPVS()) then return end
		
		if not IsValid(self.emitter) then
			self.emitter = ParticleEmitter(self:GetPos(), false)
		end

		local firepos = self:GetPos() + self:GetUp() * 5
		local up = self:GetUp()

		-- Add particles
		-- Point 4: Only emit particles when close enough to see them
		if (self.nextParticle < CurTime() and IsValid(self.emitter) and EyePos():DistToSqr(firepos) <= MAX_PARTICLE_DIST) then
			-- Main Fire
			for i = 1, 2 do
				local p = self.emitter:Add("particles/flamelet" .. math.random(1, 5), firepos + VectorRand() * 2)
				if (p) then
					p:SetVelocity(up * math.Rand(30, 50) + VectorRand() * 5)
					p:SetDieTime(math.Rand(0.4, 0.6))
					p:SetStartAlpha(180)
					p:SetEndAlpha(0)
					p:SetStartSize(math.Rand(6, 9))
					p:SetEndSize(math.Rand(1.5, 3.5))
					p:SetRoll(math.Rand(0, 360))
					p:SetRollDelta(math.Rand(-10, 10))
					p:SetColor(255, 100 + math.random(50), 30)
					p:SetLighting(false)
				end
			end
			
			-- Embers
			if math.random(1, 6) == 1 then
				local p = self.emitter:Add("particles/flamelet" .. math.random(1, 5), firepos + VectorRand() * 1)
				if (p) then
					p:SetVelocity(up * math.Rand(50, 90) + VectorRand() * 10)
					p:SetDieTime(math.Rand(0.8, 1.5))
					p:SetStartAlpha(255)
					p:SetEndAlpha(0)
					p:SetStartSize(math.Rand(0.5, 1.5))
					p:SetEndSize(0)
					p:SetColor(255, 150, 50)
					p:SetGravity(Vector(0, 0, 20))
					p:SetAirResistance(50)
					p:SetLighting(false)
				end
			end

			-- Smoke
			if math.random(1, 5) == 1 then
				local p = self.emitter:Add("particle/smokesprites_000" .. math.random(1, 9), firepos + up * 10)
				if (p) then
					p:SetVelocity(up * math.Rand(20, 40) + VectorRand() * 5)
					p:SetDieTime(math.Rand(1.5, 3))
					p:SetStartAlpha(math.Rand(30, 60))
					p:SetEndAlpha(0)
					p:SetStartSize(math.Rand(3, 8))
					p:SetEndSize(math.Rand(30, 50))
					p:SetRoll(math.Rand(0, 360))
					p:SetRollDelta(math.Rand(-1, 1))
					p:SetColor(35, 35, 35)
					p:SetGravity(Vector(0, 0, 15))
					p:SetAirResistance(150)
				end
			end
			
			self.nextParticle = CurTime() + 0.05
		end
		
		-- Core Glow
		local size = 22 + math.sin(RealTime() * 2) * 1.5
		render.SetMaterial(GLOW_MATERIAL)
		render.DrawSprite(firepos + up * 5, size, size, Color(255, 120, 0, 150))
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
