include("shared.lua")

local SCREEN_SCALE = 0.03
local ACTIVE_COLOR = Color(110, 255, 110, 240)
local DIM_COLOR = Color(25, 70, 25, 220)
local GLOW_MATERIAL = ix.util.GetMaterial("sprites/glow04_noz")

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawTranslucent()
	if (self:GetClass() != "ix_computer_civic_interface") then
		return
	end

	if (!self:GetNetVar("powered", false)) then
		return
	end

	local position = self:GetPos() + self:GetUp() * 33 + self:GetForward() * 2 + self:GetRight() * 13
	local color = Color(110, 255, 110)

	render.SetMaterial(GLOW_MATERIAL)
	render.DrawSprite(position, 10, 10, color)

	local dlight = DynamicLight(self:EntIndex())

	if (dlight) then
		dlight.pos = position
		dlight.r = color.r
		dlight.g = color.g
		dlight.b = color.b
		dlight.brightness = 2
		dlight.Decay = 1000
		dlight.Size = 128
		dlight.DieTime = CurTime() + 0.1
	end
end

function ENT:OnPopulateEntityInfo(container)
	local plugin = ix.plugin.Get("interactive_computers")
	local displayName = plugin and plugin:GetDisplayName(self:GetClass()) or L("interactiveComputer")
	local isInteractive = plugin and plugin:IsInteractiveComputer(self)
	local definition = plugin and plugin:GetComputerDefinition(self:GetClass())

	local name = container:AddRow("name")
	name:SetImportant()
	name:SetText(displayName)
	name:SizeToContents()

	local description = container:AddRow("description")
	description:SetText(L(isInteractive and "interactiveComputerDesc" or "interactiveComputerSupportDesc"))
	description:SizeToContents()

	if (isInteractive) then
		local action = container:AddRow("action")
		action:SetText(L("interactiveComputerUse"))
		action:SetBackgroundColor(Color(85, 127, 242, 50))
		action:SizeToContents()
	end
end
