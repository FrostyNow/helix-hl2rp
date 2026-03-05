
ITEM.name = "Binoculars"
ITEM.model = "models/customstuff/binoculars.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.iconCam = {
	pos = Vector(705.3, 591.82, 464.45),
	ang = Angle(26.77, 219.94, 0),
	fov = 0.6
}
ITEM.exRender = true
ITEM.category = "Utility"
ITEM.description = "itemBinocularsDesc"
ITEM.price = 100

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end