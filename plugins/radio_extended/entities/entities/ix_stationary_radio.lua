
ENT.Type = "anim"
ENT.PrintName = "Stationary Radio"
ENT.Author = "Frosty"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Helix"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

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
		if (self:GetNetVar("active", false)) then
			netstream.Start(activator, "ixStationaryRadioMenu", self)
		else
			self:SetNetVar("active", true)
			self:EmitSound("radio/radio_on.ogg")
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

	function ENT:PopulateContextMenu(container)
		if (self:GetNetVar("active", false)) then
			container:AddOption(L("itemRadioMenuFreqTitle"), function()
				Derma_StringRequest(L("itemRadioMenuFreqTitle"), L("itemRadioMenuFreqDesc"), self:GetNetVar("frequency", "100.0"), function(text)
					ix.command.Send("SetFreq", text)
				end)
			end):SetIcon("icon16/transmit.png")

		end

		container:AddOption(L("Activate"), function()
			netstream.Start("ixStationaryRadioAction", self, "off")
		end):SetIcon("icon16/disconnect.png")
	end
end
