local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base 			= "base_gmodentity"
ENT.Type 			= "anim"
ENT.PrintName		= "Cloth"
ENT.Author			= "Riggs Mackay"
ENT.Purpose			= "Clean it dude."
ENT.Instructions	= "Press E"
ENT.Category 		= "HL2 RP: Laundry"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PopulateEntityInfo = true

ENT.Holdable = true

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Clean")
	self:NetworkVar("Float", 1, "ClothType")

	if ( SERVER ) then
		self:NetworkVarNotify("Clean", self.OnClothChangeState)
	end
end

if ( SERVER ) then
	function ENT:Initialize()
		self:SetModel("models/tnb/items/aphelion/shirt_citizen1.mdl")
		self:PhysicsInit(SOLID_VPHYSICS) 
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self.health = 50
		
		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
			phys:EnableMotion(true)
		end

		if not ( self:GetClean() ) then
			self:SetColor(Color(159, 159, 159))
			-- self:SetMaterial("models/props_c17/furniturefabric003a")
		else
			self:SetColor(Color(255, 255, 255))
			-- self:SetMaterial("models/debug/debugwhite")
		end

		if ( self:GetClothType() == 1 ) then
			self:SetSkin(1)
		elseif ( self:GetClothType() == 2 ) then
			self:SetSkin(2)
		end
	end

	function ENT:OnTakeDamage(damageInfo)
		self:SetHealth(self:Health() - damageInfo:GetDamage())

		if (self:Health() <= 0) then
			self:Remove()
		end
	end
else
	function ENT:OnPopulateEntityInfo(tooltip)
		local name = tooltip:AddRow("name")
		name:SetImportant()
		name:SetText(L("Laundry Cloth"))
		name:SetBackgroundColor(ix.config.Get("color"))
		name:SizeToContents()

		local description = tooltip:AddRow("description")
		description:SetText(L"laundryClothDesc")
		description:SizeToContents()

		local condition = tooltip:AddRow("condition")
		if ( self:GetClean() ) then
			condition:SetText(L"laundryClean")
			condition:SetBackgroundColor(Color(172, 179, 172))
		else
			condition:SetText(L"laundryDirty")
			condition:SetBackgroundColor(Color(121, 95, 77))
		end
		condition:SizeToContents()
	end
end
