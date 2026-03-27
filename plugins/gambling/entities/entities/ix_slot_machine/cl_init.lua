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
	price:SetText(L("price") .. ": " .. ix.currency.Get(ix.config.Get("gamblingPrice", 30)))
	price:SetBackgroundColor(Color(255, 165, 0, 100)) -- Orange-ish background
	price:SizeToContents()
end