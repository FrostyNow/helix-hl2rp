include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	
	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:Wake()
		phys:EnableMotion(false)
	end

	-- Default health
	self:SetMaxHealth(200)
	self:SetHealth(200)
end

function ENT:OnTakeDamage(damage)
	-- Only take damage from explosions
	if (!damage:IsDamageType(DMG_BLAST)) then
		return
	end

	self:SetHealth(self:Health() - damage:GetDamage())

	if (self:Health() <= 0) then
		self:OnBreak()
	end
end

function ENT:OnBreak()
	if (self.bBroken) then return end
	self.bBroken = true

	local pos = self:GetPos()
	local ang = self:GetAngles()
	local model = self:GetModel()
	local skin = self:GetSkin()

	-- Replacement physics prop
	local prop = ents.Create("prop_physics")
	prop:SetModel(model)
	prop:SetPos(pos)
	prop:SetAngles(ang)
	prop:SetSkin(skin)
	prop:Spawn()
	
	-- Apply some force to make it "fall over"
	local phys = prop:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:Wake()
		phys:ApplyForceCenter(VectorRand() * 500)
	end

	-- Explosion effect
	local explosion = ents.Create("env_explosion")
	explosion:SetPos(pos)
	explosion:SetOwner(self)
	explosion:Spawn()
	explosion:SetKeyValue("iMagnitude", "50")
	explosion:Fire("Explode", 0, 0)

	-- Sound effect
	self:EmitSound("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav")

	self:Remove()
end

function ENT:Use(activator)
end
