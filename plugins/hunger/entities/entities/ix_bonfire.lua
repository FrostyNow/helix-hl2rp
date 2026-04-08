ENT.Type = "anim"
ENT.PrintName = "Bonfire"
ENT.Author = "Black Tea"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Helix"
ENT.RenderGroup = RENDERGROUP_BOTH

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_unique/firepit_campground.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetNetVar("active", false)
		self:SetNetVar("fuel", 0)
		self:SetNetVar("fuelCount", 0)
		self:SetNetVar("fuelMax", 10)
		self.fuelList = {} -- Server side list of fuel durations
		self:SetUseType(SIMPLE_USE)

		local physicsObject = self:GetPhysicsObject()

		if (IsValid(physicsObject)) then
			physicsObject:Wake()
		end
	end

	function ENT:OnRemove()
	end

	function ENT:OnTakeDamage(damageInfo)
		if (damageInfo:IsDamageType(DMG_BURN) and !self:GetNetVar("active", false)) then
			local fuel = self:GetNetVar("fuel", 0)
			if (fuel > 0) then
				self:SetNetVar("active", true)
				self:EmitSound("ambient/fire/mtov_flame2.wav", 60, 100, 0.8)
			end
		end
	end

	function ENT:AddFuel(seconds)
		self.fuelList = self.fuelList or {}

		if (#self.fuelList >= 10) then
			return false
		end

		table.insert(self.fuelList, seconds)
		self:UpdateFuelNetVars()
		return true
	end

	function ENT:UpdateFuelNetVars()
		self.fuelList = self.fuelList or {}
		local total = 0
		for _, s in ipairs(self.fuelList) do
			total = total + s
		end
		self:SetNetVar("fuel", total)
		self:SetNetVar("fuelCount", #self.fuelList)
		self:SetNetVar("fuelMax", 10)
	end

	function ENT:Use(activator)
		local bActive = self:GetNetVar("active", false)
		local action = bActive and "extinguishing" or "lighting"

		if (!bActive) then
			local fuel = self:GetNetVar("fuel", 0)
			if (fuel <= 0) then
				activator:NotifyLocalized("needFuel")
				return
			end

			local hungerPlugin = ix.plugin.list["hunger"]
			if (!hungerPlugin:HasRemainingFireStarter(activator)) then
				activator:NotifyLocalized("needFireStarter")
				return
			end
		end

		activator:SetAction(L(action, activator), 1.5)
		activator:DoStaredAction(self, function()
			if (!IsValid(self) or !IsValid(activator) or activator:GetPos():DistToSqr(self:GetPos()) > 6400) then
				activator:SetAction()
				activator:NotifyLocalized("tooFar")
				return
			end

			local bNewActive = !self:GetNetVar("active", false)
			
			if (bNewActive) then
				local hungerPlugin = ix.plugin.list["hunger"]
				local item = hungerPlugin:HasRemainingFireStarter(activator)

				if (!item) then
					activator:NotifyLocalized("needFireStarter")
					return
				end

				hungerPlugin:ConsumeFireStarter(item)
			end

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
		self.fuelList = self.fuelList or {}

		if (self:GetNetVar("active", false)) then
			if (#self.fuelList > 0) then
				local decrease = 0.5
				self.fuelList[1] = self.fuelList[1] - decrease
				
				if (self.fuelList[1] <= 0) then
					table.remove(self.fuelList, 1)
				end
				
				self:UpdateFuelNetVars()
			else
				self:SetNetVar("active", false)
				self:EmitSound("ambient/fire/mtov_flame2.wav", 60, 250, 0.8)
			end

			local pos = self:GetPos()

			for _, v in ipairs(ents.FindInSphere(pos, 10)) do
				if (v:IsPlayer() and v:Alive()) then
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

			-- Lighting culling based on distance below


			local firepos = self:GetPos() + self:GetUp() * 10
			
			-- Performance - only create heavy dynamic light when the player is close
			if (EyePos():DistToSqr(firepos) <= MAX_LIGHT_DIST) then
				local dlight = DynamicLight(self:EntIndex())
				
				if (dlight) then
					dlight.Pos = firepos
					dlight.r = 255
					dlight.g = 100
					dlight.b = 20
					dlight.Brightness = 3
					dlight.Size = 256
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

		-- Particle culling based on distance below

		
		if not IsValid(self.emitter) then
			self.emitter = ParticleEmitter(self:GetPos(), false)
		end

		local firepos = self:GetPos() + self:GetUp() * 5
		local up = self:GetUp()

		-- Add particles
		-- Only emit particles when close enough to see them
		if (self.nextParticle < CurTime() and IsValid(self.emitter) and EyePos():DistToSqr(firepos) <= MAX_PARTICLE_DIST) then
			-- Main Fire
			for i = 1, 3 do
				local p = self.emitter:Add("particles/flamelet" .. math.random(1, 5), firepos + VectorRand() * 4)
				if (p) then
					p:SetVelocity(up * math.Rand(40, 70) + VectorRand() * 10)
					p:SetDieTime(math.Rand(0.5, 0.8))
					p:SetStartAlpha(200)
					p:SetEndAlpha(0)
					p:SetStartSize(math.Rand(12, 18))
					p:SetEndSize(math.Rand(4, 7))
					p:SetRoll(math.Rand(0, 360))
					p:SetRollDelta(math.Rand(-10, 10))
					p:SetColor(255, 100 + math.random(50), 30)
					p:SetLighting(false)
				end
			end
			
			-- Embers
			if math.random(1, 4) == 1 then
				local p = self.emitter:Add("particles/flamelet" .. math.random(1, 5), firepos + VectorRand() * 2)
				if (p) then
					p:SetVelocity(up * math.Rand(50, 100) + VectorRand() * 15)
					p:SetDieTime(math.Rand(1, 2))
					p:SetStartAlpha(255)
					p:SetEndAlpha(0)
					p:SetStartSize(math.Rand(1, 2))
					p:SetEndSize(0)
					p:SetColor(255, 150, 50)
					p:SetGravity(Vector(0, 0, 30))
					p:SetAirResistance(50)
					p:SetLighting(false)
				end
			end

			-- Smoke
			if math.random(1, 4) == 1 then
				local p = self.emitter:Add("particle/smokesprites_000" .. math.random(1, 9), firepos + up * 15)
				if (p) then
					p:SetVelocity(up * math.Rand(30, 60) + VectorRand() * 10)
					p:SetDieTime(math.Rand(2, 4))
					p:SetStartAlpha(math.Rand(40, 90))
					p:SetEndAlpha(0)
					p:SetStartSize(math.Rand(5, 15))
					p:SetEndSize(math.Rand(50, 80))
					p:SetRoll(math.Rand(0, 360))
					p:SetRollDelta(math.Rand(-1, 1))
					p:SetColor(30, 30, 30)
					p:SetGravity(Vector(0, 0, 20))
					p:SetAirResistance(150)
				end
			end
			
			self.nextParticle = CurTime() + 0.05
		end
		
		-- Core Glow
		local size = 45 + math.sin(RealTime() * 2) * 3
		render.SetMaterial(GLOW_MATERIAL)
		render.DrawSprite(firepos + up * 10, size, size, Color(255, 100, 0, 150))
		render.DrawSprite(firepos + up * 5, size * 0.5, size * 0.5, Color(255, 200, 150, 200))
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

		local fuel = stove:AddRow("fuel")
		fuel:SetText(L("fuelStatus", math.ceil(self:GetNetVar("fuel", 0) / 60)))
		fuel:SizeToContents()

		local fuelCount = stove:AddRow("fuelCount")
		fuelCount:SetText(L("fuelCountStatus", self:GetNetVar("fuelCount", 0), self:GetNetVar("fuelMax", 10)))
		fuelCount:SizeToContents()
	end
end
