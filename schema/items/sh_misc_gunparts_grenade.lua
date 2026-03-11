
ITEM.name = "Grenade cylinder"
ITEM.description = "itemGrenadeCylinderDesc"
ITEM.price = 3
ITEM.model = "models/weapons/w_grenade.mdl"
ITEM.isjunk = true
ITEM.isStackable = false

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end