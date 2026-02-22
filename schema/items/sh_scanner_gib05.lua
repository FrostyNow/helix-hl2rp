ITEM.name = "Scanner Parts"
ITEM.model = "models/gibs/scanner_gib05.mdl"
ITEM.description = "itemScannerPartsDesc"
ITEM.price = 70
ITEM.width = 2
ITEM.height = 2

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end