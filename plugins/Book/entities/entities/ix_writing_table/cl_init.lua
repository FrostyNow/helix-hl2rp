include('shared.lua')

function ENT:Draw()
  self:DrawModel()
  local position = self:GetPos()
  local angles = self:GetAngles()
end

function ENT:OnPopulateEntityInfo(container)
		local name = container:AddRow("name")
		name:SetImportant()
		name:SetText(L("Slot Machine"))
		name:SizeToContents()

		local desc = container:AddRow("desc")
		desc:SetText(L("slotMachineDesc"))
		desc:SizeToContents()

    local price = container:AddRow("price")
		price:SetText(ix.currency.Get(ix.config.Get("gamblingPrice", 13), LocalPlayer()))
		price:SetBackgroundColor(Color(207, 188, 79, 173))
		price:SizeToContents()
end