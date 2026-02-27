ITEM.name = "Manhack Parts"
ITEM.model = "models/gibs/manhack_gib01.mdl"
ITEM.description = "itemManhackPartsDesc"
ITEM.isjunk = true

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end