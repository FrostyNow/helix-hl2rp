
FACTION.name = "Overwatch Transhuman Arm"
FACTION.description = "A transhuman Overwatch soldier produced by the Combine."
FACTION.color = Color(181, 110, 60, 255)
FACTION.pay = 40
FACTION.models = {
	-- "models/Combine_Soldier.mdl"
	"models/combine_soldierproto.mdl"
}
FACTION.isDefault = false
FACTION.isGloballyRecognized = true
FACTION.runSounds = {[0] = "NPC_CombineS.RunFootstepLeft", [1] = "NPC_CombineS.RunFootstepRight"}

FACTION.canSeeWaypoints = true

function FACTION:OnCharacterCreated(client, character)
	local inventory = character:GetInventory()

	inventory:Add("smg1", 1)
	inventory:Add("smg1ammo", 4)
	inventory:Add("handheld_radio", 1)
	inventory:Add("grenade", 1)
	inventory:Add("health_vial", 2)
	inventory:Add("ota_supplements", 2)
end

function FACTION:GetDefaultName(client)
	return Schema:FormatCombineName("OTA", "OWS"), true
end

function FACTION:OnTransferred(character)
	character:SetName(Schema:NormalizeCombineName(self:GetDefaultName(character:GetPlayer()), "OTA"))
	character:SetModel(self.models[1])
end

function FACTION:OnNameChanged(client, oldValue, value)
	Schema:SyncCombineClass(client, value)
end

function FACTION:ModifyPlayerStep(client, data)
	-- Don't replace sounds while climbing ladders or wading through water
	if data.ladder or data.submerged then
		return
	end

	-- Only replace running sounds
	if data.running then
		data.snd = data.foot and "NPC_CombineS.RunFootstepRight" or "NPC_CombineS.RunFootstepLeft"
		data.volume = data.volume * 0.6 -- Very loud otherwise
	end
end

FACTION_OTA = FACTION.index
