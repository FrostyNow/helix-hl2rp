ITEM.name = "Metropolice Uniform"
ITEM.description = "itemMetropoliceDesc"
ITEM.model = "models/props_c17/SuitCase_Passenger_Physics.mdl"
ITEM.price = 375
ITEM.width = 1
ITEM.height = 1
ITEM.outfitCategory = "torso"
ITEM.replacements = {
	{"humans/pandafishizens", "conceptbine_policeforce/rnd"}
}
ITEM.eqBodyGroups = {
	["lower gear"] = 1
}
ITEM.newSkin = 0
ITEM.allowedBaseFactions = {FACTION_CITIZEN}
ITEM.noDeathDrop = true

ITEM.functions.Equip.OnCanRun = function(item)
	if (item.baseTable.functions.Equip.OnCanRun(item) == false) then
		return false
	end

	local char = item.player:GetCharacter()
	if (!char) then return false end

	local allowed = false

	if (char:HasFlags("M")) then
		allowed = true
	elseif (item.player:IsAdmin()) then
		allowed = true
	end

	return allowed
end

local function GetMPFFaction()
	return ix.faction.indices[FACTION_MPF]
end

local function GetUniformState(character)
	local faction = GetMPFFaction()

	if (!faction or !character) then
		return {}
	end

	return faction:GetUniformState(character)
end

local function SetUniformState(character, state)
	local faction = GetMPFFaction()

	if (faction and character) then
		faction:SetUniformState(character, state)
	end
end

local function GetDefaultDutyName(client, character)
	local faction = GetMPFFaction()

	if (!faction) then
		return character:GetName()
	end

	return faction:GetDefaultName(client)
end

local function RefreshFactionState(client)
	local character = client:GetCharacter()
	local inventory = character and character:GetInventory()
	local runSpeed = ix.config.Get("runSpeed")

	client:SetRunSpeed(client:IsCombine() and runSpeed * 1.1 or runSpeed)
	client:SetCanZoom(character and (client:IsCombine() or client:IsAdmin() or (inventory and inventory:HasItem("binoculars"))))
end

local function FinalizeUniformChange(client)
	if (!IsValid(client)) then
		return
	end

	RefreshFactionState(client)
	client:SetupHands()

	timer.Simple(0, function()
		if (IsValid(client) and client:GetCharacter()) then
			hook.Run("UpdateAllRelations")
		end
	end)
end

ITEM.tooltipLabelText = "securitizedItemTooltip"
ITEM.tooltipLabelFactionColor = FACTION_MPF

function ITEM:CanEquipOutfit()
	local client = self.player or self:GetOwner()
	local character = IsValid(client) and client:GetCharacter()
	local faction = GetMPFFaction()

	if (!character or !faction) then
		return false
	end

	return (character:GetFaction() == FACTION_CITIZEN) or (character:GetFaction() == FACTION_MPF and faction:IsUniformCitizenDuty(character))
end

function ITEM:ApplyOutfit(client)
	client = client or self.player or self:GetOwner()

	if (!IsValid(client)) then return end

	local character = client:GetCharacter()
	local faction = GetMPFFaction()

	if (!character or !faction) then
		return self.baseTable.ApplyOutfit(self, client)
	end

	local state = GetUniformState(character)

	if (!state.active) then
		local currentFaction = ix.faction.indices[character:GetFaction()]

		state.active = true
		state.originalFaction = currentFaction and currentFaction.uniqueID or "citizen"
		state.originalName = character:GetName()
		state.originalModel = client:GetModel()
		state.originalClass = character:GetClass()
		state.originalDescription = character:GetDescription()
	end

	state.dutyName = state.dutyName or GetDefaultDutyName(client, character)
	state.dutyDescription = state.dutyDescription or faction.description or "A metropolice unit working as Civil Protection."
	SetUniformState(character, state)

	self.baseTable.ApplyOutfit(self, client)

	state = GetUniformState(character)
	state.dutyModel = client:GetModel()
	SetUniformState(character, state)

	if (character:GetFaction() != FACTION_MPF) then
		character:SetFaction(FACTION_MPF)
	end

	character:KickClass()

	if (character:GetName() != state.dutyName) then
		character:SetName(state.dutyName)
	elseif (faction.OnNameChanged) then
		faction:OnNameChanged(client, "", state.dutyName)
	end

	if (character:GetDescription() != state.dutyDescription) then
		character:SetDescription(state.dutyDescription)
	elseif (faction.OnDescriptionChanged) then
		faction:OnDescriptionChanged(client, "", state.dutyDescription)
	end

	FinalizeUniformChange(client)
end

function ITEM:RemoveOutfit(client)
	client = client or self.player or self:GetOwner()

	if (!IsValid(client)) then return end

	local character = client:GetCharacter()
	local faction = GetMPFFaction()
	local state = character and GetUniformState(character) or {}
	local originalName = state.originalName
	local originalModel = state.originalModel
	local originalClass = state.originalClass
	local originalDescription = state.originalDescription
	local returnFaction = (faction and character) and faction:GetUniformReturnFaction(character) or FACTION_CITIZEN

	self.baseTable.RemoveOutfit(self, client)

	if (!character or !faction or !state.active) then
		FinalizeUniformChange(client)
		return
	end

	state.active = false
	state.originalFaction = nil
	state.originalName = nil
	state.originalModel = nil
	state.originalClass = nil
	state.originalDescription = nil
	SetUniformState(character, state)

	if (character:GetFaction() != returnFaction) then
		character:SetFaction(returnFaction)
	end

	if (isnumber(originalClass)) then
		local classData = ix.class.list[originalClass]

		if (classData and classData.faction == returnFaction) then
			character:JoinClass(originalClass)
		else
			character:KickClass()
		end
	else
		character:KickClass()
	end

	if (isstring(originalName) and originalName != "" and character:GetName() != originalName) then
		character:SetName(originalName)
	end

	if (isstring(originalModel) and originalModel != "" and character:GetModel() != originalModel) then
		character:SetModel(originalModel)
	end

	if (isstring(originalDescription) and originalDescription != "" and character:GetDescription() != originalDescription) then
		character:SetDescription(originalDescription)
	end

	FinalizeUniformChange(client)
end

/*
-- This will change a player's skin after changing the model. Keep in mind it starts at 0.
ITEM.newSkin = 1
-- This will change a certain part of the model.
ITEM.replacements = {"group01", "group02"}
-- This will change the player's model completely.
ITEM.replacements = "models/manhack.mdl"
-- This will have multiple replacements.
ITEM.replacements = {
	{"male", "female"},
	{"group01", "group02"}
}

-- This will apply body groups.
ITEM.eqBodyGroups = {
	["blade"] = 1,
	["bladeblur"] = 1
}
*/
