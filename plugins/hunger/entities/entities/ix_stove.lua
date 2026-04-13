ENT.Type = "anim"
ENT.PrintName = "Stove"
ENT.Author = "Black Tea"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Helix"

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "FurnitureID")
	self:NetworkVar("String", 1, "OwnerName")
	self:NetworkVar("Int", 0, "OwnerCID")
end

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_c17/furnitureStove001a.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetNetVar("active", false)
		self:SetNetVar("broken", false)
		self:SetNetVar("fuel", 0)
		self:SetNetVar("fuelCount", 0)
		self:SetNetVar("fuelMax", 30)
		self:SetNetVar("igniter", 0)
		self.fuelList = {}
		self:SetUseType(SIMPLE_USE)

		local physicsObject = self:GetPhysicsObject()

		if (IsValid(physicsObject)) then
			physicsObject:Wake()
		end
	end

	function ENT:OnRemove()
	end

	function ENT:OnTakeDamage(damageInfo)
		self.fuelList = self.fuelList or {}
		if (damageInfo:IsDamageType(DMG_BURN) and #self.fuelList > 0) then
			local attacker = damageInfo:GetAttacker()
			local pos = self:GetPos()

			-- Consume all fuel and break the stove
			self.fuelList = {}
			self:UpdateFuelNetVars()
			self:SetNetVar("active", false)
			self:SetNetVar("broken", true)
			self:SetNetVar("igniter", 0)
			self:SetColor(Color(100, 100, 100))

			-- Small explosion effect
			local explode = ents.Create("env_explosion")
			if (IsValid(explode)) then
				explode:SetPos(pos)
				explode:SetOwner(attacker)
				explode:Spawn()
				explode:SetKeyValue("iMagnitude", "50")
				explode:Fire("Explode", 0, 0)
			end

			-- Blast damage (Approx 2m radius = 110 units)
			util.BlastDamage(self, IsValid(attacker) and attacker or self, pos, 110, 50)

			self:EmitSound("ambient/explosions/exp1.wav", 80, 100)
		end
	end

	function ENT:AddFuel(seconds)
		self.fuelList = self.fuelList or {}

		if (self:GetNetVar("broken", false)) then
			return false
		end

		if (#self.fuelList >= 30) then
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
		self:SetNetVar("fuelMax", 30)
	end

	function ENT:Use(activator)
		if (self:GetNetVar("broken", false)) then
			activator:NotifyLocalized("stoveBroken")
			return
		end

		local bActive = self:GetNetVar("active", false)
		local action = bActive and "extinguishing" or "lighting"

		if (!bActive) then
			local fuel = self:GetNetVar("fuel", 0)
			if (fuel <= 0) then
				activator:NotifyLocalized("needFuel")
				return
			end

			local igniter = self:GetNetVar("igniter", 0)
			if (igniter <= 0) then
				local hungerPlugin = ix.plugin.list["hunger"]
				if (!hungerPlugin:HasRemainingFireStarter(activator)) then
					activator:NotifyLocalized("needFireStarter")
					return
				end
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
				local igniter = self:GetNetVar("igniter", 0)
				if (igniter > 0) then
					self:SetNetVar("igniter", igniter - 1)
				else
					local hungerPlugin = ix.plugin.list["hunger"]
					local item = hungerPlugin:HasRemainingFireStarter(activator)

					if (!item) then
						activator:NotifyLocalized("needFireStarter")
						return
					end

					hungerPlugin:ConsumeFireStarter(item)
				end
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

		if (self:GetNetVar("broken", false)) then
			self:SetNetVar("active", false)
			return
		end

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
		end

		self:NextThink(CurTime() + 0.5)
		return true
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

			-- Lighting culling based on distance below


			-- Performance - only create heavy dynamic light when the player is close
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
			-- Sprite culling below


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

		local fuel = stove:AddRow("fuel")
		fuel:SetText(L("fuelStatus", math.ceil(self:GetNetVar("fuel", 0) / 60)))
		fuel:SizeToContents()

		local fuelCount = stove:AddRow("fuelCount")
		fuelCount:SetText(L("fuelCountStatus", self:GetNetVar("fuelCount", 0), self:GetNetVar("fuelMax", 30)))
		fuelCount:SizeToContents()

		if (self:GetNetVar("broken", false)) then
			local broken = stove:AddRow("broken")
			broken:SetText(L"stoveBroken")
			broken:SetBackgroundColor(Color(69, 14, 14))
			broken:SizeToContents()
		end
	end
end
