ITEM.name = "CP Vest"
ITEM.description = "cp_vest_desc"
ITEM.model = "models/tnb/items/aphelion/shirt_rebelmetrocop.mdl"
ITEM.price = 500
ITEM.width = 1
ITEM.height = 1
ITEM.outfitCategory = "kevlar"
ITEM.bodyGroups = {
	["kevlar"] = 1
}
ITEM.allowedModels = {
    "models/humans/pandafishizens/male_01.mdl",
    "models/humans/pandafishizens/male_02.mdl",
    "models/humans/pandafishizens/male_03.mdl",
    "models/humans/pandafishizens/male_04.mdl",
    "models/humans/pandafishizens/male_05.mdl",
    "models/humans/pandafishizens/male_06.mdl",
    "models/humans/pandafishizens/male_07.mdl",
    "models/humans/pandafishizens/male_08.mdl",
    "models/humans/pandafishizens/male_09.mdl",
    "models/humans/pandafishizens/male_10.mdl",
    "models/humans/pandafishizens/male_11.mdl",
    "models/humans/pandafishizens/male_12.mdl",
    "models/humans/pandafishizens/male_15.mdl",
    "models/humans/pandafishizens/male_16.mdl",
    "models/humans/pandafishizens/female_01.mdl",
    "models/humans/pandafishizens/female_02.mdl",
    "models/humans/pandafishizens/female_03.mdl",
    "models/humans/pandafishizens/female_04.mdl",
    "models/humans/pandafishizens/female_06.mdl",
    "models/humans/pandafishizens/female_07.mdl",
    "models/humans/pandafishizens/female_11.mdl",
    "models/humans/pandafishizens/female_17.mdl",
    "models/humans/pandafishizens/female_18.mdl",
    "models/humans/pandafishizens/female_19.mdl",
    "models/humans/pandafishizens/female_24.mdl"
}
ITEM.noBusiness = true
ITEM.noResetBodyGroups = true
ITEM.armorAmount = 50
ITEM.damage = {.75, .75, .75, .75, .75, .75, .75}
ITEM.resistance = true
ITEM.hitGroups = {HITGROUP_CHEST, HITGROUP_STOMACH}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end
