ITEM.name = "Scanner Parts"
ITEM.model = "models/gibs/scanner_gib05.mdl"
ITEM.description = "itemScannerPartsDesc"
ITEM.price = 3
ITEM.width = 2
ITEM.height = 2
ITEM.isjunk = true

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end