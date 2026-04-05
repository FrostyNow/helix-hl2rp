AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Suit Charger"
ENT.Author = "Frosty"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Category = "HL2 RP"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.PopulateEntityInfo = true

ENT.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ENT.denySound = Sound("items/suitchargeno1.wav")
ENT.useSound = Sound("items/suitchargeok1.wav")
ENT.chargeSound = "items/suitcharge1.wav"
ENT.restoreRate = 0.1
ENT.restoreAmount = 1
ENT.restoreCost = 0.03
ENT.restoreCool = 60

ix.lang.AddTable("english", {
	suitChargerDesc = "A device that automatically restores armor to the user.",
})

ix.lang.AddTable("korean", {
	["Suit Charger"] = "충전 장치",
	suitChargerDesc = "사용자의 장비에 전력을 공급하기 위한 충전 장치입니다.",
})

function ENT:GetUsed()
	return self:GetNetVar("used", 0)
end

function ENT:IsActive()
	return self:GetNetVar("active", false)
end

function ENT:GetClientMaxArmor(client)
	if (!IsValid(client)) then
		return 100
	end

	local maxArmor = client.GetMaxArmor and client:GetMaxArmor() or nil

	return math.max(maxArmor or 100, 0)
end

if (SERVER) then
	function ENT:SpawnFunction(client, trace, className)
		if (!trace.Hit or trace.HitSky) then return end

		local pos = trace.HitPos + trace.HitNormal * 1
		local ent = ents.Create(className)
		
		-- Grid-snapping logic
		local divider = 10
		for i = 1, 3 do
			pos[i] = math.Round(pos[i] / divider) * divider
		end
		
		ent:SetPos(pos)
		ent:Spawn()
		ent:SetAngles(trace.HitNormal:Angle())
		ent:Activate()

		return ent
	end

	function ENT:Initialize()
		self:SetModel("models/props_combine/suit_charger001.mdl")
		self:DrawShadow(false)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:SetNetVar("used", 0)
		self.rechargeTime = CurTime()
		self.rechargeSoundPlayed = false
		self.sessionUsed = 0
		
		self:SetAutomaticFrameAdvance(false)
		local idleSequence = self:LookupSequence("idle")

		self:ResetSequence((idleSequence and idleSequence >= 0) and idleSequence or 0)
		self:SetCycle(0)
		self:SetPlaybackRate(0)
		
		local phys = self:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:Wake()
			phys:EnableMotion()
		end

		timer.Simple(0, function()
			if (IsValid(self)) then
				self.loopSound = CreateSound(self, self.chargeSound)
			end
		end)
	end

	function ENT:OnRemove()
		if (self.loopSound) then
			self.loopSound:Stop()
		end
		
		if (IsValid(self.user)) then
			self.user.ixSuitCharging = nil
		end
	end

	function ENT:finishUse()
		self:SetNetVar("active", false)
		self.rechargeSoundPlayed = false
		
		if (self.loopSound) then
			self.loopSound:Stop()
		end
		self:EmitSound(self.denySound)

		if (IsValid(self.user)) then
			self.user.ixSuitCharging = nil
		end
		
		self.user = nil
		self.sessionUsed = 0
	end
	
	function ENT:Think()
		if (self:IsActive() and IsValid(self.user)) then
			local dist = self.user:GetPos():Distance(self:GetPos())
			local character = self.user:GetCharacter()
			local maxArmor = self:GetClientMaxArmor(self.user)

			if (dist > 96 or !self.user:KeyDown(IN_USE) or self:GetUsed() >= 1 or
				self.user:Armor() >= maxArmor or !character) then
				self:finishUse()
				return
			end

			self.user:SetArmor(math.min(self.user:Armor() + self.restoreAmount, maxArmor))
			
			local nextUsed = math.Clamp(self:GetUsed() + self.restoreCost, 0, 1)
			self.sessionUsed = self.sessionUsed + (nextUsed - self:GetUsed())
			
			self:SetNetVar("used", nextUsed)
			self.rechargeTime = CurTime() + self.restoreCool
			self.rechargeSoundPlayed = false
		else
			if (self.rechargeTime < CurTime()) then
				local currentUsed = self:GetUsed()
				local rechargeStep = self.restoreCost * 0.8
				local nextUsed = math.Clamp(currentUsed - rechargeStep, 0, 1)

				if (!self.rechargeSoundPlayed and nextUsed < currentUsed) then
					self:EmitSound(self.useSound)
					self.rechargeSoundPlayed = true
				end

				self:SetNetVar("used", nextUsed)
			end
		end

		self:NextThink(CurTime() + self.restoreRate)
		return true
	end

	function ENT:Use(client)
		local character = client:GetCharacter()
		local maxArmor = self:GetClientMaxArmor(client)

		if (!character) then return end

		local comkey = character:GetInventory():HasItem("comkey")
		if (!client:IsCombine() and !comkey) then
			self:EmitSound(self.denySound)
			return
		end

		if (!client.ixSuitCharging and !IsValid(self.user) and self:GetUsed() < 1 and client:Armor() < maxArmor) then
			client.ixSuitCharging = self
			self.user = client
			self.sessionUsed = 0
			self:SetNetVar("active", true)
			self.rechargeSoundPlayed = false

			if (self.loopSound) then
				self.loopSound:Play()
				self.loopSound:ChangeVolume(1, 0)
			end
			self:EmitSound(self.useSound)
		else
			self:EmitSound(self.denySound)
		end
	end
else
	local GLOW_MATERIAL = Material("particle/Particle_Glow_04_Additive.vmt")
	local COLOR_ACTIVE = Color(255, 100, 0, 50)
	local COLOR_INACTIVE = Color(255, 0, 0, 50)
	local SPINNER_BONE = "roundcap"
	local BAR_BONE = "healthbar"
	local SPINNER_BONE_FALLBACK = 1
	local BAR_BONE_FALLBACK = 2
	local ACTIVE_BOB_RANGE = 1.3
	local ACTIVE_BOB_SPEED = 12

	function ENT:Draw()
		self:UpdateBonePositions(FrameTime())
		self:DrawModel()
	end

	function ENT:Initialize()
		self.smoothUsed = self:GetUsed()
		self.lightPhase = 0
		self.spinnerBone = self:GetSpinnerBoneIndex()
		self.barBone = self:GetBarBoneIndex()
		self.rootBone = self:GetBoneName(0) and 0 or nil
		self.lastRootPos = nil
		self.lastRootAng = nil
	end

	function ENT:GetSpinnerBoneIndex()
		local bone = self:LookupBone(SPINNER_BONE)

		if (!bone or bone == -1) then
			bone = self:GetBoneName(SPINNER_BONE_FALLBACK) and SPINNER_BONE_FALLBACK or -1
		end

		return bone
	end

	function ENT:GetBarBoneIndex()
		local bone = self:LookupBone(BAR_BONE)

		if (!bone or bone == -1) then
			bone = self:GetBoneName(BAR_BONE_FALLBACK) and BAR_BONE_FALLBACK or -1
		end

		return bone
	end

	function ENT:UpdateBonePositions(ft)
		ft = ft or FrameTime()
		self.smoothUsed = math.Approach(self.smoothUsed or 0, self:GetUsed(), ft * (self.restoreRate + self.restoreCost) * 2)
		self.spinnerBone = self:GetSpinnerBoneIndex()
		self.barBone = self:GetBarBoneIndex()
		self.rootBone = self.rootBone or (self:GetBoneName(0) and 0 or nil)
		self:SetupBones()

		local drainedFraction = self.smoothUsed
		local rootPos
		local rootAng
		local rootMatrix = self.rootBone and self:GetBoneMatrix(self.rootBone) or nil

		if (rootMatrix) then
			rootPos = rootMatrix:GetTranslation()
			rootAng = rootMatrix:GetAngles()
		end

		if (!rootPos or !rootAng) then
			rootPos = self.lastRootPos
			rootAng = self.lastRootAng
		end

		if (!rootPos or !rootAng) then
			return
		end

		self.lastRootPos = rootPos
		self.lastRootAng = rootAng

		local up = rootAng:Up()
		local right = rootAng:Right()
		local forward = rootAng:Forward()

		if (self.spinnerBone and self.spinnerBone != -1) then
			local spinnerHeight = 6.5 - (1.4 * drainedFraction)

			if (drainedFraction >= 0.98) then
				spinnerHeight = 5.1
			elseif (self:IsActive()) then
				spinnerHeight = 5.2 + (math.sin(CurTime() * ACTIVE_BOB_SPEED) * ACTIVE_BOB_RANGE)
			end

			self:SetBonePosition(self.spinnerBone, rootPos + up * spinnerHeight - right * 7.8 - forward * 4.25, rootAng)
		end

		if (self.barBone and self.barBone != -1) then
			self:SetBonePosition(self.barBone, rootPos + up * 4 - forward * 4.3 - right * (drainedFraction * 6), rootAng)
		end
	end

	local MAX_LIGHT_DIST = 512 * 512

	function ENT:DrawTranslucent()
		-- Lighting culling based on distance below


		local position = self:GetPos() + self:GetForward() * 8 + self:GetUp() * 11 + self:GetRight() * 1
		local color = self:GetUsed() >= 1 and COLOR_INACTIVE or COLOR_ACTIVE

		-- Point 2: Fake Light (Glow Sprite) - always draw so it's visible from a distance
		render.SetMaterial(GLOW_MATERIAL)
		render.DrawSprite(position, 10, 10, color)

		-- Point 4: Performance - only create heavy dynamic light when the player is close
		if (EyePos():DistToSqr(position) <= MAX_LIGHT_DIST) then
			local dlight = DynamicLight(self:EntIndex())

			if (dlight) then
				dlight.pos = position
				dlight.r = color.r
				dlight.g = color.g
				dlight.b = color.b
				dlight.brightness = 2
				dlight.Decay = 1000
				dlight.Size = 64
				dlight.DieTime = CurTime() + 0.1
			end
		end
	end

	function ENT:OnPopulateEntityInfo(charger)
		local name = charger:AddRow("name")
		name:SetImportant()
		name:SetText(L("Suit Charger"))
		name:SizeToContents()

		local desc = charger:AddRow("desc")
		desc:SetText(L("suitChargerDesc"))
		desc:SizeToContents()
	end
end
