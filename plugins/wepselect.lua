local PLUGIN = PLUGIN

PLUGIN.name = "Weapon Select"
PLUGIN.author = "Ronald"
PLUGIN.description = "Replaces the linear weapon selector with a slot-aware selector that respects equipped gear weapons. Enhanced with mouse wheel support."

ix.lang.AddTable("korean", {
	purpose = "설명",
	instructions = "사용 방법",

	["weapon_physgun"] = "피직스 건",

	-- Helix
	["Hands"] = "손",
	["Primary Fire: Throw/Punch\nSecondary Fire: Knock/Pickup\nSecondary Fire + Mouse: Rotate Object\nReload: Drop"] = "왼쪽 클릭: 던지기/주먹질하기\n오른쪽 클릭: 노크하기/집어들기\n오른쪽 클릭 + 마우스: 물체 회전\n재장전 버튼: 내려놓기",
	["Hitting things and knocking on doors."] = "뭔가를 때리거나 문을 노크합니다.",
	["Keys"] = "열쇠",
	["Primary Fire: Lock\nSecondary Fire: Unlock"] = "왼쪽 클릭: 잠그기\n오른쪽 클릭: 잠금 해제하기",
})

function PLUGIN:IsActive()
	return true
end

PLUGIN.customWeaponInfo = {
	-- HL2
	["weapon_ar2"] = {
		purpose = "ar2Desc"
	},
	["weapon_smg1"] = {
		purpose = "smg1Desc"
	},
	["weapon_shotgun"] = {
		purpose = "shotgunDesc"
	},
	["weapon_357"] = {
		purpose = "revolverDesc"
	},
	["weapon_pistol"] = {
		purpose = "pistolDesc"
	},
	["weapon_crowbar"] = {
		purpose = "crowbarDesc"
	},
	["weapon_frag"] = {
		purpose = "grenadeDesc"
	},
	["weapon_stunstick"] = {
		purpose = "stunstickDesc"
	},
	["weapon_rpg"] = {
		purpose = "rpgDesc"
	},
	["weapon_crossbow"] = {
		purpose = "crossbowDesc"
	},

	-- HL2 RP
	["arc9_hl2_pistol"] = {
		purpose = "pistolDesc"
	},
	["arc9_hl2_smg1"] = {
		purpose = "smg1Desc"
	},
	["arc9_l4d2_spas12"] = {
		purpose = "shotgunDesc"
	},
	["arc9_rtb_akm"] = {
		purpose = "akmDesc"
	},
	["arc9_rtb_oicw"] = {
		purpose = "oicwDesc"
	},
	["arc9_hla_irifle"] = {
		purpose = "ar1Desc"
	},
	["weapon_ezt_mp5k"] = {
		purpose = "mp5kDesc"
	},
	["weapon_extinguisher"] = {
		purpose = "extinguisherDesc"
	},
	["weapon_molotov"] = {
		purpose = "molotovDesc"
	},
	["weapon_vj_hlr2_rpg"] = {
		purpose = "rpgDesc"
	},
	["weapon_rtbr_flaregun"] = {
		purpose = "flaregunDesc"
	},
	["weapon_rtbr_frag"] = {
		purpose = "grenadeDesc"
	},
}

if SERVER then
	util.AddNetworkString("ixSlotWepSelect")

	net.Receive("ixSlotWepSelect", function(_, client)
		local weaponClass = net.ReadString()
		local weapon = client:GetWeapon(weaponClass)

		if IsValid(weapon) then
			client:SelectWeapon(weaponClass)
		end
	end)

	return
end

-- CLIENT SIDE

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

}

local HUD_BG = Color(8, 10, 14, 225)
local HUD_PANEL_ACTIVE = Color(120, 96, 44, 245)
local HUD_BORDER = Color(72, 80, 94, 180)
local HUD_BORDER_ACTIVE = Color(214, 178, 92, 255)
local HUD_ROW = Color(34, 38, 47, 235)
local HUD_ROW_PENDING = Color(88, 102, 132, 230)
local HUD_TEXT = Color(232, 234, 238)
local HUD_TEXT_DIM = Color(150, 158, 170)
local HUD_TEXT_MUTED = Color(108, 116, 128)
local HUD_TEXT_ACTIVE = Color(24, 20, 12)
local HUD_ROW_HOVER = Color(65, 78, 105, 250)
local HUD_BORDER_HOVER = Color(240, 210, 140, 255)

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
PLUGIN.currentWeaponClass = nil
PLUGIN.hoveredIndex = nil
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
PLUGIN.xOffset = -100
PLUGIN.fadeAlpha = 0

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
	else
		printName = L(printName)
	end

	return isstring(printName) and printName or class
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

	for _, item in pairs(items) do
		if item.class and item:GetData("equip") == true then
			lookup[item.class] = item
		end
	end

	return lookup
end

local function GuessWeaponSlotInfo(class, item, stored)
	if class == "ix_hands" then
		return 0, 0
	elseif class == "ix_keys" then
		return 0, 1
	elseif class == "weapon_physgun" then
		return 0, 1000
	elseif class == "gmod_tool" then
		return 0, 1001
	end

	if class == "ix_suitcase" then
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

function PLUGIN:GetWeaponSlotInfo(weapon, item)
	local class = weapon:GetClass()
	local stored = GetStoredWeapon(class)
	local slot = nil
	local slotPos = nil

	slot, slotPos = GuessWeaponSlotInfo(class, item, stored)

	if slot == nil then
		slot = weapon.Slot or (stored and stored.Slot)
	end

	if slotPos == nil then
		slotPos = weapon.SlotPos or (stored and stored.SlotPos)
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

	local itemLookup = self:GetEquippedWeaponItems(client)
	local records = {}

	for _, weapon in ipairs(client:GetWeapons()) do
		if self:ShouldIgnoreWeapon(weapon) then
			continue
		end

		local item = itemLookup[weapon:GetClass()]
		local slot, slotPos = self:GetWeaponSlotInfo(weapon, item)

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
		hoveredIndex = selectedIndex,
		expires = CurTime() + self.displayDuration
	}
	
	self.hoveredIndex = selectedIndex
end

function PLUGIN:ConfirmSelection(client)
	if not self.hudState or not self.hoveredIndex then
		return false
	end

	local records = self:GetSelectableWeapons(client)
	local record = records[self.hoveredIndex]

	if not record or not IsValid(record.weapon) then
		return false
	end

	local activeWeapon = client:GetActiveWeapon()
	local activeClass = IsValid(activeWeapon) and activeWeapon:GetClass() or nil

	if IsValid(activeWeapon) and activeClass ~= record.class then
		self.lastWeaponClass = activeClass
	end

	self.pendingWeaponClass = record.class
	self.pendingWeaponTime = CurTime() + 2

	net.Start("ixSlotWepSelect")
		net.WriteString(record.class)
	net.SendToServer()

	input.SelectWeapon(record.weapon)
	self.currentWeaponClass = record.class

	LocalPlayer():EmitSound("HL2Player.Use", 60, 110)

	self.hudState = nil
	self.hoveredIndex = nil
	return true
end

function PLUGIN:SelectRecord(client, records, targetIndex)
	local record = records[targetIndex]
	if not record then
		return false
	end

	self:StoreHudState(records, targetIndex)
	LocalPlayer():EmitSound("common/talk.wav", 40, 180)

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
			self:StoreHudState(records, self:FindRecordIndexByClass(records, "ix_hands"))
		end
		return true
	end

	if activeClass == "ix_hands" and not pendingClass then
		self.currentWeaponClass = "ix_hands"
		if records then
			self:StoreHudState(records, self:FindRecordIndexByClass(records, "ix_hands"))
		end
		return true
	end

	if IsValid(activeWeapon) and activeClass ~= "ix_hands" then
		self.lastWeaponClass = activeClass
	end

	self.pendingWeaponClass = "ix_hands"
	self.pendingWeaponTime = CurTime() + 2

	net.Start("ixSlotWepSelect")
		net.WriteString("ix_hands")
	net.SendToServer()

	input.SelectWeapon(hands)

	self.currentWeaponClass = "ix_hands"

	if records then
		self:StoreHudState(records, self:FindRecordIndexByClass(records, "ix_hands"))
	end

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

	local result = self:SelectRecord(client, records, targetIndex)
	return result
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

	local activeIndex = (self.hudState and self.hudState.expires > CurTime() and self.hoveredIndex) or self:GetReferenceRecordIndex(records, client)
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

	if #slotRecords > 0 then
		return self:SelectRecord(client, records, slotRecords[nextSlotIndex].recordIndex)
	else
		self:StoreHudState(records, nil)
		self.hudState.selectedSlot = slot
		return true
	end
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

	-- Allow scrolling/binding if we are hovering a VGUI panel that isn't the world
	local hovered = vgui.GetHoveredPanel()
	if IsValid(hovered) and hovered != vgui.GetWorldPanel() then
		return false
	end

	if IsValid(ix.gui.chat) and ix.gui.chat:GetActive() then
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
				local bJustSwitched = false

				if not activeRecord or activeRecord.slot ~= slot then
					self:SelectSlot(client, slot)
					bJustSwitched = true
				end

				self.heldSlot = slot
				self.heldSlotCode = tonumber(code) or nil
				self.heldSlotTime = CurTime()
				self.heldSlotTriggered = bJustSwitched
				
				if not bJustSwitched then
					local hoveredIndex = (self.hudState and self.hudState.expires > CurTime() and self.hoveredIndex) or self:FindRecordIndex(records, client:GetActiveWeapon())
					self:StoreHudState(records, hoveredIndex)
				end

				return true
			end

			if self.heldSlot == slot then
				if not self.heldSlotTriggered then
					self:SelectSlot(client, slot)
				end

				self:ClearHeldSlot()
				return true
			end
		end

		return true
	end

	if not pressed then
		return
	end

	self:ClearHeldSlot()

	if bind:find("+attack", 1, true) then
		if self.hudState and self.hudState.expires > CurTime() then
			return self:ConfirmSelection(client) and true or nil
		end
	end

	if bind:find("invprev", 1, true) or bind:find("invnext", 1, true) then
		-- 스크롤이 무조건 차단되는 문제를 해결합니다.
		-- 1. 상호작용 개체(스크롤 패널 등)를 보고 있을 때는 허용합니다.
		local trace = client:GetEyeTraceNoCursor()
		if IsValid(trace.Entity) and (trace.Entity:GetClass() == "ix_scrollpanel" or trace.Entity.OnMouseWheeled) then
			return
		end

		-- 2. 무기 선택 메뉴가 명시적으로 소환되지 않은 상태에서는 휠을 차단하지 않습니다. (확대/축소 지원 등)
		-- 사용자가 원한 "무기 선택을 스크롤로 불가" 기능은 HUD가 열렸을 때만 차단함으로써 충족합니다.
		if not (self.hudState and self.hudState.expires > CurTime()) then
			return
		end

		return true
	elseif bind:find("lastinv", 1, true) then
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
		elseif (self.heldSlotTime + self.slotHoldDuration) <= CurTime() then
			self:SelectSlot(client, self.heldSlot)
			
			self.heldSlotTime = CurTime() - self.slotHoldDuration + 0.25
			self.heldSlotTriggered = true
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
	local client = LocalPlayer()
	local records_in_paint = self:GetSelectableWeapons(client)
	local state = self.hudState
	local targetAlpha = (state and state.expires > CurTime()) and 255 or 0
	
	self.fadeAlpha = Lerp(FrameTime() * 10, self.fadeAlpha or 0, targetAlpha)
	self.xOffset = Lerp(FrameTime() * 10, self.xOffset or -120, (targetAlpha > 0) and 40 or -120)

	if self.fadeAlpha < 1 then
		return
	end

	local fraction = self.fadeAlpha / 255
	local pendingClass = (self.pendingWeaponClass and (tonumber(self.pendingWeaponTime) or 0) > CurTime()) and self.pendingWeaponClass or nil
	
	local boxSize = 48
	local boxGap = 8
	local startX = self.xOffset
	local startY = ScrH() * 0.4 - (3 * (boxSize + boxGap))

	for slotIndex = 0, 5 do
		local slotY = startY + (slotIndex * (boxSize + boxGap))
		local isSelectedSlot = state and slotIndex == state.selectedSlot
		
		local slotInfo = nil
		if state then
			for _, info in ipairs(state.slots) do
				if info.slot == slotIndex then
					slotInfo = info
					break
				end
			end
		end

		local hasWeapons = slotInfo ~= nil
		local boxColor = isSelectedSlot and HUD_PANEL_ACTIVE or (hasWeapons and HUD_BG or ColorAlpha(HUD_BG, 100 * fraction))
		local borderColor = isSelectedSlot and HUD_BORDER_ACTIVE or (hasWeapons and HUD_BORDER or ColorAlpha(HUD_BORDER, 60 * fraction))
		local textColor = isSelectedSlot and HUD_TEXT_ACTIVE or (hasWeapons and HUD_TEXT or HUD_TEXT_MUTED)

		draw.RoundedBox(8, startX, slotY, boxSize, boxSize, ColorAlpha(boxColor, 225 * fraction))
		surface.SetDrawColor(ColorAlpha(borderColor, 200 * fraction))
		surface.DrawOutlinedRect(startX, slotY, boxSize, boxSize, isSelectedSlot and 2 or 1)

		local ROMAN_NUMERALS = {"I", "II", "III", "IV", "V", "VI"}
		draw.SimpleText(ROMAN_NUMERALS[slotIndex + 1] or tostring(slotIndex + 1), "ixMediumFont", startX + (boxSize * 0.5), slotY + (boxSize * 0.5), ColorAlpha(textColor, 255 * fraction), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if isSelectedSlot and slotInfo then
			local listX = startX + boxSize + 15
			local rowHeight = 36
			local rowWidth = 240

			for k, record in ipairs(slotInfo.records) do
				local rowY = slotY + (k - 1) * (rowHeight + 4)
				local isCurrentWeapon = self.currentWeaponClass == record.class
				local isHovered = state.hoveredIndex == self:FindRecordIndex(state.slots_flattened or records_in_paint, record.weapon) -- This needs careful index handling
				
				-- find current record index in global records list for comparison
				local globalIndex = 0
				for _, r in ipairs(records_in_paint) do
					globalIndex = globalIndex + 1
					if r.weapon == record.weapon then break end
				end
				
				isHovered = state.hoveredIndex == globalIndex

				local isPendingWeapon = pendingClass == record.class and not isCurrentWeapon
				
				local rowColor = HUD_ROW
				local rowTextColor = HUD_TEXT
				local rowBorderColor = HUD_BORDER

				if isHovered then
					rowColor = HUD_ROW_HOVER
					rowBorderColor = HUD_BORDER_HOVER
					rowTextColor = HUD_TEXT
					
					surface.SetDrawColor(ColorAlpha(rowBorderColor, 255 * fraction))
					surface.DrawRect(listX, rowY, 4, rowHeight)
				elseif isCurrentWeapon then
					rowColor = HUD_PANEL_ACTIVE
					rowTextColor = HUD_TEXT_ACTIVE
					rowBorderColor = HUD_BORDER_ACTIVE
					
					surface.SetDrawColor(ColorAlpha(rowBorderColor, 255 * fraction))
					surface.DrawRect(listX, rowY, 4, rowHeight)
				elseif isPendingWeapon then
					rowColor = HUD_ROW_PENDING
					rowTextColor = HUD_TEXT
					
					surface.SetDrawColor(ColorAlpha(rowBorderColor, 100 * fraction))
					surface.DrawOutlinedRect(listX, rowY, rowWidth, rowHeight, 1)
				else
					surface.SetDrawColor(ColorAlpha(rowBorderColor, 100 * fraction))
					surface.DrawOutlinedRect(listX, rowY, rowWidth, rowHeight, 1)
				end

				draw.RoundedBox(6, listX, rowY, rowWidth, rowHeight, ColorAlpha(rowColor, 235 * fraction))
				draw.SimpleText(ClipTextToWidth(record.name, "ixSmallFont", rowWidth - 30), "ixSmallFont", listX + 12, rowY + (rowHeight * 0.5), ColorAlpha(rowTextColor, 255 * fraction), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText(tostring(k), "ixSmallFont", listX + rowWidth - 10, rowY + (rowHeight * 0.5), ColorAlpha((isHovered or isCurrentWeapon) and rowTextColor or HUD_TEXT_DIM, 150 * fraction), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			end
		end
	end

	if state and state.hoveredIndex and records_in_paint[state.hoveredIndex] then
		local record = records_in_paint[state.hoveredIndex]
		local weapon = record.weapon
		
		local function GetLocalText(text)
			if not text or text == "" or text == "None" then return "" end
			if string.StartWith(text, "#") then
				text = language.GetPhrase(string.sub(text, 2))
			else
				text = L(text)
			end
			return string.gsub(text, "\\n", "\n")
		end

		local custom = self.customWeaponInfo[weapon:GetClass()]
		local purpose = GetLocalText(custom and custom.purpose or weapon.Purpose)
		local instructions = GetLocalText(custom and custom.instructions or weapon.Instructions)
		
		if purpose ~= "" or instructions ~= "" then
			local infoX = self.xOffset + 48 + 15 + 240 + 20
			local infoY = startY + (state.selectedSlot or 0) * (48 + 8)
			local infoWidth = 320
			
			surface.SetFont("ixSmallFont")
			
			local textItems = {}
			if purpose ~= "" and purpose ~= "None" then
				table.insert(textItems, {title = L("purpose"):upper(), text = purpose})
			end
			if instructions ~= "" and instructions ~= "None" then
				table.insert(textItems, {title = L("instructions"):upper(), text = instructions})
			end
			
			local totalHeight = 15 -- Initial top padding
			for _, item in ipairs(textItems) do
				local wrapped = ix.util.WrapText(item.text, infoWidth - 40, "ixSmallFont")
				if istable(wrapped) then wrapped = table.concat(wrapped, "\n") end
				item.wrapped = wrapped
				local _, th = surface.GetTextSize(wrapped)
				item.height = th + 30 -- Title + Spacing + Wraps
				totalHeight = totalHeight + item.height + 10
			end
			
			-- Draw Main Box with Shadow Effect
			draw.RoundedBox(8, infoX + 2, infoY + 2, infoWidth, totalHeight, Color(0, 0, 0, 150)) -- Shadow
			draw.RoundedBox(8, infoX, infoY, infoWidth, totalHeight, ColorAlpha(HUD_BG, 245 * fraction))
			
			-- Main Highlight Left Bar
			surface.SetDrawColor(ColorAlpha(HUD_BORDER_ACTIVE, 255 * fraction))
			surface.DrawRect(infoX, infoY + 10, 4, totalHeight - 20)
			
			surface.SetDrawColor(ColorAlpha(HUD_BORDER, 80 * fraction))
			surface.DrawOutlinedRect(infoX, infoY, infoWidth, totalHeight, 1)

			local currentY = infoY + 15
			for i, item in ipairs(textItems) do
				-- Draw Section Header
				draw.SimpleText(item.title, "ixSmallFont", infoX + 18, currentY, ColorAlpha(HUD_BORDER_ACTIVE, 255 * fraction), TEXT_ALIGN_LEFT)
				
				-- Separator line below header
				surface.SetDrawColor(ColorAlpha(HUD_BORDER, 40 * fraction))
				surface.DrawRect(infoX + 18, currentY + 18, infoWidth - 36, 1)
				
				-- Wrapped Text
				draw.DrawText(item.wrapped, "ixSmallFont", infoX + 18, currentY + 22, ColorAlpha(HUD_TEXT, 220 * fraction), TEXT_ALIGN_LEFT)
				
				currentY = currentY + item.height + 10
			end
		end
	end
end
