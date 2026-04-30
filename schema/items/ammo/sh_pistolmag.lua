ITEM.name = "9mm Pistol Magazine"
ITEM.model = "models/weapons/w_pist_223_mag.mdl"
ITEM.ammo = "pistol" -- type of the ammo
ITEM.ammoAmount = 18 -- amount of the ammo
ITEM.description = "pistolMagDesc"
ITEM.classes = {CLASS_REBEL}
ITEM.factions = {FACTION_MPF, FACTION_CONSCRIPT}
ITEM.price = 20

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end