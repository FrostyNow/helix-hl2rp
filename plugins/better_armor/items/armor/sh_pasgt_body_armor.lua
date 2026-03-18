
ITEM.name = "PASGT Vest"
ITEM.description = "pasgtBodyArmorDesc"
ITEM.model = "models/props_c17/SuitCase_Passenger_Physics.mdl"
ITEM.height = 1
ITEM.width = 1
ITEM.armorAmount = 70
ITEM.price = 250
ITEM.gasmask = false -- It will protect you from bad air
ITEM.resistance = true -- This will activate the protection bellow
ITEM.damage = { -- It is scaled; so 100 damage * 0.8 will makes the damage be 80.
			.8, -- Bullets
			.9, -- Slash
			.9, -- Shock
			1, -- Burn
			1, -- Radiation
			1, -- Acid
			.8, -- Explosion
}
ITEM.replacements = {
	{"novest", ""}
}
ITEM.eqBodyGroups = {
	["harness"] = 1,
	["bodyarmor"] = 1
}
ITEM.outfitCategory = "vest"

ITEM.isBag = true
ITEM.invWidth = 2
ITEM.invHeight = 2

ITEM.hitGroups = {HITGROUP_CHEST, HITGROUP_STOMACH}
ITEM.maxDurability = 150
ITEM.allowedModels = {
	"models/wichacks/erdimnovest.mdl",
	"models/wichacks/ericnovest.mdl",
	"models/wichacks/joenovest.mdl",
	"models/wichacks/mikenovest.mdl",
	"models/wichacks/sandronovest.mdl",
	"models/wichacks/tednovest.mdl",
	"models/wichacks/vannovest.mdl",
	"models/wichacks/vancenovest.mdl",
	"models/models/army/female_01.mdl",
	"models/models/army/female_02.mdl",
	"models/models/army/female_03.mdl",
	"models/models/army/female_04.mdl",
	"models/models/army/female_06.mdl",
	"models/models/army/female_07.mdl"
}

ITEM.tooltipLabelText = "securitizedItemTooltip"
ITEM.tooltipLabelFactionColor = FACTION_MPF