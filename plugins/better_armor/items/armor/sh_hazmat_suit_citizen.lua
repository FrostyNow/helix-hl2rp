
ITEM.name = "Hazmat Suit"
ITEM.description = "hazmatSuitCitizenDesc"
ITEM.model = "models/props_c17/SuitCase_Passenger_Physics.mdl"
ITEM.height = 1
ITEM.width = 1
ITEM.price = 250
ITEM.gasmask = true -- It will protect you from bad air
ITEM.resistance = true -- This will activate the protection bellow
ITEM.damage = { -- It is scaled; so 100 damage * 0.8 will makes the damage be 80.
	.9, -- Bullets
	.9, -- Slash
	.9, -- Shock
	.9, -- Burn
	.7, -- Radiation
	.7, -- Acid
	.9, -- Explosion
}
ITEM.replacements = {
	{"humans/pandafishizens/", "npc/engineer_"},
	{"_01", ""},
	{"_02", ""},
	{"_03", ""},
	{"_04", ""},
	{"_05", ""},
	{"_06", ""},
	{"_07", ""},
	{"_08", ""},
	{"_09", ""},
	{"_10", ""},
	{"_11", ""},
	{"_12", ""},
	{"_13", ""},
	{"_14", ""},
	{"_15", ""},
	{"_16", ""},
	{"_17", ""},
	{"_18", ""},
	{"_19", ""},
	{"_24", ""},
	{"_25", ""}
}
ITEM.outfitCategory = "suit"
ITEM.newSkin = 11
ITEM.maxDurability = 100