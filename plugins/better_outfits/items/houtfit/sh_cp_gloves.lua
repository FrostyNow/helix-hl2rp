ITEM.name = "CP Gloves"
ITEM.description = "cpGlovesDesc"
ITEM.model = "models/tnb/items/aphelion/gloves.mdl"
ITEM.price = 30
ITEM.outfitCategory = "gloves"
ITEM.eqBodyGroups = {
	["gloves"] = 1,
}

local function GetMPFModels()
	local faction = ix.faction.indices[FACTION_MPF]

	if (faction and istable(faction.models) and #faction.models > 0) then
		return table.Copy(faction.models)
	end

	return {
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
end

ITEM.allowedModels = GetMPFModels()

ITEM.tooltipLabelText = "securitizedItemTooltip"
ITEM.tooltipLabelFactionColor = FACTION_MPF

function ITEM:CanEquipOutfit()
	local client = self.player or self:GetOwner()

	return IsValid(client) and client:Team() == FACTION_MPF
end

