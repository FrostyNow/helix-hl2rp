
ENT.Type = "anim"
ENT.PrintName = "Radio Jammer"
ENT.Author = "Frosty"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Helix"
ENT.RenderGroup = RENDERGROUP_BOTH

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_lab/reciever01b.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetNetVar("active", false)
		self:SetNetVar("radius", 512)
		self:SetNetVar("strength", 100)
		self:SetUseType(SIMPLE_USE)

		local physicsObject = self:GetPhysicsObject()

		if (IsValid(physicsObject)) then
			physicsObject:Wake()
		end
	end

	function ENT:Use(activator)
		self:SetNetVar("active", !self:GetNetVar("active", false))
		
		if (self:GetNetVar("active")) then
			self:EmitSound("buttons/combine_button1.wav")
			self.humSound = self:StartLoopingSound("ambient/energy/force_field_loop1.wav")
		else
			self:EmitSound("buttons/combine_button2.wav")
			if (self.humSound) then
				self:StopLoopingSound(self.humSound)
				self.humSound = nil
			end
		end
	end

	function ENT:OnRemove()
		if (self.humSound) then
			self:StopLoopingSound(self.humSound)
		end
	end
else
	function ENT:OnPopulateEntityInfo(container)
		local name = container:AddRow("name")
		name:SetImportant()
		name:SetText(L("Radio Jammer"))
		name:SizeToContents()

		local desc = container:AddRow("desc")
		desc:SetText(L("radioJammerDesc"))
		desc:SizeToContents()

		local status = container:AddRow("status")
		status:SetText(self:GetNetVar("active") and "Active" or "Inactive")
		status:SetBackgroundColor(self:GetNetVar("active") and Color(0, 255, 0, 50) or Color(255, 0, 0, 50))
		status:SizeToContents()
		
		status.Think = function(panel)
			local isActive = self:GetNetVar("active")
			panel:SetText(isActive and "Active" or "Inactive")
			panel:SetBackgroundColor(isActive and Color(0, 255, 0, 50) or Color(255, 0, 0, 50))
			panel:SizeToContents()
		end

		if (self:GetNetVar("active")) then
			local radius = container:AddRow("radius")
			radius:SetText("Radius: " .. self:GetNetVar("radius", 512) .. " units")
			radius:SizeToContents()
		end
	end

	local GLOW_MATERIAL = Material("sprites/glow04_noz")
	local COLOR_ACTIVE = Color(255, 100, 0)
	local COLOR_INACTIVE = Color(50, 50, 50)

	function ENT:Draw()
		self:DrawModel()

		if (self:GetNetVar("active")) then
			local position = self:GetPos() + self:GetUp() * 8
			render.SetMaterial(GLOW_MATERIAL)
			render.DrawSprite(position, 16, 16, COLOR_ACTIVE)
		end
	end
end
