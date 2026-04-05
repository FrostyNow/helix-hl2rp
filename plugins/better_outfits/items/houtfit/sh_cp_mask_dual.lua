ITEM.name = "CP Mask"
ITEM.description = "cpMaskDesc"
ITEM.model = "models/conceptbine_policeforce/rnd/copmask.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.iconCam = {
	pos = Vector(27.34, -71.44, 184.57),
	ang = Angle(66.8, 110.14, 0),
	fov = 3.76
}
ITEM.exRender = true
ITEM.price = 50
ITEM.bodyGroups = {
	["cop mask filters"] = 1,
}
ITEM.noDeathDrop = true
ITEM.classes = {CLASS_MPU}
ITEM.eqBodyGroups = {
	["mask"] = 1,
	["mask eyes"] = 1,
	["cop mask filters"] = 2,
	["mask back"] = 1,
}
ITEM.outfitCategory = "face"
ITEM.badAirProtection = true
ITEM.combineMaskProtection = true
ITEM.requiresGasmaskFilter = true
ITEM.filterMaxDurability = 100
ITEM.filterIgnoreItemDurability = true

ITEM.allowedModels = {
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

ITEM.tooltipLabelText = "securitizedItemTooltip"
ITEM.tooltipLabelFactionColor = FACTION_MPF
