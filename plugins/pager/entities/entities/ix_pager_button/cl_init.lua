include("shared.lua")

function ENT:Draw()
	self:DrawModel()

	local bHasPairs = self:GetNetVar("hasPairs", false)
	local color = bHasPairs and Color(0, 255, 0) or Color(255, 0, 0)
	local dlight = DynamicLight(self:EntIndex())

	if (dlight) then
		dlight.pos = self:GetPos() + self:GetUp() * 4 + self:GetForward() * 2
		dlight.r = color.r
		dlight.g = color.g
		dlight.b = color.b
		dlight.brightness = 2
		dlight.Decay = 1000
		dlight.Size = 64
		dlight.DieTime = CurTime() + 1
	end
end

function ENT:OnPopulateTooltip(tooltip)
	local name = tooltip:AddRow("name")
	name:SetImportant()
	name:SetText(L("pagerButton"))

	local description = tooltip:AddRow("description")
	description:SetText(L("pagerButtonDesc"))

	local usage = tooltip:AddRow("usage")
	usage:SetText(L("pagerButtonUsage"))
	usage:SetBackgroundColor(team.GetColor(FACTION_MPF))
end
