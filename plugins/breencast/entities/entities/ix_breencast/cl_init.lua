include("shared.lua")

ENT.PopulateEntityInfo = true

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	self:FrameAdvance(FrameTime())
	self:SetNextClientThink(CurTime())

	return true
end

function ENT:OnPopulateEntityInfo(tooltip)
	local name = tooltip:AddRow("name")
	name:SetImportant()
	name:SetText(L("Dr. Wallace Breen"))
	name:SizeToContents()

	local desc = tooltip:AddRow("desc")
	desc:SetText(L("breenDesc"))
	desc:SizeToContents()

	local client = LocalPlayer()
	if (client:IsAdmin()) then
		local hint = tooltip:AddRow("hint")
		hint:SetText(L("breenCastUseHint"))
		hint:SetBackgroundColor(team.GetColor(FACTION_MPF))
		hint:SizeToContents()
	end

	tooltip:SizeToContents()
end