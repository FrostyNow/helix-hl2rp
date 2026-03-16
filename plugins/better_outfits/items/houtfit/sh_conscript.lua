ITEM.name = "Conscript Fatigue"
ITEM.description = "itemConscriptFatigueDesc"
ITEM.model = "models/props_c17/SuitCase_Passenger_Physics.mdl"
ITEM.skin = 0
ITEM.width = 1
ITEM.height = 1
ITEM.price = 100
ITEM.outfitCategory = "suit"
ITEM.allowedBaseFactions = {"citizen"}
ITEM.tooltipLabelText = "securitizedItemTooltip"
ITEM.tooltipLabelFactionColor = FACTION_CONSCRIPT

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

local function HasEquippedOutfitLayers(character, ignoreItemID)
	local inventory = character and character:GetInventory()

	if (!inventory) then
		return false
	end

	for _, item in pairs(inventory:GetItems()) do
		if (item.id == ignoreItemID or !item:GetData("equip")) then
			continue
		end

		local itemTable = ix.item.list[item.uniqueID]
		local category = item.outfitCategory or (itemTable and itemTable.outfitCategory)

		if (category and category != "suit") then
			return true
		end
	end

	return false
end

function ITEM:CanEquipOutfit()
	local client = self.player or self:GetOwner()
	local character = IsValid(client) and client:GetCharacter()
	local faction = GetConscriptFaction()

	if (!character or !faction) then
		return false
	end

	if (character:GetFaction() == FACTION_CITIZEN) then
		return !HasEquippedOutfitLayers(character, self.id)
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
	end

	state.dutyName = faction:GetFormattedName(character, state.originalName)
	state.dutyModel = faction:ResolveDutyModel(character, state.originalModel)
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
	local returnFaction = (faction and character) and faction:GetUniformReturnFaction(character) or FACTION_CITIZEN

	self.baseTable.RemoveOutfit(self, client)

	if (!character or !faction or !state.active) then
		return
	end

	state.active = false
	state.originalFaction = nil
	state.originalName = nil
	state.originalModel = nil
	state.originalClass = nil
	state.dutyName = nil
	state.dutyModel = nil
	SetUniformState(character, state)

	if (character:GetFaction() != returnFaction) then
		character:SetFaction(returnFaction)
	end

	character:KickClass()

	if (isnumber(originalClass)) then
		local classData = ix.class.list[originalClass]

		if (classData and classData.faction == returnFaction) then
			character:SetClass(originalClass)
		end
	end

	if (isstring(originalName) and originalName != "" and character:GetName() != originalName) then
		character:SetName(originalName)
	end
end
