ITEM.name = "MP7 Magazine"
ITEM.model = "models/weapons/w_smg_mp7_mag.mdl"
ITEM.ammo = "smg1" -- type of the ammo
ITEM.ammoAmount = 45 -- amount of the ammo
ITEM.description = "smg1MagDesc"
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