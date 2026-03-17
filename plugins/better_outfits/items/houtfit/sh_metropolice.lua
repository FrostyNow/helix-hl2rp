ITEM.name = "Metropolice Uniform"
ITEM.description = "itemMetropoliceDesc"
-- ITEM.category = "Outfit"
ITEM.model = "models/props_c17/SuitCase_Passenger_Physics.mdl"
ITEM.price = 375
ITEM.width = 1
ITEM.height = 1
-- ITEM.gasmask = false -- Mask handling should come from dedicated metrocop bodygroup items
-- ITEM.resistance = true -- This will activate the protection bellow
-- ITEM.damage = { -- It is scaled; so 100 damage * 0.8 will makes the damage be 80.
-- 			.9, -- Bullets
-- 			.9, -- Slash
-- 			.9, -- Shock
-- 			.9, -- Burn
-- 			.7, -- Radiation
-- 			.7, -- Acid
-- 			.9, -- Explosion
-- }
-- ITEM.maxDurability = 150
ITEM.outfitCategory = "torso"
-- ITEM.pacData = {}
ITEM.replacements = {
	{"humans/pandafishizens", "conceptbine_policeforce/rnd"}
}
ITEM.eqBodyGroups = {
	-- ["vest"] = 1,
	-- ["gloves"] = 1,
	-- ["boots"] = 1,
	["lower gear"] = 1,
}
ITEM.newSkin = 0

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

	RefreshFactionState(client)
end

function ITEM:RemoveOutfit(client)
	client = client or self.player or self:GetOwner()

	if (!IsValid(client)) then return end

	local character = client:GetCharacter()
	local faction = GetMPFFaction()
	local state = character and GetUniformState(character) or {}
	local originalName = state.originalName
	local originalClass = state.originalClass
	local originalDescription = state.originalDescription
	local returnFaction = (faction and character) and faction:GetUniformReturnFaction(character) or FACTION_CITIZEN

	self.baseTable.RemoveOutfit(self, client)

	if (!character or !faction or !state.active) then
		RefreshFactionState(client)
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

	if (isstring(originalDescription) and originalDescription != "" and character:GetDescription() != originalDescription) then
		character:SetDescription(originalDescription)
	end

	RefreshFactionState(client)
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
