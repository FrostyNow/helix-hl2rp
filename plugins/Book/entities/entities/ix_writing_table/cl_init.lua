include('shared.lua')

function ENT:Draw()
  self:DrawModel()
  local position = self:GetPos()
  local angles = self:GetAngles()
end																																																																																												

function ENT:OnPopulateEntityInfo(container)
		local name = container:AddRow("name")
		
		name:SetImportant()
		-- NOTE :: Need Add More Description Text
		name:SetText(L("writing_Table"))
		name:SizeToContents()

		-- NOTE :: Need Add More Description Text
		local desc = container:AddRow("desc")
		desc:SetText(L("writing_Table"))
		desc:SizeToContents()
end