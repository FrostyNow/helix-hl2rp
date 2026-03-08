ITEM.name = "Scanner Parts"
ITEM.model = "models/gibs/scanner_gib04.mdl"
ITEM.description = "itemScannerPartsDesc"
ITEM.price = 20
ITEM.isjunk = true
ITEM.isStackable = true

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end