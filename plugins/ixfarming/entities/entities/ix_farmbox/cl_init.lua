include("shared.lua")

ENT.PopulateEntityInfo = true

function ENT:OnPopulateEntityInfo(tooltip)
	local title = tooltip:AddRow("name")
	title:SetText(L("farmBox"))
	title:SetImportant()
	title:SizeToContents()

	local desc = tooltip:AddRow("desc")
	desc:SetText(L("farmBoxDesc"))
	desc:SizeToContents()

	local condition = tooltip:AddRow("condition")
	if (self:GetCropType() == "") then
		if (self:GetHasPesticide()) then
			condition:SetText(L("farmBoxPoisoned"))
			condition:SetBackgroundColor(Color(150, 50, 200))
		else
			condition:SetText(L("farmBoxEmpty"))
		end
		condition:SizeToContents()
	end
end

function ENT:Draw()
	self:DrawModel()
end
