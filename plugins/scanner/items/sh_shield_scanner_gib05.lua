ITEM.name = "Shield Scanner Parts"
ITEM.model = "models/gibs/shield_scanner_gib5.mdl"
ITEM.description = "itemShieldScannerPartsDesc"
ITEM.price = 5
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
