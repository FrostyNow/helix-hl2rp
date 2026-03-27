include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:Initialize()
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	
	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:Wake()
		phys:EnableMotion(false)
	end

	-- Initialize health based on price (after a small delay to ensure DataTables are synced)
	timer.Simple(0.1, function()
		if (!IsValid(self)) then return end

		local furnitureID = tonumber(self:GetFurnitureID())
		local plugin = ix.plugin.list["ixfurniture"]
		
		if (plugin and plugin.FurnitureList[furnitureID]) then
			local price = plugin.FurnitureList[furnitureID].price or 100
			local hp = math.max(100, price)
			
			self:SetMaxHealth(hp)
			self:SetHealth(hp)
		else
			self:SetMaxHealth(100)
			self:SetHealth(100)
		end
	end)
end

function ENT:OnTakeDamage(damage)
	self:SetHealth(self:Health() - damage:GetDamage())

	if (self:Health() <= 0) then
		self:OnBreak()
	end
end

function ENT:OnBreak()
	local pos = self:GetPos()
	
	-- Sound effect
	self:EmitSound("physics/wood/wood_panel_break" .. math.random(1, 2) .. ".wav")
	
	-- Effect
	local effect = EffectData()
	effect:SetOrigin(pos)
	effect:SetScale(1)
	util.Effect("GlassImpact", effect) -- Simple debris effect

	self:Remove()
end

function ENT:Use(activator)
end
