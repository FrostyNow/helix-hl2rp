ITEM.name = "SMG Bullets"
ITEM.model = "models/Items/BoxMRounds.mdl"
ITEM.ammo = "smg1" -- type of the ammo
ITEM.ammoAmount = 225 -- amount of the ammo
ITEM.ammoClip = 45
ITEM.description = "smg1ammoDesc"
ITEM.classes = {CLASS_EMP, CLASS_OWS, CLASS_MPU, CLASS_REBEL}
ITEM.factions = {FACTION_CONSCRIPT}
ITEM.price = 100

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end