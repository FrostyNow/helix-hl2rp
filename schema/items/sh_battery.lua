
ITEM.name = "Combine Battery"
ITEM.model = Model("models/Items/battery.mdl")
ITEM.description = "batteryDesc"
ITEM.price = 75
ITEM.category = "Utility"

ITEM.classes = {CLASS_MPU, CLASS_EMP, CLASS_OWS, CLASS_EOW}

ITEM.functions.Use = {
	OnRun = function(item)
		local client = item.player

		if client:Team() == FACTION_OTA then
			client:SetArmor(math.Clamp(client:Armor() + 15, 0, 255))
		else
			client:SetArmor(math.Clamp(client:Armor() + 15, 0, 100))
		end
		client:EmitSound("items/battery_pickup.wav")
	end,
	OnCanRun = function(item)
		return item.player:IsCombine()
	end
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end