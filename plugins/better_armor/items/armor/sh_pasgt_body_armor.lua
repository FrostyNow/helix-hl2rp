
ITEM.name = "PASGT Vest"
ITEM.description = "pasgtBodyArmorDesc"
ITEM.model = "models/props_c17/SuitCase_Passenger_Physics.mdl"
ITEM.height = 2
ITEM.width = 2
ITEM.armorAmount = 70
ITEM.price = 500
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
ITEM.bodyGroups = {
	["harness"] = 1,
	["bodyarmor"] = 1
}
ITEM.outfitCategory = "torso"
ITEM.noResetBodyGroups = true
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

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end