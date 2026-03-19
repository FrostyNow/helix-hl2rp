ITEM.name = "20mm HEAB Round"
ITEM.model = "models/Items/AR2_Grenade.mdl"
ITEM.ammo = "20x28mm grenade" -- type of the ammo
ITEM.ammoAmount = 1 -- amount of the ammo
ITEM.description = "oicwgrenadeammoDesc"
ITEM.classes = {CLASS_EMP, CLASS_OWS, CLASS_MPU}
ITEM.factions = {FACTION_CONSCRIPT}
ITEM.price = 60

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end