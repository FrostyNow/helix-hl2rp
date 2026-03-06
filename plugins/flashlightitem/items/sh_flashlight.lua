
ITEM.name = "Flashlight"
ITEM.model = Model("models/props_combine/breenlight.mdl")
ITEM.width = 1
ITEM.height = 1
ITEM.description = "itemFlashlightDesc"
ITEM.category = "Utility"

ITEM:Hook("drop", function(item)
	item.player:Flashlight(false)
end)

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end
