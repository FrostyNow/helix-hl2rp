
ITEM.name = "Gunpowder"
ITEM.description = "itemGunpowderDesc"
ITEM.price = 4
ITEM.model = "models/props_lab/box01a.mdl"
ITEM.isjunk = true

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end