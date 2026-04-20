include("shared.lua")

ENT.PopulateEntityInfo = true

function ENT:OnPopulateEntityInfo(tooltip)
	local title = tooltip:AddRow("name")
	title:SetImportant()
	title:SetText(L(self.PrintName))
	title:SetBackgroundColor(ix.config.Get("color"))
	title:SizeToContents()

	local description = tooltip:AddRow("description")
	description:SetText(L("ammoCrateDesc"))
	description:SizeToContents()
end
