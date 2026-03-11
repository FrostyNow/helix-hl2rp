ITEM.name = "Conscript Fatigue"
ITEM.description = "itemConscriptFatigueDesc"
ITEM.model = "models/props_c17/SuitCase_Passenger_Physics.mdl"
ITEM.skin = 0
ITEM.width = 1
ITEM.height = 1
ITEM.price = 100
ITEM.outfitCategory = "outfit"
ITEM.replacements = {
	{"tnb/citizens/aphelion/male_01", "wichacks/vannovest"},
	{"tnb/citizens/aphelion/male_02", "wichacks/tednovest"},
	{"tnb/citizens/aphelion/male_03", "wichacks/joenovest"},
	{"tnb/citizens/aphelion/male_04", "wichacks/ericnovest"},
	{"tnb/citizens/aphelion/male_05", "wichacks/artcnovest"},
	{"tnb/citizens/aphelion/male_06", "wichacks/sandrocnovest"},
	{"tnb/citizens/aphelion/male_07", "wichacks/mikenovest"},
	{"tnb/citizens/aphelion/male_09", "wichacks/erdimnovest"},
	{"tnb/citizens/aphelion/female_", "models/army/female_"}
}
ITEM.allowedModels = {
	"models/tnb/citizens/aphelion/male_01.mdl",
	"models/tnb/citizens/aphelion/male_02.mdl",
	"models/tnb/citizens/aphelion/male_03.mdl",
	"models/tnb/citizens/aphelion/male_04.mdl",
	"models/tnb/citizens/aphelion/male_05.mdl",
	"models/tnb/citizens/aphelion/male_06.mdl",
	"models/tnb/citizens/aphelion/male_07.mdl",
	"models/tnb/citizens/aphelion/male_09.mdl",
	"models/tnb/citizens/aphelion/male_16.mdl",
	"models/tnb/citizens/aphelion/female_01.mdl",
	"models/tnb/citizens/aphelion/female_02.mdl",
	"models/tnb/citizens/aphelion/female_03.mdl",
	"models/tnb/citizens/aphelion/female_04.mdl",
	"models/tnb/citizens/aphelion/female_05.mdl",
	"models/tnb/citizens/aphelion/female_08.mdl",
	"models/tnb/citizens/aphelion/female_09.mdl",
	"models/tnb/citizens/aphelion/female_10.mdl",
	"models/tnb/citizens/aphelion/female_11.mdl"
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end