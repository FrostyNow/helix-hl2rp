ITEM.name = "CP Armor Vest"
ITEM.description = "cp_vest_mpf_desc"
ITEM.model = "models/tnb/items/aphelion/shirt_rebelmetrocop.mdl"
ITEM.price = 250
ITEM.width = 1
ITEM.height = 1
ITEM.outfitCategory = "vest"
ITEM.eqBodyGroups = {
	["vest"] = 1,
}
ITEM.noBusiness = true

local faction = ix.faction.indices[FACTION_MPF]
ITEM.allowedModels = faction and table.Copy(faction.models) or {
	"models/conceptbine_policeforce/rnd/male_01.mdl",
	"models/conceptbine_policeforce/rnd/male_02.mdl",
	"models/conceptbine_policeforce/rnd/male_03.mdl",
	"models/conceptbine_policeforce/rnd/male_04.mdl",
	"models/conceptbine_policeforce/rnd/male_05.mdl",
	"models/conceptbine_policeforce/rnd/male_06.mdl",
	"models/conceptbine_policeforce/rnd/male_07.mdl",
	"models/conceptbine_policeforce/rnd/male_08.mdl",
	"models/conceptbine_policeforce/rnd/male_09.mdl",
	"models/conceptbine_policeforce/rnd/male_10.mdl",
	"models/conceptbine_policeforce/rnd/male_11.mdl",
	"models/conceptbine_policeforce/rnd/male_15.mdl",
	"models/conceptbine_policeforce/rnd/male_16.mdl",
	"models/conceptbine_policeforce/rnd/female_01.mdl",
	"models/conceptbine_policeforce/rnd/female_02.mdl",
	"models/conceptbine_policeforce/rnd/female_03.mdl",
	"models/conceptbine_policeforce/rnd/female_04.mdl",
	"models/conceptbine_policeforce/rnd/female_06.mdl",
	"models/conceptbine_policeforce/rnd/female_07.mdl",
	"models/conceptbine_policeforce/rnd/female_11.mdl",
	"models/conceptbine_policeforce/rnd/female_17.mdl",
	"models/conceptbine_policeforce/rnd/female_18.mdl",
	"models/conceptbine_policeforce/rnd/female_19.mdl",
	"models/conceptbine_policeforce/rnd/female_24.mdl"
}

ITEM.armorAmount = 50
ITEM.damage = {.75, .75, .75, .75, .75, .75, .75}
ITEM.resistance = true
ITEM.hitGroups = {HITGROUP_CHEST}

ITEM.tooltipLabelText = "securitizedItemTooltip"
ITEM.tooltipLabelFactionColor = FACTION_MPF

function ITEM:CanEquipOutfit()
	local client = self.player or self:GetOwner()

	return IsValid(client) and client:Team() == FACTION_MPF
end
