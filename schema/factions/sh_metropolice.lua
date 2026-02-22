
FACTION.name = "Metropolice Force"
FACTION.description = "A metropolice unit working as Civil Protection."
FACTION.color = Color(85, 127, 242)
FACTION.pay = 10
FACTION.models = {"models/dpfilms/metropolice/hdpolice.mdl"}
-- FACTION.weapons = {"ix_stunstick"}
FACTION.isDefault = false
FACTION.isGloballyRecognized = true
FACTION.runSounds = {[0] = "NPC_MetroPolice.RunFootstepLeft", [1] = "NPC_MetroPolice.RunFootstepRight"}

FACTION.canSeeWaypoints = true

function FACTION:OnCharacterCreated(client, character)
	local inventory = character:GetInventory()

	inventory:Add("smg1", 1)
	inventory:Add("smg1ammo", 2)
	inventory:Add("pistol", 1)
	inventory:Add("pistolammo", 2)
	inventory:Add("health_vial", 1)
	inventory:Add("stunstick", 1)
end

function FACTION:GetDefaultName(client)
	return "c17:MPF-RCT.UNKNOWN:" .. Schema:ZeroNumber(math.random(1, 999), 3), true
end

function FACTION:OnTransferred(character)
	character:SetName(self:GetDefaultName())
	character:SetModel(self.models[1])
end

function FACTION:OnNameChanged(client, oldValue, value)
	local character = client:GetCharacter()

	if (!Schema:IsCombineRank(oldValue, "RCT") and Schema:IsCombineRank(value, "RCT")) then
		character:JoinClass(CLASS_MPR)
	elseif (!Schema:IsCombineRank(oldValue, "OfC") and Schema:IsCombineRank(value, "OfC")) then
		character:SetModel("models/dpfilms/metropolice/policetrench.mdl")
	elseif (!Schema:IsCombineRank(oldValue, "EpU") and Schema:IsCombineRank(value, "EpU")) then
		character:JoinClass(CLASS_EMP)

		character:SetModel("models/metropolice/leet_police_v2.mdl")
	elseif (!Schema:IsCombineRank(oldValue, "DvL") and Schema:IsCombineRank(value, "DvL")) then
		character:SetModel("models/metropolice/leet_police_v2.mdl")
	elseif (!Schema:IsCombineRank(oldValue, "SeC") and Schema:IsCombineRank(value, "SeC")) then
		character:SetModel("models/metropolice/leet_police_v2.mdl")
	elseif (!Schema:IsCombineRank(oldValue, "SCN") and Schema:IsCombineRank(value, "SCN")
	or !Schema:IsCombineRank(oldValue, "SHIELD") and Schema:IsCombineRank(value, "SHIELD")) then
		character:JoinClass(CLASS_MPS)
	end
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

FACTION_MPF = FACTION.index