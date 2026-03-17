
ITEM.name = "Ballistic Fiber"
ITEM.description = "itemBallisticFiberDesc"
ITEM.price = 3
ITEM.model = "models/mosi/fallout4/props/junk/components/ballisticfiber.mdl"
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