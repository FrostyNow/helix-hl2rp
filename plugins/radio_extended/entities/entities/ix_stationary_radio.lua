
ENT.Type = "anim"
ENT.PrintName = "Stationary Radio"
ENT.Author = "Antigravity"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Helix"
ENT.RenderGroup = RENDERGROUP_BOTH

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_lab/citizenradio.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetNetVar("active", false)
		self:SetNetVar("frequency", "100.0")
		self:SetUseType(SIMPLE_USE)

		local physicsObject = self:GetPhysicsObject()

		if (IsValid(physicsObject)) then
			physicsObject:Wake()
		end
	end

	function ENT:Use(activator)
		self:SetNetVar("active", !self:GetNetVar("active", false))
		
		if (self:GetNetVar("active")) then
			self:EmitSound("buttons/button1.wav")
		else
			self:EmitSound("buttons/button19.wav")
		end
	end
else
	local GLOW_MATERIAL = Material("sprites/glow04_noz")
	local COLOR_ACTIVE = Color(0, 255, 0)
	local COLOR_INACTIVE = Color(255, 0, 0)

	function ENT:Draw()
		self:DrawModel()

		local position = self:GetPos() + self:GetForward() * 10 + self:GetUp() * 11 + self:GetRight() * 9.5

		render.SetMaterial(GLOW_MATERIAL)
		render.DrawSprite(position, 14, 14, self:GetNetVar("active") and COLOR_ACTIVE or COLOR_INACTIVE)
	end
	
	function ENT:OnPopulateEntityInfo(container)
		local name = container:AddRow("name")
		name:SetImportant()
		name:SetText(L("Stationary Radio"))
		name:SizeToContents()

		local desc = container:AddRow("desc")
		desc:SetText(L("stationaryRadioDesc"))
		desc:SizeToContents()

		local freq = container:AddRow("freq")
		freq:SetText(self:GetNetVar("frequency", "100.0") .. " MHz")
		freq:SetBackgroundColor(Color(85, 127, 242, 50))
		freq:SizeToContents()
		
		freq.Think = function(panel)
			panel:SetText(self:GetNetVar("frequency", "100.0") .. " MHz")
			panel:SizeToContents()
		end

		local status = container:AddRow("status")
		status:SetText(self:GetNetVar("active") and L("radioOn") or L("radioOff"))
		status:SetBackgroundColor(self:GetNetVar("active") and Color(0, 255, 0, 50) or Color(255, 0, 0, 50))
		status:SizeToContents()
		
		status.Think = function(panel)
			local isActive = self:GetNetVar("active")
			panel:SetText(isActive and L("radioOn") or L("radioOff"))
			panel:SetBackgroundColor(isActive and Color(0, 255, 0, 50) or Color(255, 0, 0, 50))
			panel:SizeToContents()
		end
	end
end
