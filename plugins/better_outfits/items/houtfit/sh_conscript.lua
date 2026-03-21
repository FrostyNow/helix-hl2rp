ITEM.name = "Conscript Fatigue"
ITEM.description = "itemConscriptFatigueDesc"
ITEM.model = "models/props_c17/SuitCase_Passenger_Physics.mdl"
ITEM.skin = 0
ITEM.width = 1
ITEM.height = 1
ITEM.price = 100
ITEM.outfitCategory = "torso"
ITEM.allowedBaseFactions = {FACTION_CITIZEN}
ITEM.tooltipLabelText = "securitizedItemTooltip"
ITEM.tooltipLabelFactionColor = FACTION_MPF
ITEM.noDeathDrop = true

ITEM.functions.Equip.OnCanRun = function(item)
	if (item.baseTable.functions.Equip.OnCanRun(item) == false) then
		return false
	end

	local char = item.player:GetCharacter()
	if (!char) then return false end

	local allowed = false

	if (char:HasFlags("C")) then
		allowed = true
	elseif (item.player:IsAdmin()) then
		allowed = true
	end

	return allowed
end

local function GetConscriptFaction()
	return ix.faction.indices[FACTION_CONSCRIPT]
end

local function GetUniformState(character)
	local faction = GetConscriptFaction()

	if (!faction or !character) then
		return {}
	end

	return faction:GetUniformState(character)
end

local function SetUniformState(character, state)
	local faction = GetConscriptFaction()

	if (faction and character) then
		faction:SetUniformState(character, state)
	end
end

local function FinalizeUniformChange(client)
	if (!IsValid(client)) then
		return
	end

	client:SetupHands()

	timer.Simple(0, function()
		if (IsValid(client) and client:GetCharacter()) then
			hook.Run("UpdateAllRelations")
		end
	end)
end

function ITEM:CanEquipOutfit()
	local client = self.player or self:GetOwner()
	local character = IsValid(client) and client:GetCharacter()
	local faction = GetConscriptFaction()

	if (!character or !faction) then
		return false
	end

	if (character:GetFaction() == FACTION_CITIZEN) then
		return true
	end

	return character:GetFaction() == FACTION_CONSCRIPT and faction:IsUniformCitizenDuty(character)
end

function ITEM:OnGetReplacement()
	local client = self.player or self:GetOwner()
	local character = IsValid(client) and client:GetCharacter()
	local faction = GetConscriptFaction()
	local state = character and GetUniformState(character) or {}

	if (!character or !faction) then
		return IsValid(client) and client:GetModel() or nil
	end

	return state.dutyModel or faction:ResolveDutyModel(character, state.originalModel or client:GetModel())
end

function ITEM:ApplyOutfit(client)
	client = client or self.player or self:GetOwner()

	if (!IsValid(client)) then
		return
	end

	local character = client:GetCharacter()
	local faction = GetConscriptFaction()

	if (!character or !faction) then
		return self.baseTable.ApplyOutfit(self, client)
	end

	local state = GetUniformState(character)

	if (!state.active) then
		local currentFaction = ix.faction.indices[character:GetFaction()]

		state.active = true
		state.originalFaction = currentFaction and currentFaction.uniqueID or "citizen"
		state.originalName = faction:GetBaseName(character)
		state.originalModel = client:GetModel()
		state.originalClass = character:GetClass()
		state.originalDescription = character:GetDescription()
	end

	state.dutyName = faction:GetFormattedName(character, state.originalName)
	state.dutyModel = faction:ResolveDutyModel(character, state.originalModel)
	state.dutyDescription = state.dutyDescription or faction.description or "A regular human citizen enlisted as a soldier to Combine Overwatch."
	SetUniformState(character, state)

	self.baseTable.ApplyOutfit(self, client)

	state = GetUniformState(character)
	state.dutyName = faction:GetFormattedName(character, state.originalName)
	state.dutyModel = client:GetModel()
	SetUniformState(character, state)

	if (character:GetFaction() != FACTION_CONSCRIPT) then
		character:SetFaction(FACTION_CONSCRIPT)
	end

	if (CLASS_CONSCRIPT and character:GetClass() != CLASS_CONSCRIPT) then
		character:JoinClass(CLASS_CONSCRIPT)
	end

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

	if (!IsValid(client)) then
		return
	end

	local character = client:GetCharacter()
	local faction = GetConscriptFaction()
	local state = character and GetUniformState(character) or {}
	local originalName = state.originalName
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
	state.dutyName = nil
	state.dutyModel = nil
	state.dutyDescription = nil
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

	if (isstring(originalDescription) and originalDescription != "" and character:GetDescription() != originalDescription) then
		character:SetDescription(originalDescription)
	end

	FinalizeUniformChange(client)
end
