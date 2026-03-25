include("shared.lua")

ENT.PopulateEntityInfo = true

function ENT:OnPopulateEntityInfo(tooltip)
	local title = tooltip:AddRow("name")
	title:SetImportant()
	
	if (self:GetCropType() == "") then
		title:SetText(L("farmBoxEmpty"))
	else
		title:SetText(L("farmBox"))
	end
	title:SizeToContents()
end

function ENT:Draw()
	self:DrawModel()
end
