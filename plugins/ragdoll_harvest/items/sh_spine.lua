ITEM.name = "Spine"
ITEM.model = Model("models/gibs/hgibs_spine.mdl")
ITEM.description = "itemSpineDesc"
ITEM.price = 1
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