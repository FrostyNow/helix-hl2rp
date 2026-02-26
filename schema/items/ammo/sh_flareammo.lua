ITEM.name = "Flares"
ITEM.model = "models/rtbr/items/boxflares.mdl"
ITEM.ammo = "Flares" -- type of the ammo
ITEM.ammoAmount = 4 -- amount of the ammo
ITEM.ammoClip = 1
ITEM.description = "flareammoDesc"
ITEM.classes = {CLASS_REBEL}
ITEM.factions = {FACTION_CONSCRIPT, FACTION_MPF, FACTION_OTA}
ITEM.price = 50

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end