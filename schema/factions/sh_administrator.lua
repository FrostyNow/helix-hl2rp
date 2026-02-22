
FACTION.name = "Administrator"
FACTION.description = "A human Administrator advised by the Universal Union."
FACTION.color = Color(191, 57, 75, 255)
FACTION.pay = 50
FACTION.models = {
	"models/humans/combine/female_01.mdl",
	"models/humans/combine/female_02.mdl",
	"models/humans/combine/female_03.mdl",
	"models/humans/combine/female_04.mdl",
	"models/humans/combine/female_06.mdl",
	"models/humans/combine/female_07.mdl",
	"models/humans/combine/female_08.mdl",
	"models/humans/combine/female_09.mdl",
	"models/humans/combine/female_10.mdl",
	"models/humans/combine/female_11.mdl",
	"models/humans/combine/male_01.mdl",
	"models/humans/combine/male_02.mdl",
	"models/humans/combine/male_03.mdl",
	"models/humans/combine/male_04.mdl",
	"models/humans/combine/male_05.mdl",
	"models/humans/combine/male_06.mdl",
	"models/humans/combine/male_07.mdl",
	"models/humans/combine/male_08.mdl",
	"models/humans/combine/male_09.mdl",
	"models/humans/combine/male_10.mdl",
	"models/humans/combine/male_11.mdl",
	"models/humans/combine/male_12.mdl",
	"models/humans/combine/male_13.mdl",
	"models/humans/combine/male_14.mdl",
	"models/humans/combine/male_15.mdl",
	"models/humans/combine/male_16.mdl",
	"models/humans/combine/male_18.mdl",
	"models/humans/combine/male_77.mdl"
}
FACTION.isDefault = false
FACTION.isGloballyRecognized = true

FACTION.canSeeWaypoints = true

function FACTION:OnCharacterCreated(client, character)
	local inventory = character:GetInventory()

	inventory:Add("357", 1)
	inventory:Add("357ammo", 2)
	inventory:Add("handheld_radio", 1)
	inventory:Add("stunstick", 1)
end

FACTION_ADMIN = FACTION.index
