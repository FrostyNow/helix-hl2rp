
ITEM.name = "Combine Battery"
ITEM.model = Model("models/Items/battery.mdl")
ITEM.description = "batteryDesc"
ITEM.price = 75
ITEM.category = "Utility"
ITEM.isStackable = true

ITEM.classes = {CLASS_MPU, CLASS_EMP, CLASS_OWS, CLASS_EOW}

ITEM.functions.Use = {
	icon = "icon16/asterisk_orange.png",
	OnRun = function(item)
		local client = item.player

		client:SetArmor(math.Clamp(client:Armor() + 15, 0, client:GetMaxArmor() or 255))
		client:EmitSound("items/battery_pickup.wav")
	end,
	OnCanRun = function(item)
		local client = item.player
		return client:Alive() and (client:IsCombine() or client:GetMaxArmor() > 0) and client:Armor() < (client:GetMaxArmor() or 255)
	end
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end