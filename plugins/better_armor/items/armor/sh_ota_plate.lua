ITEM.name = "OTA Armor Plate"
ITEM.description = "otaPlateDesc"
ITEM.model = "models/gibs/scanner_gib02.mdl"
ITEM.price = 50
ITEM.width = 1
ITEM.height = 1
ITEM.outfitCategory = "plate"
ITEM.factions = {FACTION_OTA}

ITEM.damage = {.75, .75, .75, .75, .75, .75, .75}
ITEM.resistance = true
ITEM.hitGroups = {
	HITGROUP_CHEST,
	HITGROUP_STOMACH,
	HITGROUP_LEFTARM,
	HITGROUP_RIGHTARM,
	HITGROUP_LEFTLEG,
	HITGROUP_RIGHTLEG
}

ITEM.tooltipLabelText = "securitizedItemTooltip"
ITEM.tooltipLabelFactionColor = FACTION_MPF

function ITEM:CanEquipOutfit()
	local client = self.player or self:GetOwner()

	return IsValid(client) and client:Team() == FACTION_OTA
end
