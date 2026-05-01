ITEM.name = "STANAG Magazine"
ITEM.model = "models/weapons/w_rif_m4a1_mag.mdl"
ITEM.ammo = "5.56x45mm" -- type of the ammo
ITEM.ammoAmount = 30 -- amount of the ammo
ITEM.description = "stanagDesc"
ITEM.classes = {CLASS_EMP, CLASS_OWS, CLASS_MPU, CLASS_REBEL}
ITEM.factions = {FACTION_CONSCRIPT}
ITEM.price = 30

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end