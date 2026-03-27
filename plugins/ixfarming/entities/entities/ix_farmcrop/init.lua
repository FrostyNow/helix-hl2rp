include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:Wake()
		phys:EnableMotion(false)
	end

	self:SetMaxHealth(200)
	self:SetHealth(200)
end

function ENT:Use(activator)
	local farmBox = self:GetFarmBox()
	if (IsValid(farmBox)) then
		farmBox:Use(activator, self, USE_ON, 0)
	end
end

function ENT:OnTakeDamage(dmg)
	if (dmg:IsDamageType(DMG_BURN) or dmg:IsDamageType(DMG_BLAST)) then
		local farmBox = self:GetFarmBox()

		if (IsValid(farmBox) and farmBox:GetCropType() != "") then
			local damage = dmg:GetDamage()
			self:SetHealth(self:Health() - damage)
			self.lastDamageTime = CurTime()

			if (self:Health() <= 0) then
				farmBox:SetCropType("")
				farmBox:SetProgress(0)
				farmBox:SetHasFertilizer(false)
				farmBox:SetHasPesticide(false)
				farmBox:SetWaterQuality(0)
				farmBox:SetWaterAmount(0)

				self:Remove()
			end
		end
	else
		dmg:SetDamage(0)
	end
end

function ENT:Think()
	if (self.lastDamageTime and (CurTime() - self.lastDamageTime) >= 300) then
		local maxHealth = self:GetMaxHealth()

		if (self:Health() < maxHealth) then
			self:SetHealth(maxHealth)
		end

		self.lastDamageTime = nil
	end

	self:NextThink(CurTime() + 1)
	return true
end
