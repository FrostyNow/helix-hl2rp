
ITEM.name = "Ballistic Fiber"
ITEM.description = "itemBallisticFiberDesc"
ITEM.price = 5
ITEM.model = "models/mosi/fallout4/props/junk/components/ballisticfiber.mdl"
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