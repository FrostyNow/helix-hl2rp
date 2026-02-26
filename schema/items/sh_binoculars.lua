
ITEM.name = "Binoculars"
ITEM.model = Model("models/gibs/shield_scanner_gib1.mdl")
ITEM.category = "Utility"
ITEM.description = "itemBinocularsDesc"
ITEM.price = 100

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end