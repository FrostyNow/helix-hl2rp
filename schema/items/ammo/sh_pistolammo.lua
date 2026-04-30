ITEM.name = "9mm Pistol Bullets"
ITEM.model = "models/Items/BoxSRounds.mdl"
ITEM.ammo = "pistol" -- type of the ammo
ITEM.ammoAmount = 90 -- amount of the ammo
ITEM.ammoClip = 18
ITEM.description = "pistolammoDesc"
ITEM.classes = {CLASS_REBEL}
ITEM.factions = {FACTION_MPF, FACTION_CONSCRIPT}
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