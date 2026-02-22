
FACTION.name = "Conscript"
FACTION.description = "A regular human citizen enlisted as a soldier to Combine Overwatch."
FACTION.color = Color(77, 93, 83, 255)
FACTION.pay = 7
FACTION.isDefault = false
FACTION.isGloballyRecognized = true
FACTION.runSounds = {[0] = "NPC_MetroPolice.RunFootstepLeft", [1] = "NPC_MetroPolice.RunFootstepRight"}

FACTION.canSeeWaypoints = true

FACTION.genderModels = {
	male = {
		"models/wichacks/erdimnovest.mdl",
		"models/wichacks/ericnovest.mdl",
		"models/wichacks/joenovest.mdl",
		"models/wichacks/mikenovest.mdl",
		"models/wichacks/sandronovest.mdl",
		"models/wichacks/tednovest.mdl",
		"models/wichacks/vannovest.mdl",
		"models/wichacks/vancenovest.mdl",
	},
	female = {
		"models/models/army/female_01.mdl",
		"models/models/army/female_02.mdl",
		"models/models/army/female_03.mdl",
		"models/models/army/female_04.mdl",
		"models/models/army/female_06.mdl",
		"models/models/army/female_07.mdl"
	}
}

function FACTION:OnCharacterCreated(client, character)
	local inventory = character:GetInventory()

	inventory:Add("smg1", 1)
	inventory:Add("smg1ammo", 4)
	inventory:Add("handheld_radio", 1)
	inventory:Add("hat", 1)
	inventory:Add("pasgt_helmet", 1)
	inventory:Add("pasgt_body_armor", 1)
	inventory:Add("harness", 1)
	inventory:Add("grenade", 1)
	inventory:Add("bandage", 2)
	inventory:Add("health_vial", 1)
	inventory:Add("flashlight", 1)
	inventory:Add("stunstick", 1)
end

function FACTION:ModifyPlayerStep(client, data)
	-- Don't replace sounds while climbing ladders or wading through water
	if data.ladder or data.submerged then
		return
	end

	-- Only replace running sounds
	if data.running then
		data.snd = data.foot and "NPC_MetroPolice.RunFootstepRight" or "NPC_MetroPolice.RunFootstepLeft"
		data.volume = data.volume * 0.6 -- Very loud otherwise
	end
end

FACTION_CONSCRIPT = FACTION.index