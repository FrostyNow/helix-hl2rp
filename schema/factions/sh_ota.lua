
FACTION.name = "Overwatch Transhuman Arm"
FACTION.description = "A transhuman Overwatch soldier produced by the Combine."
FACTION.color = Color(181, 110, 60, 255)
FACTION.pay = 40
FACTION.models = {
	"models/Combine_Soldier.mdl"
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
end

function FACTION:GetDefaultName(client)
	return "OTA.OWS-UNKNOWN:" .. Schema:ZeroNumber(math.random(1, 999), 2), true
end

function FACTION:OnTransferred(character)
	character:SetName(self:GetDefaultName())
	character:SetModel(self.models[1])
end

function FACTION:OnNameChanged(client, oldValue, value)
	local character = client:GetCharacter()

	if (!Schema:IsCombineRank(oldValue, "OWS") and Schema:IsCombineRank(value, "OWS")) then
		character:JoinClass(CLASS_OWS)
	elseif (!Schema:IsCombineRank(oldValue, "EOW") and Schema:IsCombineRank(value, "EOW")) then
		character:JoinClass(CLASS_EOW)
	end
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
