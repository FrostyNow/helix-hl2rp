
ITEM.name = "Nuclear Material"
ITEM.description = "itemNuclearDesc"
ITEM.price = 300
ITEM.model = "models/mosi/fallout4/props/junk/components/nuclear.mdl"
ITEM.isjunk = true
ITEM.isStackable = true

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end