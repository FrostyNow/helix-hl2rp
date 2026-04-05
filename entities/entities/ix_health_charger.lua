AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Health Charger"
ENT.Author = "Black Tea"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Category = "HL2 RP"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.PopulateEntityInfo = true

ENT.denySound = Sound("items/medshotno1.wav")
ENT.useSound = Sound("items/medshot4.wav")
ENT.chargeSound = "items/medcharge4.wav"
ENT.grubConsumeSound = {"npc/antlion_grub/agrub_die1.wav", "npc/antlion_grub/agrub_die2.wav"}
ENT.restoreRate = 0.1
ENT.restoreAmount = 1
ENT.restoreCost = 0.03
ENT.restoreCool = 5
ENT.freeChargeAmount = 100
ENT.grubConsumeRadius = 24

ix.lang.AddTable("english", {
	healthChargerDesc = "A medical device that automatically injects green solution to heal the user.",
	healthChargerFreeCharge = "Free charge remaining: %s HP",
	healthChargerPaidCharge = "Paid charge cost: %s per %s HP",
	healthChargerPay = "You paid %s for medical care.",
	healthChargerNoMoney = "You don't have enough money for medical care."
})

ix.lang.AddTable("korean", {
	["Health Charger"] = "자동화 의료 장치",
	healthChargerDesc = "녹색 용액을 자동 주입하여 사용자를 치료하는 기계장치입니다.",
	healthChargerFreeCharge = "남은 무료 충전량: %s HP",
	healthChargerPaidCharge = "유료 충전 비용: %s / %s HP",
	healthChargerPay = "의료 서비스 비용으로 %s을(를) 지불했습니다.",
	healthChargerNoMoney = "의료 서비스를 이용하기 위한 돈이 부족합니다."
})

function ENT:GetUsed()
	return self:GetNetVar("used", 0)
end

function ENT:GetFreeCharge()
	return self:GetNetVar("freeCharge", 0)
end

function ENT:IsActive()
	return self:GetNetVar("active", false)
end

function ENT:GetCostPerHealth()
	return self.restoreAmount > 0 and (self.restoreCost / self.restoreAmount) or 0
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
		self:SetModel("models/ccr/props/health_charger.mdl")
		self:DrawShadow(false)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:SetNetVar("used", 0)
		self:SetNetVar("freeCharge", 0)
		self.rechargeTime = CurTime()
		self.sessionPaidUsed = 0
		self.nextGrubScan = 0
		self.vialIndex = self:FindBodygroupByName("Vial")

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
			self.user.ixHealthCharging = nil
		end
	end

	function ENT:SetFreeCharge(amount)
		self:SetNetVar("freeCharge", math.max(amount, 0))
	end

	function ENT:IsFreeUseAvailable(amount)
		return self:GetFreeCharge() >= (amount or self.restoreAmount)
	end

	function ENT:CanConsumeGrubEntity(entity)
		if (!IsValid(entity) or entity:GetClass() != "ix_item" or entity.ixHealthChargerConsumed) then
			return false
		end

		local itemTable = entity.GetItemTable and entity:GetItemTable()

		if (!itemTable) then
			return false
		end

		return itemTable.uniqueID == "antlion_grub" or itemTable.name == "Antlion Grub"
	end

	function ENT:ConsumeGrubEntity(entity)
		if (!self:CanConsumeGrubEntity(entity)) then
			return false
		end

		entity.ixHealthChargerConsumed = true

		local itemTable = entity:GetItemTable()

		self:SetFreeCharge(self:GetFreeCharge() + self.freeChargeAmount)

		-- Sound and bodygroup changes moved to Think when charging actually starts

		itemTable:Remove()

		if (IsValid(entity)) then
			entity:Remove()
		end
		
		if (self.vialIndex != -1) then
			self:SetBodygroup(self.vialIndex, 1)
		end

		return true
	end

	function ENT:ConsumeNearbyGrub()
		if (self.nextGrubScan > CurTime()) then
			return false
		end

		self.nextGrubScan = CurTime() + 0.2

		for _, entity in ipairs(ents.FindInSphere(self:GetPos(), self.grubConsumeRadius)) do
			if (self:ConsumeGrubEntity(entity)) then
				return true
			end
		end

		return false
	end

	function ENT:finishUse()
		self:SetNetVar("active", false)
		
		if (self.loopSound) then
			self.loopSound:Stop()
		end
		self:EmitSound(self.denySound)

		if (IsValid(self.user)) then
			local character = self.user:GetCharacter()
			
			if (character and self.sessionPaidUsed > 0) then
				local cost = math.min(math.Round(self.sessionPaidUsed * 100), character:GetMoney())
				
				if (cost > 0) then
					character:TakeMoney(cost)
					self.user:Notify(L("healthChargerPay", self.user, ix.currency.Get(cost)))
				end
			end
			
			self.user.ixHealthCharging = nil
		end
		
		self.user = nil
		self.sessionPaidUsed = 0
		self.beganCharging = false
	end
	
	function ENT:Think()
		self:ConsumeNearbyGrub()

		if (self:IsActive() and IsValid(self.user)) then
			local dist = self.user:GetPos():Distance(self:GetPos())
			local character = self.user:GetCharacter()
			local nextPaidUse = math.max(self.restoreAmount - self:GetFreeCharge(), 0) * self:GetCostPerHealth()
			local nextCost = math.Round((self.sessionPaidUsed + nextPaidUse) * 100)

			if (dist > 96 or !self.user:KeyDown(IN_USE) or self:GetUsed() >= 1 or
				self.user:Health() >= self.user:GetMaxHealth() or !character or character:GetMoney() < nextCost) then
				self:finishUse()
				return
			end

			local previousHealth = self.user:Health()
			local nextHealth = math.min(previousHealth + self.restoreAmount, self.user:GetMaxHealth())
			local restored = math.max(nextHealth - previousHealth, 0)

			self.user:SetHealth(nextHealth)

			if (restored > 0 and ix.plugin.list["badair"]) then
				local toxicity = self.user:GetLocalVar("toxicity", 0)

				if (toxicity > 0) then
					self.user:SetLocalVar("toxicity", math.Clamp(toxicity - restored, 0, 100))
				end
			end

			if (restored > 0 and !self.beganCharging) then
				self.beganCharging = true

				if (self.grubConsumeSound) then
					local sound = self.grubConsumeSound

					if (istable(sound)) then
						sound = table.Random(sound)
					end

					if (sound != "") then
						self:EmitSound(sound)
					end
				end
			end
			
			local nextUsed = math.Clamp(self:GetUsed() + self.restoreCost, 0, 1)
			local freeCharge = self:GetFreeCharge()
			local freeConsumed = math.min(restored, freeCharge)
			local paidRestored = restored - freeConsumed

			if (freeConsumed > 0) then
				self:SetFreeCharge(freeCharge - freeConsumed)
			end

			if (self.vialIndex != -1) then
				local vialState = self:GetBodygroup(self.vialIndex)
				local freeCharge = self:GetFreeCharge()

				if (vialState > 0) then
					if (freeCharge < 1) then
						self:SetBodygroup(self.vialIndex, 0)

						local position = self:GetPos() + self:GetForward() * 5
						ix.item.Spawn("antlion_grub_empty", position)
					elseif (freeCharge <= 30 and vialState != 3) then
						self:SetBodygroup(self.vialIndex, 3)
					elseif (vialState == 1 and self.beganCharging) then
						self:SetBodygroup(self.vialIndex, 2)
					end
				end
			end

			if (paidRestored > 0) then
				self.sessionPaidUsed = self.sessionPaidUsed + paidRestored * self:GetCostPerHealth()
			end
			
			self:SetNetVar("used", nextUsed)
			self.rechargeTime = CurTime() + self.restoreCool
		else
			if (self.rechargeTime < CurTime()) then
				self:SetNetVar("used", math.Clamp(self:GetUsed() - self.restoreCost * 0.8, 0, 1))
			end
		end

		self:NextThink(CurTime() + self.restoreRate)
		return true
	end

	function ENT:Use(client)
		local character = client:GetCharacter()
		local minCost = math.Round(self.restoreCost * 100)

		if (!client.ixHealthCharging and !IsValid(self.user) and self:GetUsed() < 1 and client:Health() < client:GetMaxHealth()) then
			if (character and !self:IsFreeUseAvailable() and character:GetMoney() < minCost) then
				client:Notify(L("healthChargerNoMoney", client))
				self:EmitSound(self.denySound)

				return
			end

			client.ixHealthCharging = self
			self.user = client
			self.sessionPaidUsed = 0
			self:SetNetVar("active", true)

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
	function ENT:Draw()
		self:DrawModel()
	end

	function ENT:Initialize()
		self.smoothUsed = 0
		self.lastDisplayedFreeCharge = nil
	end

	function ENT:RefreshEntityInfo()
		local panel = ix.gui.entityInfo

		if (!IsValid(panel) or panel:GetEntity() != self) then
			return
		end

		panel:Remove()

		local infoPanel = vgui.Create(ix.option.Get("minimalTooltips", false) and "ixTooltipMinimal" or "ixTooltip")
		infoPanel:SetEntity(self)
		infoPanel:SetDrawArrow(true)
		ix.gui.entityInfo = infoPanel
	end

	local light = 0
	local GLOW_MATERIAL = Material("particle/Particle_Glow_04_Additive.vmt")
	local COLOR_ACTIVE = Color(0, 255, 255, 50)
	local COLOR_INACTIVE = Color(255, 0, 0, 50)

	local MAX_LIGHT_DIST = 512 * 512

	function ENT:DrawTranslucent()
		-- Lighting culling based on distance below


		local ft = FrameTime()
		local idxHealth = self:LookupBone("healthbar")
		local idxSpinner = self:LookupBone("roundcap")
		local displayedFreeCharge = math.floor(self:GetFreeCharge())

		if (self.lastDisplayedFreeCharge != displayedFreeCharge) then
			self.lastDisplayedFreeCharge = displayedFreeCharge
			self:RefreshEntityInfo()
		end

		self.smoothUsed = math.Approach(self.smoothUsed, self:GetUsed(), ft * (self.restoreRate + self.restoreCost) * 2)

		if (idxSpinner and idxSpinner != -1) then
			self:ManipulateBoneAngles(idxSpinner, Angle(0, self.smoothUsed * 250, 0))
			self:ManipulateBonePosition(idxSpinner, Vector(0, 0, -4 * self.smoothUsed))
		end

		if (idxHealth and idxHealth != -1) then
			self:ManipulateBonePosition(idxHealth, Vector(1 + (-8 * self.smoothUsed), 0, 0))
		end

		local position = self:GetPos() + self:GetForward() * 7.5 + self:GetUp() * -0.5 + self:GetRight() * 2.5
		local color = self:GetUsed() >= 1 and COLOR_INACTIVE or COLOR_ACTIVE

		-- Fake Light (Glow Sprite) - always draw so it's visible from a distance
		render.SetMaterial(GLOW_MATERIAL)
		render.DrawSprite(position, 10, 10, color)

		-- Performance - only create heavy dynamic light when the player is close
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
		name:SetText(L("Health Charger"))
		name:SizeToContents()

		local desc = charger:AddRow("desc")
		desc:SetText(L("healthChargerDesc"))
		desc:SizeToContents()

		local freeCharge = math.floor(self:GetFreeCharge())

		if (freeCharge > 0) then
			local bonus = charger:AddRow("freeCharge")
			bonus:SetText(L("healthChargerFreeCharge", freeCharge))
			bonus:SetBackgroundColor(Color(85, 127, 242, 50))
			bonus:SizeToContents()
		else
			local paidCharge = charger:AddRow("paidCharge")
			paidCharge:SetText(L("healthChargerPaidCharge", ix.currency.Get(math.Round(self:GetCostPerHealth() * 100)), self.restoreAmount))
			paidCharge:SetBackgroundColor(Color(85, 127, 242, 50))
			paidCharge:SizeToContents()
		end
	end
end
