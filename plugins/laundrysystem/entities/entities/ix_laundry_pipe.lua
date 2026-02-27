local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base 			= "base_gmodentity"
ENT.Type 			= "anim"
ENT.PrintName		= "Laundry Pipe"
ENT.Author			= "Riggs Mackay"
ENT.Purpose			= "Clean it dude."
ENT.Instructions	= "Press E"
ENT.Category 		= "HL2 RP: Laundry"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PopulateEntityInfo = true

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "ClothesNumber")
end

if ( SERVER ) then
	function ENT:Initialize()
		self:SetModel("models/props_pipes/pipe03_45degree01.mdl")
		self:PhysicsInit(SOLID_VPHYSICS) 
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		
		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
			phys:EnableMotion(false)
		end
	end

	function ENT:Use(activator, ply)
		if ((self.nextUse or 0) > CurTime()) then
			return
		end

		if not (PLUGIN:CanUseLaundry(ply)) then
			ply:NotifyLocalized("laundryNoAccess")
			return
		end

		if (self:GetClothesNumber() >= 6) then
			ply:NotifyLocalized("laundryPipeFull")
			return
		end

		local pos = self:LocalToWorld(self:OBBCenter())
		local ang = self:GetAngles()

		local cloth = ents.Create("ix_cloth")
		if not cloth:IsValid() then return end
		cloth:SetPos(pos + (ang:Forward() * 30))
		cloth:SetAngles(self:GetAngles())

		if ( math.random(1, 4) == 4 ) then
			cloth:SetClothType(2)
		else
			cloth:SetClothType(1)
		end

		cloth:SetClean(false)
		cloth:Spawn()
		self:EmitSound("doors/vent_open"..math.random(1, 3)..".wav", 60)

		self.nextUse = CurTime() + ix.config.Get("laundryDirtyDelay", 120)
	end

	function ENT:Think()
		local count = 0
		local pos = self:GetPos()

		for _, ent in pairs(ents.FindInSphere(pos, 300)) do
			if (ent:GetClass() == "ix_cloth" and not ent:GetClean()) then
				count = count + 1
			end
		end

		self:SetClothesNumber(count)
		self:NextThink(CurTime() + 1)
		return true
	end
else
	function ENT:OnPopulateEntityInfo(tooltip)
		local name = tooltip:AddRow("name")
		name:SetImportant()
		name:SetText(L("Laundry Pipe"))
		name:SetBackgroundColor(ix.config.Get("color"))
		name:SizeToContents()

		local description = tooltip:AddRow("description")
		description:SetText(L"laundryPipeDesc")
		description:SizeToContents()
	end
end
