local PLUGIN = PLUGIN

PLUGIN.name = "Slot Weapon Select"
PLUGIN.author = "OpenAI"
PLUGIN.description = "Replaces the linear web weapon selector with a slot-aware selector that respects equipped gear weapons."

if SERVER then
	util.AddNetworkString("ixSlotWepSelect")

	PLUGIN.pendingRaise = {}
	PLUGIN.cachedRaised = {}

	local function GetTimerName(client)
		return "ixSlotWepSelect_" .. client:SteamID64()
	end

	local function ClearPending(client)
		if not IsValid(client) then
			return
		end

		PLUGIN.pendingRaise[client] = nil
		timer.Remove(GetTimerName(client))
	end

	local function GetCachedRaised(client)
		if not IsValid(client) then
			return false
		end

		local cachedRaised = PLUGIN.cachedRaised[client]
		if isbool(cachedRaised) then
			return cachedRaised
		end

		return client:IsWepRaised() == true
	end

	local function ApplyRaisedCallback(weapon, bRaised)
		if not IsValid(weapon) then
			return
		end

		if bRaised and weapon.OnRaised then
			weapon:OnRaised()
		elseif not bRaised and weapon.OnLowered then
			weapon:OnLowered()
		end
	end

	local function UpdatePlayerHoldType(client, weapon)
		weapon = weapon or client:GetActiveWeapon()
		local holdType = "normal"

		if (IsValid(weapon)) then
			holdType = weapon.HoldType or weapon:GetHoldType()
			holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType
		end

		client.ixAnimHoldType = holdType
	end

	local function UpdateAnimationTable(client, vehicle)
		local baseTable = ix.anim[client.ixAnimModelClass] or {}

		if (IsValid(client) and IsValid(vehicle)) then
			local vehicleClass = vehicle:IsChair() and "chair" or vehicle:GetClass()

			if (vehicleClass == "prop_vehicle_prisoner_pod" and vehicle:GetModel() and !string.find(string.lower(vehicle:GetModel()), "prisoner_pod")) then
				vehicleClass = "chair"
			end

			if (baseTable.vehicle and baseTable.vehicle[vehicleClass]) then
				client.ixAnimTable = baseTable.vehicle[vehicleClass]
			else
				client.ixAnimTable = baseTable.vehicle and baseTable.vehicle.chair or {ACT_BUSY_SIT_CHAIR, Vector(0, 0, 0)}
			end
		else
			client.ixAnimTable = baseTable[client.ixAnimHoldType]
		end

		client.ixAnimGlide = baseTable["glide"]
	end

	local function ApplyRaisedState(client, weapon, bRaised)
		if not IsValid(client) or not IsValid(weapon) then
			return false
		end

		PLUGIN.cachedRaised[client] = bRaised == true

		if (weapon.IsAlwaysRaised or ALWAYS_RAISED[weapon:GetClass()]) then
			PLUGIN.cachedRaised[client] = true
			client:SetWepRaised(true, weapon)
			ApplyRaisedCallback(weapon, true)
			return true
		end

		if (weapon.IsAlwaysLowered or weapon.NeverRaised or client:IsRestricted()) then
			PLUGIN.cachedRaised[client] = false
			client:SetWepRaised(false, weapon)
			ApplyRaisedCallback(weapon, false)
			return true
		end

		if (ix.config.Get("weaponAlwaysRaised")) then
			PLUGIN.cachedRaised[client] = true
			client:SetWepRaised(true, weapon)
			ApplyRaisedCallback(weapon, true)
			return true
		end

		client:SetWepRaised(bRaised == true, weapon)

		if (bRaised == true) then
			timer.Remove("ixWeaponRaise" .. client:SteamID64())
			client:SetNetVar("canShoot", true)
		end

		ApplyRaisedCallback(weapon, bRaised == true)
		return true
	end

	local function ProcessPending(client)
		local pending = PLUGIN.pendingRaise[client]
		if not istable(pending) then
			ClearPending(client)
			return
		end

		if not IsValid(client) or type(pending.expires) ~= "number" or pending.expires <= CurTime() then
			ClearPending(client)
			return
		end

		local desiredWeapon = client:GetWeapon(pending.weaponClass)
		if not IsValid(desiredWeapon) then
			ClearPending(client)
			return
		end

		local activeWeapon = client:GetActiveWeapon()
		if activeWeapon == desiredWeapon then
			ApplyRaisedState(client, activeWeapon, pending.raised)

			local holdUntil = tonumber(pending.holdUntil)
			if not holdUntil then
				pending.holdUntil = CurTime() + 0.25
			elseif holdUntil <= CurTime() then
				ClearPending(client)
			end

			return
		end
	end

	local function BeginPending(client, weaponClass, bRaised)
		if not IsValid(client) or not isstring(weaponClass) or weaponClass == "" then
			return
		end

		PLUGIN.pendingRaise[client] = {
			weaponClass = weaponClass,
			raised = bRaised == true,
			expires = CurTime() + 2,
			holdUntil = nil
		}

		PLUGIN.cachedRaised[client] = bRaised == true

		local timerName = GetTimerName(client)
		timer.Remove(timerName)
		timer.Create(timerName, 0.05, 0, function()
			ProcessPending(client)
		end)

		ProcessPending(client)
	end

	net.Receive("ixSlotWepSelect", function(_, client)
		local weaponClass = net.ReadString()
		local bRaised = net.ReadBool()
		BeginPending(client, weaponClass, bRaised)
	end)

	function PLUGIN:PlayerSwitchWeapon(client, oldWeapon, weapon)
		if not IsValid(client) or not IsValid(weapon) or oldWeapon == weapon then
			return
		end

		local pending = self.pendingRaise[client]
		if istable(pending) and type(pending.expires) == "number" and pending.expires > CurTime() then
			return
		end

		BeginPending(client, weapon:GetClass(), GetCachedRaised(client))
	end

	function PLUGIN:PlayerWeaponChanged(client, weapon)
		if not IsValid(client) or not IsValid(weapon) then
			return
		end

		local pending = self.pendingRaise[client]
		local bRaised = GetCachedRaised(client)

		if istable(pending) and pending.weaponClass == weapon:GetClass() then
			bRaised = pending.raised == true

			if not tonumber(pending.holdUntil) then
				pending.holdUntil = CurTime() + 0.25
			end
		elseif not istable(pending) then
			ClearPending(client)
		end

		UpdatePlayerHoldType(client, weapon)
		UpdateAnimationTable(client, client:InVehicle() and client:GetVehicle() or nil)
		ApplyRaisedState(client, weapon, bRaised)
		return true
	end

	function PLUGIN:PlayerDisconnected(client)
		ClearPending(client)
		self.cachedRaised[client] = nil
	end

	function PLUGIN:StartCommand(client)
		if not IsValid(client) then
			return
		end

		self.cachedRaised[client] = client:IsWepRaised() == true
	end

	return
end

local CATEGORY_SLOT_FALLBACK = {
	melee = 0,
	sidearm = 1,
	primary = 2,
	grenade = 3
}

local CATEGORY_POS_FALLBACK = {
	melee = 10,
	sidearm = 20,
	primary = 30,
	grenade = 40
}

local EXCLUDED_CLASSES = {
	ix_hands = true,
	ix_keys = true
}

local HUD_BG = Color(8, 10, 14, 225)
local HUD_PANEL = Color(20, 24, 31, 240)
local HUD_PANEL_ACTIVE = Color(120, 96, 44, 245)
local HUD_BORDER = Color(72, 80, 94, 180)
local HUD_BORDER_ACTIVE = Color(214, 178, 92, 255)
local HUD_ROW = Color(34, 38, 47, 235)
local HUD_ROW_ACTIVE = Color(214, 178, 92, 245)
local HUD_ROW_PENDING = Color(88, 102, 132, 230)
local HUD_TEXT = Color(232, 234, 238)
local HUD_TEXT_DIM = Color(150, 158, 170)
local HUD_TEXT_MUTED = Color(108, 116, 128)
local HUD_TEXT_ACTIVE = Color(24, 20, 12)

local function ClipTextToWidth(text, font, maxWidth)
	text = tostring(text or "")
	surface.SetFont(font)

	local textWidth = surface.GetTextSize(text)
	if textWidth <= maxWidth then
		return text
	end

	local ellipsis = "..."
	local ellipsisWidth = surface.GetTextSize(ellipsis)
	local clipped = text

	while #clipped > 0 do
		clipped = string.sub(clipped, 1, #clipped - 1)
		if surface.GetTextSize(clipped) + ellipsisWidth <= maxWidth then
			return clipped .. ellipsis
		end
	end

	return ellipsis
end

PLUGIN.displayDuration = 1.5
PLUGIN.lastWeaponClass = nil
PLUGIN.currentWeaponClass = nil
PLUGIN.lastSlotKey = nil
PLUGIN.lastSlotKeyTime = 0
PLUGIN.lastSlotCycleIndex = 0
PLUGIN.hudState = nil
PLUGIN.pendingWeaponClass = nil
PLUGIN.pendingWeaponTime = 0
PLUGIN.slotHoldDuration = 0.35
PLUGIN.heldSlot = nil
PLUGIN.heldSlotCode = nil
PLUGIN.heldSlotTime = 0
PLUGIN.heldSlotTriggered = false

local function GetStoredWeapon(class)
	if not class or class == "" then
		return nil
	end

	return weapons.GetStored(class)
end

local function GetWeaponPrintName(weapon, item)
	if item and item.GetName then
		return item:GetName()
	end

	local class = IsValid(weapon) and weapon:GetClass() or ""
	local stored = GetStoredWeapon(class)
	local printName = stored and stored.PrintName or class

	if isstring(printName) and string.StartWith(printName, "#") then
		printName = language.GetPhrase(string.sub(printName, 2))
	end

	return isstring(printName) and printName or class
end

local function ResetHelixWeaponSelect(client)
	if not IsValid(client) then return end

	local weaponSelect = ix.plugin.Get("wepselect")
	if not weaponSelect then return end

	local weaponsList = client:GetWeapons()
	local activeWeapon = client:GetActiveWeapon()
	local activeIndex = 1

	for i = 1, #weaponsList do
		if weaponsList[i] == activeWeapon then
			activeIndex = i
			break
		end
	end

	weaponSelect.index = activeIndex
	weaponSelect.deltaIndex = activeIndex
	weaponSelect.alpha = 0
	weaponSelect.alphaDelta = 0
	weaponSelect.fadeTime = 0
	weaponSelect.infoAlpha = 0
	weaponSelect.markup = nil
end

function PLUGIN:ShouldIgnoreWeapon(weapon)
	if not IsValid(weapon) then
		return true
	end

	return EXCLUDED_CLASSES[weapon:GetClass()] == true
end

function PLUGIN:GetEquippedWeaponItems(client)
	local character = IsValid(client) and client:GetCharacter() or nil
	local inventory = character and character:GetInventory() or nil
	local items = inventory and inventory.GetItems and inventory:GetItems() or {}
	local lookup = {}
	local orderedItems = {}

	for _, item in pairs(items) do
		if item.class and item:GetData("equip") == true then
			lookup[item.class] = item

			local equipTime = tonumber(item:GetData("equipTime", 0)) or 0
			if equipTime > 0 and item.class ~= "weapon_physgun" and item.class ~= "gmod_tool" then
				orderedItems[#orderedItems + 1] = item
			end
		end
	end

	table.sort(orderedItems, function(a, b)
		local aTime = tonumber(a:GetData("equipTime", 0)) or 0
		local bTime = tonumber(b:GetData("equipTime", 0)) or 0

		if aTime ~= bTime then
			return aTime < bTime
		end

		local aID = tonumber(a.GetID and a:GetID() or 0) or 0
		local bID = tonumber(b.GetID and b:GetID() or 0) or 0

		if aID ~= bID then
			return aID < bID
		end

		return tostring(a.class or "") < tostring(b.class or "")
	end)

	local slotLookup = {}

	for index, item in ipairs(orderedItems) do
		if isstring(item.class) and item.class ~= "" then
			slotLookup[item.class] = index - 1
		end
	end

	return lookup, slotLookup
end

local function GuessWeaponSlotInfo(class, item, stored)
	if class == "weapon_physgun" or class == "gmod_tool" then
		return 5, 0
	end

	if item and item.weaponCategory then
		local slot = CATEGORY_SLOT_FALLBACK[item.weaponCategory]
		local slotPos = CATEGORY_POS_FALLBACK[item.weaponCategory]

		if slot ~= nil or slotPos ~= nil then
			return slot, slotPos
		end
	end

	local probe = string.lower(tostring((stored and stored.PrintName) or class or ""))

	if probe:find("crowbar", 1, true) or probe:find("stunstick", 1, true) or probe:find("knife", 1, true)
	or probe:find("melee", 1, true) or probe:find("axe", 1, true) or probe:find("pan", 1, true)
	or probe:find("pipe", 1, true) or probe:find("bottle", 1, true) then
		return 0, 10
	end

	if probe:find("pistol", 1, true) or probe:find("357", 1, true) or probe:find("revolver", 1, true)
	or probe:find("flaregun", 1, true) then
		return 1, 20
	end

	if probe:find("grenade", 1, true) or probe:find("rpg", 1, true) or probe:find("molotov", 1, true)
	or probe:find("frag", 1, true) or probe:find("gascan", 1, true) then
		return 3, 40
	end

	if probe:find("smg", 1, true) or probe:find("ar2", 1, true) or probe:find("rifle", 1, true)
	or probe:find("shotgun", 1, true) or probe:find("sniper", 1, true) or probe:find("crossbow", 1, true)
	or probe:find("oicw", 1, true) or probe:find("mp5", 1, true) or probe:find("ak", 1, true)
	or probe:find("m16", 1, true) then
		return 2, 30
	end
end

function PLUGIN:GetWeaponSlotInfo(weapon, item, equippedSlots)
	local class = weapon:GetClass()
	local stored = GetStoredWeapon(class)
	local slot = item and equippedSlots and equippedSlots[class] or nil
	local slotPos = slot ~= nil and 0 or nil

	if slot == nil then
		slot = weapon.Slot
	end

	if slotPos == nil then
		slotPos = weapon.SlotPos
	end

	if slot == nil and stored then
		slot = stored.Slot
	end

	if slotPos == nil and stored then
		slotPos = stored.SlotPos
	end

	if slot == nil or slotPos == nil then
		local fallbackSlot, fallbackPos = GuessWeaponSlotInfo(class, item, stored)

		if slot == nil then
			slot = fallbackSlot
		end

		if slotPos == nil then
			slotPos = fallbackPos
		end
	end

	slot = math.max(0, math.floor(tonumber(slot) or 5))
	slotPos = math.max(0, math.floor(tonumber(slotPos) or 99))

	return slot, slotPos
end

function PLUGIN:GetSelectableWeapons(client)
	if not IsValid(client) then
		return {}
	end

	local itemLookup, equippedSlots = self:GetEquippedWeaponItems(client)
	local records = {}

	for _, weapon in ipairs(client:GetWeapons()) do
		if self:ShouldIgnoreWeapon(weapon) then
			continue
		end

		local item = itemLookup[weapon:GetClass()]
		local slot, slotPos = self:GetWeaponSlotInfo(weapon, item, equippedSlots)

		records[#records + 1] = {
			weapon = weapon,
			item = item,
			class = weapon:GetClass(),
			slot = slot,
			slotPos = slotPos,
			name = GetWeaponPrintName(weapon, item),
			isUtility = item == nil
		}
	end

	table.sort(records, function(a, b)
		if a.slot ~= b.slot then
			return a.slot < b.slot
		end

		if a.slotPos ~= b.slotPos then
			return a.slotPos < b.slotPos
		end

		if a.isUtility ~= b.isUtility then
			return a.isUtility == false
		end

		return a.name < b.name
	end)

	return records
end

function PLUGIN:FindRecordIndex(records, weapon)
	if not IsValid(weapon) then
		return nil
	end

	for index, record in ipairs(records) do
		if record.weapon == weapon then
			return index
		end
	end
end

function PLUGIN:FindRecordIndexByClass(records, class)
	if not isstring(class) or class == "" then
		return nil
	end

	for index, record in ipairs(records) do
		if record.class == class then
			return index
		end
	end
end

function PLUGIN:GetReferenceRecordIndex(records, client)
	local pendingClass = self.pendingWeaponClass
	if pendingClass and (tonumber(self.pendingWeaponTime) or 0) > CurTime() then
		local pendingIndex = self:FindRecordIndexByClass(records, pendingClass)
		if pendingIndex then
			return pendingIndex
		end
	end

	return self:FindRecordIndex(records, client:GetActiveWeapon())
end

function PLUGIN:StoreHudState(records, selectedIndex)
	local grouped = {}
	local orderedSlots = {}

	for _, record in ipairs(records) do
		grouped[record.slot] = grouped[record.slot] or {
			slot = record.slot,
			records = {}
		}

		if #grouped[record.slot].records == 0 then
			orderedSlots[#orderedSlots + 1] = grouped[record.slot]
		end

		grouped[record.slot].records[#grouped[record.slot].records + 1] = record
	end

	self.hudState = {
		slots = orderedSlots,
		selectedSlot = records[selectedIndex] and records[selectedIndex].slot or nil,
		expires = CurTime() + self.displayDuration
	}
end

function PLUGIN:SelectRecord(client, records, targetIndex)
	local record = records[targetIndex]
	if not record or not IsValid(record.weapon) then
		return false
	end

	local activeWeapon = client:GetActiveWeapon()
	local activeClass = IsValid(activeWeapon) and activeWeapon:GetClass() or nil
	local pendingClass = (self.pendingWeaponClass and (tonumber(self.pendingWeaponTime) or 0) > CurTime()) and self.pendingWeaponClass or nil

	if pendingClass == record.class then
		self.currentWeaponClass = record.class
		self:StoreHudState(records, targetIndex)
		ResetHelixWeaponSelect(client)
		return true
	end

	if activeClass == record.class and not pendingClass then
		self.currentWeaponClass = record.class
		self:StoreHudState(records, targetIndex)
		ResetHelixWeaponSelect(client)
		return true
	end

	if IsValid(activeWeapon) and activeWeapon ~= record.weapon then
		self.lastWeaponClass = activeWeapon:GetClass()
	end

	self.pendingWeaponClass = record.class
	self.pendingWeaponTime = CurTime() + 2

	net.Start("ixSlotWepSelect")
		net.WriteString(record.class)
		net.WriteBool(client:IsWepRaised() == true)
	net.SendToServer()

	input.SelectWeapon(record.weapon)

	self.currentWeaponClass = record.class

	self:StoreHudState(records, targetIndex)
	ResetHelixWeaponSelect(client)

	return true
end

function PLUGIN:ClearHeldSlot()
	self.heldSlot = nil
	self.heldSlotCode = nil
	self.heldSlotTime = 0
	self.heldSlotTriggered = false
end


function PLUGIN:GetActiveSlotInfo(client, records)
	records = records or self:GetSelectableWeapons(client)

	local activeIndex = self:GetReferenceRecordIndex(records, client)
	local activeRecord = activeIndex and records[activeIndex] or nil

	return records, activeIndex, activeRecord
end
function PLUGIN:SelectHands(client, records)
	local hands = client:GetWeapon("ix_hands")
	if not IsValid(hands) then
		return false
	end

	local activeWeapon = client:GetActiveWeapon()
	local activeClass = IsValid(activeWeapon) and activeWeapon:GetClass() or nil
	local pendingClass = (self.pendingWeaponClass and (tonumber(self.pendingWeaponTime) or 0) > CurTime()) and self.pendingWeaponClass or nil

	if pendingClass == "ix_hands" then
		self.currentWeaponClass = "ix_hands"
		if records then
			self:StoreHudState(records)
		end
		ResetHelixWeaponSelect(client)
		return true
	end

	if activeClass == "ix_hands" and not pendingClass then
		self.currentWeaponClass = "ix_hands"
		if records then
			self:StoreHudState(records)
		end
		ResetHelixWeaponSelect(client)
		return true
	end

	if IsValid(activeWeapon) and activeClass ~= "ix_hands" then
		self.lastWeaponClass = activeClass
	end

	self.pendingWeaponClass = "ix_hands"
	self.pendingWeaponTime = CurTime() + 2

	net.Start("ixSlotWepSelect")
		net.WriteString("ix_hands")
		net.WriteBool(false)
	net.SendToServer()

	input.SelectWeapon(hands)

	self.currentWeaponClass = "ix_hands"

	if records then
		self:StoreHudState(records)
	end
	ResetHelixWeaponSelect(client)

	return true
end

function PLUGIN:CycleWeapons(client, direction)
	local records = self:GetSelectableWeapons(client)
	if #records == 0 then
		return false
	end

	local activeIndex = self:GetReferenceRecordIndex(records, client) or 0
	local targetIndex = activeIndex + direction

	if targetIndex < 1 then
		targetIndex = #records
	elseif targetIndex > #records then
		targetIndex = 1
	end

	return self:SelectRecord(client, records, targetIndex)
end

function PLUGIN:SelectSlot(client, slot)
	local records = self:GetSelectableWeapons(client)
	if #records == 0 then
		return false
	end

	local slotRecords = {}

	for index, record in ipairs(records) do
		if record.slot == slot then
			slotRecords[#slotRecords + 1] = {
				recordIndex = index,
				record = record
			}
		end
	end

	if #slotRecords == 0 then
		return false
	end

	local activeIndex = self:GetReferenceRecordIndex(records, client)
	local activeSlotIndex

	for index, entry in ipairs(slotRecords) do
		if entry.recordIndex == activeIndex then
			activeSlotIndex = index
			break
		end
	end

	local nextSlotIndex = 1
	if activeSlotIndex then
		nextSlotIndex = activeSlotIndex % #slotRecords + 1
	else
		local now = CurTime()
		if self.lastSlotKey == slot and (now - self.lastSlotKeyTime) <= self.displayDuration then
			nextSlotIndex = self.lastSlotCycleIndex % #slotRecords + 1
		end
	end

	self.lastSlotKey = slot
	self.lastSlotKeyTime = CurTime()
	self.lastSlotCycleIndex = nextSlotIndex

	return self:SelectRecord(client, records, slotRecords[nextSlotIndex].recordIndex)
end

function PLUGIN:SelectLastWeapon(client)
	if not self.lastWeaponClass then
		return false
	end

	local records = self:GetSelectableWeapons(client)
	for index, record in ipairs(records) do
		if record.class == self.lastWeaponClass then
			return self:SelectRecord(client, records, index)
		end
	end

	return false
end

function PLUGIN:ShouldCaptureBind(client)
	if not IsValid(client) or client ~= LocalPlayer() then
		return false
	end

	if gui.IsGameUIVisible() or vgui.CursorVisible() then
		return false
	end

	if IsValid(ix.gui.chat) and ix.gui.chat:GetActive() then
		return false
	end

	if IsValid(ixScrollPanelAimed) then
		return false
	end

	return true
end

function PLUGIN:PlayerBindPress(client, bind, pressed, code)
	if not self:ShouldCaptureBind(client) then
		if not pressed then
			self:ClearHeldSlot()
		end
		return
	end

	bind = string.lower(bind)

	local slot = bind:match("slot(%d+)")
	if slot then
		slot = tonumber(slot)

		if slot and slot >= 1 then
			slot = slot - 1

			if pressed then
				local records, _, activeRecord = self:GetActiveSlotInfo(client)

				if not activeRecord or activeRecord.slot ~= slot then
					self:ClearHeldSlot()
					return self:SelectSlot(client, slot) and true or nil
				end

				self.heldSlot = slot
				self.heldSlotCode = tonumber(code) or nil
				self.heldSlotTime = CurTime()
				self.heldSlotTriggered = false
				return true
			end

			if self.heldSlot == slot then
				local result = true

				if not self.heldSlotTriggered then
					result = self:SelectSlot(client, slot)
				end

				self:ClearHeldSlot()
				return result and true or nil
			end
		end

		return
	end

	if not pressed then
		return
	end

	self:ClearHeldSlot()

	if bind:find("lastinv", 1, true) then
		return self:SelectLastWeapon(client) and true or nil
	end
end

function PLUGIN:Think()
	local client = LocalPlayer()
	if not IsValid(client) then return end

	local activeWeapon = client:GetActiveWeapon()
	local activeClass = IsValid(activeWeapon) and activeWeapon:GetClass() or nil

	if activeClass ~= self.currentWeaponClass then
		if self.currentWeaponClass and activeClass ~= self.currentWeaponClass then
			self.lastWeaponClass = self.currentWeaponClass
		end

		self.currentWeaponClass = activeClass
	end

	if self.heldSlot ~= nil then
		if self.heldSlotCode and self.heldSlotCode > 0 and not input.IsKeyDown(self.heldSlotCode) then
			self:ClearHeldSlot()
		elseif not self.heldSlotTriggered and (self.heldSlotTime + self.slotHoldDuration) <= CurTime() then
			local records, _, activeRecord = self:GetActiveSlotInfo(client)

			if activeRecord and activeRecord.slot == self.heldSlot then
				if self:SelectHands(client, records) then
					self.heldSlotTriggered = true
				else
					self:ClearHeldSlot()
				end
			else
				self:ClearHeldSlot()
			end
		end
	end

	if self.pendingWeaponClass then
		if activeClass == self.pendingWeaponClass then
			self.pendingWeaponClass = nil
			self.pendingWeaponTime = 0
		elseif (tonumber(self.pendingWeaponTime) or 0) <= CurTime() then
			self.pendingWeaponClass = nil
			self.pendingWeaponTime = 0
		end
	end

	if self.hudState and self.hudState.expires <= CurTime() then
		self.hudState = nil
	end
end

function PLUGIN:HUDShouldDraw(name)
	if name == "CHudWeaponSelection" then
		return false
	end
end

function PLUGIN:HUDPaint()
	local state = self.hudState
	if not state or state.expires <= CurTime() then
		return
	end

	local fade = math.Clamp((state.expires - CurTime()) / 0.2, 0, 1)
	local pendingClass = (self.pendingWeaponClass and (tonumber(self.pendingWeaponTime) or 0) > CurTime()) and self.pendingWeaponClass or nil
	local slotWidth = 172
	local headerHeight = 32
	local rowHeight = 26
	local slotGap = 12
	local cardPadding = 6
	local maxRows = 1

	for _, slotInfo in ipairs(state.slots) do
		maxRows = math.max(maxRows, #slotInfo.records)
	end

	local totalWidth = (#state.slots * slotWidth) + (math.max(#state.slots - 1, 0) * slotGap)
	local startX = math.floor((ScrW() - totalWidth) * 0.5)
	local cardHeight = headerHeight + (maxRows * rowHeight) + 12
	local startY = math.floor(ScrH() - 170 - cardHeight)

	for index, slotInfo in ipairs(state.slots) do
		local x = startX + (index - 1) * (slotWidth + slotGap)
		local y = startY
		local isSelectedSlot = slotInfo.slot == state.selectedSlot
		local borderColor = isSelectedSlot and ColorAlpha(HUD_BORDER_ACTIVE, 255 * fade) or ColorAlpha(HUD_BORDER, 255 * fade)
		local panelColor = isSelectedSlot and ColorAlpha(HUD_PANEL_ACTIVE, 245 * fade) or ColorAlpha(HUD_PANEL, 235 * fade)

		draw.RoundedBox(10, x, y, slotWidth, cardHeight, ColorAlpha(HUD_BG, 235 * fade))
		surface.SetDrawColor(borderColor)
		surface.DrawOutlinedRect(x, y, slotWidth, cardHeight, 1)
		draw.RoundedBox(8, x + cardPadding, y + cardPadding, slotWidth - cardPadding * 2, headerHeight, panelColor)
		draw.RoundedBox(6, x + 10, y + 9, 24, 20, isSelectedSlot and ColorAlpha(HUD_ROW_ACTIVE, 255 * fade) or ColorAlpha(HUD_ROW, 255 * fade))
		draw.SimpleText(tostring(slotInfo.slot + 1), "ixSmallFont", x + 22, y + 12, isSelectedSlot and HUD_TEXT_ACTIVE or HUD_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		draw.SimpleText("SLOT", "ixSmallFont", x + 42, y + 12, isSelectedSlot and HUD_TEXT_ACTIVE or HUD_TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(tostring(#slotInfo.records), "ixSmallFont", x + slotWidth - 14, y + 12, isSelectedSlot and HUD_TEXT_ACTIVE or HUD_TEXT_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

		for row = 1, maxRows do
			local record = slotInfo.records[row]
			local rowY = y + headerHeight + 6 + (row - 1) * rowHeight

			if record then
				local isCurrentWeapon = self.currentWeaponClass == record.class
				local isPendingWeapon = pendingClass == record.class and not isCurrentWeapon
				local rowColor = ColorAlpha(HUD_ROW, 225 * fade)
				local textColor = HUD_TEXT
				local indexColor = HUD_TEXT_DIM

				if isCurrentWeapon then
					rowColor = ColorAlpha(HUD_ROW_ACTIVE, 245 * fade)
					textColor = HUD_TEXT_ACTIVE
					indexColor = HUD_TEXT_ACTIVE
				elseif isPendingWeapon then
					rowColor = ColorAlpha(HUD_ROW_PENDING, 240 * fade)
				end

				draw.RoundedBox(6, x + cardPadding, rowY, slotWidth - cardPadding * 2, rowHeight - 4, rowColor)
				draw.RoundedBox(4, x + 10, rowY + 4, 18, 14, ColorAlpha(HUD_BG, 160 * fade))
				draw.SimpleText(tostring(row), "ixSmallFont", x + 19, rowY + 5, indexColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
				draw.SimpleText(ClipTextToWidth(record.name, "ixSmallFont", slotWidth - 52), "ixSmallFont", x + 34, rowY + 5, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			else
				draw.RoundedBox(6, x + cardPadding, rowY, slotWidth - cardPadding * 2, rowHeight - 4, ColorAlpha(HUD_ROW, 70 * fade))
				draw.SimpleText("-", "ixSmallFont", x + slotWidth * 0.5, rowY + 5, ColorAlpha(HUD_TEXT_MUTED, 180 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			end
		end
	end
end
