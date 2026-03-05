ITEM.name = "Health Kit"
ITEM.model = Model("models/Items/HealthKit.mdl")
ITEM.description = "healthKitDesc"
ITEM.price = 35
ITEM.healthPoint = 25 -- Health point that the player will get
ITEM.medAttr = 3 -- How much medical attribute the character needs
ITEM.bleeding = true
ITEM.fracture = true
ITEM.sound = "items/smallmedkit1.wav"

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end