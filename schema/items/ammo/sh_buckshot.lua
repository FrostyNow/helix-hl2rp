ITEM.name = "Shotgun Shells"
ITEM.model = "models/weapons/w_shot_nova_mag.mdl"
ITEM.ammo = "buckshot" -- type of the ammo
ITEM.ammoAmount = 1 -- amount of the ammo
ITEM.description = "buckshotDesc"
ITEM.classes = {CLASS_EMP, CLASS_SGS, CLASS_REBEL}
ITEM.factions = {FACTION_CONSCRIPT}
ITEM.price = 2

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end