include("shared.lua")

ENT.PopulateEntityInfo = true

local GLOW_MATERIAL = Material("sprites/glow04_noz")
local MAX_LIGHT_DIST = 512 * 512

function ENT:Draw()
	self:DrawModel()

	local bHasPairs = self:GetNetVar("hasPairs", false)
	local bOnCooldown = CurTime() < self:GetNetVar("nextUseTime", 0)
	local color = (bHasPairs and !bOnCooldown) and Color(0, 255, 0) or Color(255, 0, 0)
	local position = self:GetPos() + self:GetUp() * 4 + self:GetForward() * 4

	render.SetMaterial(GLOW_MATERIAL)
	render.DrawSprite(position, 10, 10, color)

	if (EyePos():DistToSqr(position) <= MAX_LIGHT_DIST) then
		local dlight = DynamicLight(self:EntIndex())

		if (dlight) then
			dlight.pos = position
			dlight.r = color.r
			dlight.g = color.g
			dlight.b = color.b
			dlight.brightness = 2
			dlight.Decay = 1000
			dlight.Size = 64
			dlight.DieTime = CurTime() + 0.1
		end
	end
end

function ENT:OnPopulateEntityInfo(tooltip)
	local name = tooltip:AddRow("name")
	name:SetImportant()
	name:SetText(L("Pager Button"))
	name:SizeToContents()

	local description = tooltip:AddRow("description")
	description:SetText(L("pagerButtonDesc"))
	description:SizeToContents()

	local usage = tooltip:AddRow("usage")
	usage:SetText(L("pagerButtonUsage"))
	usage:SetBackgroundColor(team.GetColor(FACTION_MPF))
	usage:SizeToContents()
end
