
ITEM.name = "OTA Supplements"
ITEM.model = Model("models/props_lab/jar01b.mdl")
ITEM.description = "itemOTASupplementsDesc"
ITEM.category = "Utility"
ITEM.factions = {FACTION_OTA}
ITEM.classes = nil
ITEM.hunger = 100
ITEM.thirst = 100
ITEM.price = 50
ITEM.heal = 0
ITEM.usenum = 2
ITEM.sound = "items/gift_pickup.wav"

ITEM.functions.Eat.OnCanRun = function(item)
	if (item.baseTable.functions.Eat.OnCanRun(item) == false) then
		return false
	end

	return item.player:Team() == FACTION_OTA
end

ITEM.tooltipLabelText = "securitizedItemTooltip"
ITEM.tooltipLabelFactionColor = FACTION_MPF