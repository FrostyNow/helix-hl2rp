include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:SpawnFunction(ply, tr, className)
	if (!tr.Hit) then return end

	local pos = tr.HitPos
	local ang = Angle(0, ply:GetAngles().y + 180, 0)

	local entity = ents.Create(className)
	entity:SetAngles(ang)
	entity:Spawn()
	entity:Activate()

	local mins, _ = entity:GetModelBounds()
	local center = entity:OBBCenter()
	local offset = entity:LocalToWorld(Vector(center.x, center.y, mins.z)) - entity:GetPos()

	entity:SetPos(pos - offset)

	return entity
end

function ENT:Initialize()
	self:SetModel("models/noble/limelight/farmbox.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:Wake()
		phys:EnableMotion(true)
	end

	self:SetCropType("")
	self:SetProgress(0)
	self:SetWaterAmount(0)
	self:SetHasFertilizer(false)
	self:SetWaterQuality(0)
end
function ENT:OnRemove()
	if (IsValid(self.cropEnt)) then
		self.cropEnt:Remove()
	end
end
function ENT:Think()
	local cropType = self:GetCropType()
	
	if (cropType != "") then
		if (!IsValid(self.cropEnt)) then
			self.cropEnt = ents.Create("ix_farmcrop")
			local center = self:OBBCenter()
			self.cropEnt:SetPos(self:LocalToWorld(Vector(center.x, center.y, 8)))
			self.cropEnt:SetAngles(self:GetAngles())
			self.cropEnt:Spawn()
			self.cropEnt:SetParent(self)
			self.cropEnt:SetFarmBox(self)

			local mdl = "models/props_junk/watermelon01.mdl"
			if (cropType == "carrot") then mdl = "models/noble/limelight/carrot_plant.mdl"
			elseif (cropType == "corn") then mdl = "models/noble/limelight/corn_plant.mdl"
			elseif (cropType == "potato") then mdl = "models/noble/limelight/potato_plant.mdl"
			elseif (cropType == "wheat") then mdl = "models/noble/limelight/wheat_plant.mdl" end
			
			self.cropEnt:SetModel(mdl)
			local phys = self.cropEnt:GetPhysicsObject()
			if (IsValid(phys)) then
				phys:Wake()
				phys:EnableMotion(false)
			end
		end

		local growthDays = ix.config.Get("cropGrowthDays", 3)
		local growthTime = growthDays * 24 * 60 * ix.config.Get("secondsPerMinute", 60)
		
		if (self:GetHasFertilizer()) then
			growthTime = growthTime / 2
		end
		
		-- Crop needs water to grow
		if (self:GetWaterAmount() > 0) then
			if (self:GetHasPesticide()) then
				-- If it has pesticide, it needs fertilizer to cure it
				if (self:GetHasFertilizer()) then
					self:SetHasPesticide(false)
					self:SetHasFertilizer(false) -- consume fertilizer to wash away pesticide
				end
			else
				self:SetProgress(math.min(self:GetProgress() + 1, growthTime))
			end
			
			-- Water drains over time (1 unit per in-game minute)
			local drainInterval = ix.config.Get("secondsPerMinute", 60)
			if (math.random(1, drainInterval) == 1) then
				self:SetWaterAmount(math.max(0, self:GetWaterAmount() - 1))
			end
		end
	else
		if (IsValid(self.cropEnt)) then
			self.cropEnt:Remove()
		end
	end

	self:NextThink(CurTime() + 1)
	return true
end

function ENT:Use(activator)
	if (self:GetCropType() != "") then
		local growthDays = ix.config.Get("cropGrowthDays", 3)
		local growthTime = growthDays * 24 * 60 * ix.config.Get("secondsPerMinute", 60)
		if (self:GetHasFertilizer()) then growthTime = growthTime / 2 end
		
		if (self:GetProgress() >= growthTime) then
			-- Harvest!
			local amount = 2
			if (self:GetWaterQuality() > 0) then
				local luck = activator:GetCharacter():GetAttribute("lck", 0)
				local lckMlt = ix.config.Get("luckMultiplier", 1)
				local chance = math.Clamp(self:GetWaterQuality() * 20 + luck * lckMlt, 0, 80)
				if (math.random(1, 100) <= chance) then
					amount = math.random(3, 5)
				end
			end
			
			local center = self:OBBCenter()
			for i = 1, amount do
				ix.item.Spawn(self:GetCropType(), self:LocalToWorld(Vector(center.x, center.y, 20 + i * 5)))
			end
			
			local cropName = "(?)"
			if (self:GetCropType() == "carrot") then cropName = L("cropCarrot", activator)
			elseif (self:GetCropType() == "corn") then cropName = L("cropCorn", activator)
			elseif (self:GetCropType() == "potato") then cropName = L("cropPotato", activator)
			elseif (self:GetCropType() == "wheat") then cropName = L("cropWheat", activator) end

			self:SetCropType("")
			self:SetProgress(0)
			self:SetHasFertilizer(false)
			self:SetWaterQuality(0)

			activator:NotifyLocalized("farmHarvestSuccess", cropName, amount)
		else
			if (self:GetWaterAmount() <= 0) then
				activator:NotifyLocalized("farmNeedsWater")
			else
				activator:NotifyLocalized("farmNotReady", math.Round((self:GetProgress() / growthTime) * 100))
			end
		end
	else
		activator:NotifyLocalized("farmNeedCrop")
	end
end
