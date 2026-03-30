
FACTION.name = "Overwatch Transhuman Arm"
FACTION.description = "A transhuman Overwatch soldier produced by the Combine."
FACTION.color = Color(181, 110, 60, 255)
FACTION.pay = 100
FACTION.models = {
	-- "models/Combine_Soldier.mdl"
	"models/combine_soldierproto.mdl"
}
FACTION.isDefault = false
FACTION.isGloballyRecognized = false
FACTION.runSounds = {[0] = "NPC_CombineS.RunFootstepLeft", [1] = "NPC_CombineS.RunFootstepRight"}

FACTION.attPoints = 20
FACTION.invWidth = 7
FACTION.invHeight = 5
FACTION.inventoryType = "main_ota"

FACTION.canSeeWaypoints = true
FACTION.forcedName = true

FACTION.bodyGroups = {
	["Radio"] = {
		name = "Handheld Radio",
		min = 1,
		max = 1
	},
	["Tactic"] = {
		name = "Magazine Pouches",
		min = 1,
		max = 1
	},
	["TacticalLegs"] = {
		name = "Magazine Leg Pouches",
		min = 1,
		max = 1
	},
}

ix.inventory.Register(FACTION.inventoryType, FACTION.invWidth, FACTION.invHeight)

local function ApplyMainInventoryLayout(character, width, height, client)
	if (!character) then
		return nil
	end

	local inventory = character:GetInventory()

	if (isnumber(inventory)) then
		inventory = ix.item.inventories[inventory] or ix.inventory.Get(inventory)
	end

	if (!istable(inventory) or !inventory.SetSize or !inventory.GetID) then
		return nil
	end

	inventory:SetSize(width, height)
	inventory.vars = inventory.vars or {}
	inventory.vars.isBag = nil

	local query = mysql:Update("ix_inventories")
		query:Update("inventory_type", "NULL")
		query:Where("inventory_id", inventory:GetID())
	query:Execute()

	if (IsValid(client)) then
		inventory:Sync(client)
	end

	return inventory
end

function FACTION:OnCharacterCreated(client, character)
	local inventory = ApplyMainInventoryLayout(character, self.invWidth, self.invHeight, client)

	if (!inventory) then
		return
	end

	inventory:Add("smg1", 1)
	inventory:Add("smg1ammo", 4)
	inventory:Add("handheld_radio", 1)
	inventory:Add("grenade", 1)
	inventory:Add("health_vial", 2)
	inventory:Add("ota_supplements", 2)
	inventory:Add("ota_pouches", 1)
	inventory:Add("ota_legpouches", 1)
	inventory:Add("ota_plate", 1)
end

function FACTION:GetDefaultName(client)
	return Schema:FormatCombineName("OTA", "OWS")
end

function FACTION:OnTransferred(character)
	local client = character:GetPlayer()
	local name = character:GetName()

	if (!Schema:GetCombineNameInfo(name)) then
		name = self:GetDefaultName(client)
	end

	character:SetName(Schema:NormalizeCombineName(name, "OTA"))
	character:SetModel(self.models[1])

	ApplyMainInventoryLayout(character, self.invWidth, self.invHeight, client)
end

function FACTION:OnNameChanged(client, oldValue, value)
	Schema:SyncCombineClass(client, value)
end

function FACTION:OnSpawn(client)
	local character = IsValid(client) and client:GetCharacter()

	if (!character) then
		return
	end

	ApplyMainInventoryLayout(character, self.invWidth, self.invHeight, client)
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
