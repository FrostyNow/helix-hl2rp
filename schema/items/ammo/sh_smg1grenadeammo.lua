ITEM.name = "HEAB"
ITEM.model = "models/Items/AR2_Grenade.mdl"
ITEM.ammo = "smg1_grenade" -- type of the ammo
ITEM.ammoAmount = 1 -- amount of the ammo
ITEM.description = "smg1grenadeammoDesc"
ITEM.classes = {CLASS_EMP, CLASS_OWS, CLASS_MPU, CLASS_REBEL}
ITEM.factions = {FACTION_CONSCRIPT}
ITEM.price = 275

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end