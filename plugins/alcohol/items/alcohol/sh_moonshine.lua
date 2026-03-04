ITEM.name = "Moonshine"
ITEM.description = "itemMoonshineDesc"
ITEM.model = "models/mosi/fallout4/props/alcohol/moonshine.mdl"
ITEM.force = 10
ITEM.thirst = 25
ITEM.price = 7
ITEM.empty = "glass_bottle_generic"

ITEM:Hook("Drink", function(item)
	local client = item.player
	
	client:EmitSound("interface/inv_beer.ogg")
end)

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end