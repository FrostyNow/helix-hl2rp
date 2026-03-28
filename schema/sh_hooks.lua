-- Business Area Access logic is now handled via global NetVars for maximum reliability.

function Schema:IsPlayerInBusinessArea(client)
	local character = IsValid(client) and client:GetCharacter()
	if (!character) then return false end

	local myFaction = client:Team()
	local myClass = character:GetClass()
	local currentArea = client:GetArea()
	local accessCache = (GetNetVar or (ix.net and ix.net.GetNetVar))("ixBusinessAccess", {})

	-- 1. Check by Area (Primary)
	if (currentArea and currentArea != "" and accessCache[currentArea]) then
		local info = accessCache[currentArea]
		
		-- If the dispenser has no faction/class restrictions, it's a public dispenser.
		if (!next(info.factions) and !next(info.classes)) then
			return true
		end

		-- Otherwise, check if the player matches the dispenser's restrictions.
		-- Using string keys to ensure consistency after network transmission.
		if (info.factions[tostring(myFaction)] or info.factions[myFaction] or
			(myClass and (info.classes[tostring(myClass)] or info.classes[myClass]))) then
			return true
		end
	end

	-- 2. Proximity Fallback (Check near entities if area system fails or player isn't in an area plugin boundary)
	-- This works on client only for entities in PVS, and on server for all entities.
	for _, v in ipairs(ents.FindByClass("ix_businessarea")) do
		if (client:GetPos():DistToSqr(v:GetPos()) < 100000) then -- ~316 units
			local factionsRaw = v:GetFactions() or "[]"
			local classesRaw = v:GetClasses() or "[]"
			
			if (factionsRaw == "[]" and classesRaw == "[]") then
				return true
			end

			local factions = util.JSONToTable(factionsRaw)
			if (table.HasValue(factions, myFaction) or table.HasValue(factions, tostring(myFaction))) then
				return true
			end

			if (myClass) then
				local classes = util.JSONToTable(classesRaw)
				if (table.HasValue(classes, myClass) or table.HasValue(classes, tostring(myClass))) then
					return true
				end
			end
		end
	end

	return false
end

function Schema:CanPlayerUseBusiness(client, uniqueID)
	if (!ix.config.Get("allowBusiness", true)) then
		return false
	end

	local character = IsValid(client) and client:GetCharacter()
	if (!character) then
		return false
	end

	-- Admin override (See everything everywhere)
	if (client:IsAdmin()) then
		return true
	end

	local myFaction = client:Team()
	local myClass = character:GetClass()

	-- 1. Identify context (Area cache or Proximity fallback)
	local currentArea = client:GetArea()
	local accessCache = (GetNetVar or (ix.net and ix.net.GetNetVar))("ixBusinessAccess", {})
	local info = nil

	if (currentArea and currentArea != "" and accessCache[currentArea]) then
		info = accessCache[currentArea]
	end

	if (!info) then
		for _, v in ipairs(ents.FindByClass("ix_businessarea")) do
			if (client:GetPos():DistToSqr(v:GetPos()) < 100000) then
				info = { factions = {}, classes = {} }
				local fRaw = v:GetFactions() or "[]"
				local cRaw = v:GetClasses() or "[]"
				
				for _, f in ipairs(util.JSONToTable(fRaw)) do 
					info.factions[tostring(f)] = true 
					info.factions[tonumber(f)] = true 
				end
				for _, c in ipairs(util.JSONToTable(cRaw)) do 
					info.classes[tostring(c)] = true 
					info.classes[tonumber(c)] = true 
				end
				break
			end
		end
	end

	if (!info) then
		return false
	end

	-- 2. Tab Visibility Check (uniqueID is nil)
	if (!uniqueID) then
		local bIsRestrictedShop = next(info.factions) or next(info.classes)
		if (!bIsRestrictedShop) then return true end

		-- Allow if player's faction matches OR player's class matches
		local sFaction = tostring(myFaction)
		local nFaction = tonumber(myFaction)
		local sClass = myClass and tostring(myClass)
		local nClass = myClass and tonumber(myClass)

		if (info.factions[sFaction] or (nFaction and info.factions[nFaction]) or
			(myClass and (info.classes[sClass] or (nClass and info.classes[nClass])))) then
			return true
		end

		return false
	end

	-- 3. Item-Specific Strict Filtering
	local itemTable = ix.item.list[uniqueID]
	if (!itemTable or itemTable.noBusiness) then
		return false
	end

	local itemFactions = itemTable.factions or itemTable.faction
	local itemClasses = itemTable.classes or itemTable.class

	-- Strict filtering: Items with no restrictions are hidden from restricted shops
	if (!itemFactions and !itemClasses and !itemTable.flag) then
		return false
	end

	-- Flag check
	if (itemTable.flag and !character:HasFlags(itemTable.flag)) then
		return false
	end

	-- Personal Requirement Check: Allowed if (No faction/class restrictions) OR (Matches faction) OR (Matches class)
	local bAllowed = true
	if (itemFactions or itemClasses) then
		bAllowed = false
		
		if (itemFactions) then
			local bFactionMatch = false
			if (istable(itemFactions)) then
				for _, f in pairs(itemFactions) do if (myFaction == f or tostring(myFaction) == tostring(f)) then bFactionMatch = true break end end
			else
				bFactionMatch = (myFaction == itemFactions or tostring(myFaction) == tostring(itemFactions))
			end
			if (bFactionMatch) then bAllowed = true end
		end

		if (!bAllowed and itemClasses) then
			local bClassMatch = false
			if (istable(itemClasses)) then
				for _, c in pairs(itemClasses) do if (myClass == c or tostring(myClass) == tostring(c)) then bClassMatch = true break end end
			else
				bClassMatch = (myClass == itemClasses or tostring(myClass) == tostring(itemClasses))
			end
			if (bClassMatch) then bAllowed = true end
		end
	end

	if (!bAllowed) then return false end

	-- Shop Compatibility Check
	local bIsRestrictedShop = next(info.factions) or next(info.classes)
	if (bIsRestrictedShop) then
		local bShopServesItem = false

		-- A shop serves an item if:
		-- 1. The item's FACTION is explicitly allowed in the shop.
		if (itemFactions) then
			local factions = istable(itemFactions) and itemFactions or {itemFactions}
			for _, f in pairs(factions) do
				if (info.factions[tostring(f)] or (tonumber(f) and info.factions[tonumber(f)])) then
					bShopServesItem = true
					break
				end
			end
		end

		-- 2. The item's CLASS is explicitly allowed in the shop.
		if (!bShopServesItem and itemClasses) then
			local classes = istable(itemClasses) and itemClasses or {itemClasses}
			for _, c in pairs(classes) do
				if (info.classes[tostring(c)] or (tonumber(c) and info.classes[tonumber(c)])) then
					bShopServesItem = true
					break
				end
			end
		end

		-- 3. INHERITANCE: Shop is for a Faction, Item is for a Class within that Faction.
		if (!bShopServesItem and itemClasses) then
			local classes = istable(itemClasses) and itemClasses or {itemClasses}
			for _, c in pairs(classes) do
				local classInfo = ix.class.list[tonumber(c) or c]
				if (classInfo and (info.factions[tostring(classInfo.faction)] or (tonumber(classInfo.faction) and info.factions[tonumber(classInfo.faction)]))) then
					bShopServesItem = true
					break
				end
			end
		end

		-- 4. REVERSE INHERITANCE: Shop is for a Class, Item is for the Parent Faction of that Class.
		-- (e.g., A CWU-only shop should still show generic Citizen items).
		if (!bShopServesItem and itemFactions) then
			local factions = istable(itemFactions) and itemFactions or {itemFactions}
			for _, f in pairs(factions) do
				-- Check if any of the shop's allowed classes belong to this faction
				for classID, _ in pairs(info.classes) do
					local classInfo = ix.class.list[tonumber(classID) or classID]
					if (classInfo and (tostring(classInfo.faction) == tostring(f))) then
						bShopServesItem = true
						break
					end
				end
				if (bShopServesItem) then break end
			end
		end

		if (!bShopServesItem) then
			return false
		end
	end

	return true
end

-- called when the client wants to view the combine data for the given target
function Schema:CanPlayerViewData(client, target)
	if (ix.plugin.Get("interactive_computers")) then
		return false
	end

	return client:IsCombine() and (!target:IsCombine() and target:Team() != FACTION_ADMIN)
end

-- called when the client wants to edit the combine data for the given target
function Schema:CanPlayerEditData(client, target)
	if (client:IsAdmin()) then
		return true
	end

	return client:IsCombine() and (!target:IsCombine() and target:Team() != (FACTION_ADMIN or -1))
end

function Schema:CanPlayerViewObjectives(client)
	if (ix.plugin.Get("interactive_computers")) then
		return false
	end

	return client:IsCombine()
end

function Schema:CanPlayerEditObjectives(client)
	if (!client:IsCombine() or !client:GetCharacter()) then
		return false
	end

	local bCanEdit = false
	local name = client:GetCharacter():GetName()

	for k, v in ipairs({"OfC", "EpU", "DvL", "SeC", "CmD"}) do
		if (self:IsCombineRank(name, v)) then
			bCanEdit = true
			break
		end
	end

	return bCanEdit
end

function Schema:CanDrive(client)
	return client:IsAdmin()
end

function Schema:AdjustStaminaOffset(client, offset)
	if (offset > 0) then -- Only buff regeneration
		if (client:Team() == FACTION_OTA) then
			return offset * 1.5
		end
	end
end

if (SERVER) then
	local ADMIN_SET_VALUE_MAX = 2000
	local ADMIN_RECOGNITION_SELF = 1
	local ADMIN_RECOGNITION_ALL = 2
	local ADMIN_UNRECOGNITION_ALL = 3

	util.AddNetworkString("ixAdminSetHealth")
	util.AddNetworkString("ixAdminSetArmor")
	util.AddNetworkString("ixAdminRecognitionAction")

	local function GetRecognitionState(character)
		local state = {}
		local raw = character:GetData("rgn", "")

		if (raw == "") then
			return state
		end

		for id in raw:gmatch(",(%d+),") do
			state[tonumber(id)] = true
		end

		return state
	end

	local function SetRecognitionState(character, state)
		local ids = {}

		for id, recognized in pairs(state) do
			if (recognized and isnumber(id) and id > 0) then
				ids[#ids + 1] = id
			end
		end

		table.sort(ids)

		if (#ids > 0) then
			character:SetData("rgn", "," .. table.concat(ids, ",") .. ",")
		else
			character:SetData("rgn", "")
		end
	end

	local function IsTargetFactionGloballyRecognized(target)
		local character = IsValid(target) and target:GetCharacter()
		local faction = character and ix.faction.indices[character:GetFaction()]

		return faction and faction.isGloballyRecognized
	end

	net.Receive("ixAdminSetHealth", function(_, client)
		if (!IsValid(client) or !client:IsAdmin()) then
			return
		end

		local target = net.ReadEntity()
		local value = net.ReadUInt(31)

		if (!IsValid(target) or !target:IsPlayer()) then
			return
		end

		value = math.floor(tonumber(value) or 0)

		if (value < 1) then
			return
		end

		value = math.min(value, ADMIN_SET_VALUE_MAX)
		target:SetHealth(value)
		client:EmitSound("buttons/button14.wav", 65, 100, 1)
	end)

	net.Receive("ixAdminSetArmor", function(_, client)
		if (!IsValid(client) or !client:IsAdmin()) then
			return
		end

		local target = net.ReadEntity()
		local value = net.ReadUInt(31)

		if (!IsValid(target) or !target:IsPlayer()) then
			return
		end

		value = math.floor(tonumber(value) or 0)

		if (value < 1) then
			return
		end

		value = math.min(value, ADMIN_SET_VALUE_MAX)
		target:SetArmor(value)
		client:EmitSound("buttons/button14.wav", 65, 100, 1)
	end)

	net.Receive("ixAdminRecognitionAction", function(_, client)
		if (!IsValid(client) or !client:IsAdmin()) then
			return
		end

		local target = net.ReadEntity()
		local action = net.ReadUInt(2)
		local targetCharacter = IsValid(target) and target:GetCharacter()
		local adminCharacter = client:GetCharacter()

		if (!IsValid(target) or !target:IsPlayer() or !targetCharacter or !adminCharacter) then
			return
		end

		if (IsTargetFactionGloballyRecognized(target)) then
			client:Notify("This target's faction is always recognized.")
			return
		end

		local targetID = targetCharacter:GetID()

		if (action == ADMIN_RECOGNITION_SELF) then
			if (adminCharacter:Recognize(targetID)) then
				client:Notify("You now recognize this player.")
			else
				client:Notify("You already recognize this player.")
			end

			return
		end

		local changed = 0

		for _, other in player.Iterator() do
			if (!IsValid(other) or other == target) then
				continue
			end

			local otherCharacter = other:GetCharacter()

			if (!otherCharacter) then
				continue
			end

			local state = GetRecognitionState(otherCharacter)

			if (action == ADMIN_RECOGNITION_ALL and !state[targetID]) then
				state[targetID] = true
				SetRecognitionState(otherCharacter, state)
				changed = changed + 1
			elseif (action == ADMIN_UNRECOGNITION_ALL and state[targetID]) then
				state[targetID] = nil
				SetRecognitionState(otherCharacter, state)
				changed = changed + 1
			end
		end

		if (action == ADMIN_RECOGNITION_ALL) then
			client:Notify(string.format("%s players now recognize the target.", changed))
		elseif (action == ADMIN_UNRECOGNITION_ALL) then
			client:Notify(string.format("%s players no longer recognize the target.", changed))
		end
	end)
end

if (CLIENT) then
	local MAX_POSITIVE_INT = 2000
	local ADMIN_RECOGNITION_SELF = 1
	local ADMIN_RECOGNITION_ALL = 2
	local ADMIN_UNRECOGNITION_ALL = 3

	local function OpenValueSlider(title, initialValue, callback)
		local frame = vgui.Create("DFrame")
		frame:SetTitle(title)
		frame:SetSize(420, 170)
		frame:Center()
		frame:MakePopup()

		local slider = frame:Add("DNumSlider")
		slider:Dock(TOP)
		slider:DockMargin(10, 10, 10, 0)
		slider:SetText("Value")
		slider:SetMin(1)
		slider:SetMax(MAX_POSITIVE_INT)
		slider:SetDecimals(0)
		slider:SetValue(math.Clamp(math.floor(tonumber(initialValue) or 1), 1, MAX_POSITIVE_INT))

		local entry = frame:Add("DTextEntry")
		entry:Dock(TOP)
		entry:DockMargin(10, 8, 10, 0)
		entry:SetNumeric(true)
		entry:SetValue(tostring(math.Clamp(math.floor(tonumber(initialValue) or 1), 1, MAX_POSITIVE_INT)))

		function entry:OnEnter()
			local value = math.floor(tonumber(self:GetValue()) or 0)

			if (value >= 1) then
				slider:SetValue(math.Clamp(value, 1, MAX_POSITIVE_INT))
			end
		end

		local buttonPanel = frame:Add("DPanel")
		buttonPanel:Dock(BOTTOM)
		buttonPanel:SetTall(40)
		buttonPanel.Paint = nil

		local confirm = buttonPanel:Add("DButton")
		confirm:Dock(LEFT)
		confirm:DockMargin(10, 6, 6, 6)
		confirm:SetWide(90)
		confirm:SetText("Apply")
		confirm.DoClick = function()
			local value = math.floor(tonumber(entry:GetValue()) or slider:GetValue() or 0)

			if (value < 1) then
				LocalPlayer():Notify("Please enter a positive integer (>= 1).")
				return
			end

			callback(math.Clamp(value, 1, MAX_POSITIVE_INT))
			frame:Close()
		end

		local cancel = buttonPanel:Add("DButton")
		cancel:Dock(RIGHT)
		cancel:DockMargin(6, 6, 10, 6)
		cancel:SetWide(90)
		cancel:SetText(L("cancel"))
		cancel.DoClick = function()
			frame:Close()
		end

		slider.OnValueChanged = function(_, value)
			value = math.Clamp(math.floor(value or 1), 1, MAX_POSITIVE_INT)
			entry:SetValue(tostring(value))
		end
	end

	function Schema:PopulateScoreboardPlayerMenu(target, menu)
		local client = LocalPlayer()
		local character = IsValid(target) and target:GetCharacter()
		local targetFaction = character and ix.faction.indices[character:GetFaction()]
		local targetIsAlwaysRecognized = targetFaction and targetFaction.isGloballyRecognized

		if (!IsValid(client) or !character) then
			return
		end

		if (client:IsAdmin()) then
			local healthMenu = menu:AddSubMenu(L("scoreboardSetHealth"))
			healthMenu:AddOption(L("scoreboardSetValue"), function()
				OpenValueSlider(L("scoreboardSetHealth"), target:Health(), function(value)
					net.Start("ixAdminSetHealth")
						net.WriteEntity(target)
						net.WriteUInt(value, 31)
					net.SendToServer()
				end)
			end)
			healthMenu:AddOption(L("scoreboardHealToMax"), function()
				local maxHealth = math.max(1, math.floor(target:GetMaxHealth() or 1))

				net.Start("ixAdminSetHealth")
					net.WriteEntity(target)
					net.WriteUInt(math.Clamp(maxHealth, 1, MAX_POSITIVE_INT), 31)
				net.SendToServer()
			end)

			local armorMenu = menu:AddSubMenu(L("scoreboardSetArmor"))
			armorMenu:AddOption(L("scoreboardSetValue"), function()
				OpenValueSlider(L("scoreboardSetArmor"), target:Armor(), function(value)
					net.Start("ixAdminSetArmor")
						net.WriteEntity(target)
						net.WriteUInt(value, 31)
					net.SendToServer()
				end)
			end)

			if (!targetIsAlwaysRecognized) then
				local recognitionMenu = menu:AddSubMenu(L("scoreboardRecognitionMenu"))

				recognitionMenu:AddOption(L("scoreboardRecognitionSelf"), function()
					net.Start("ixAdminRecognitionAction")
						net.WriteEntity(target)
						net.WriteUInt(ADMIN_RECOGNITION_SELF, 2)
					net.SendToServer()
				end)

				recognitionMenu:AddOption(L("scoreboardRecognitionAll"), function()
					net.Start("ixAdminRecognitionAction")
						net.WriteEntity(target)
						net.WriteUInt(ADMIN_RECOGNITION_ALL, 2)
					net.SendToServer()
				end)

				recognitionMenu:AddOption(L("scoreboardRecognitionClearAll"), function()
					net.Start("ixAdminRecognitionAction")
						net.WriteEntity(target)
						net.WriteUInt(ADMIN_UNRECOGNITION_ALL, 2)
					net.SendToServer()
				end)
			end

			if (!target:Alive()) then
				if (ix.command.HasAccess(client, "Revive")) then
					menu:AddOption(L("scoreboardRevive"), function()
						ix.command.Send("Revive", target:Name())
					end)
				end

				if (ix.command.HasAccess(client, "CharSpawn")) then
					menu:AddOption(L("scoreboardCharSpawn"), function()
						ix.command.Send("CharSpawn", target:Name())
					end)
				end
			end
		end

		local isSelf = (target == client)
		local canEditBodygroups = ix.command.HasAccess(client, "CharEditBodygroup") or (isSelf and character:HasFlags("b"))
		local canEditSkin = ix.command.HasAccess(client, "CharEditBodygroup") or (isSelf and character:HasFlags("s"))

		if ((canEditBodygroups or canEditSkin) and (#target:GetBodyGroups() > 1 or target:SkinCount() > 1)) then
			menu:AddOption(L("scoreboardEditBodygroups"), function()
				local panel = vgui.Create("ixBodygroupView")
				panel:Display(target)
			end)
		end

		if (ix.command.HasAccess(client, "CharSetName")) then
			menu:AddOption(L("cmdCharSetNameTitle"), function()
				Derma_StringRequest(L("cmdCharSetNameTitle"), L("cmdCharSetName"), character:GetName(), function(text)
					ix.command.Send("CharSetName", character:GetName(), text)
				end)
			end)
		end

		if (ix.command.HasAccess(client, "CharSetDesc")) then
			menu:AddOption(L("cmdCharDescTitle"), function()
				Derma_StringRequest(L("cmdCharDescTitle"), L("cmdCharDescDescription"), character:GetDescription(), function(text)
					ix.command.Send("CharSetDesc", character:GetName(), text)
				end)
			end)
		end
	end
end

function Schema:CanPlayerCreateCharacter(client, payload)
	if (IsValid(client) and istable(payload) and payload.faction) then
		client.ixPendingCharFaction = payload.faction
	end
end

function Schema:GetDefaultAttributePoints(client, payloadOrCount)
	local faction

	if (istable(payloadOrCount)) then
		faction = payloadOrCount.faction

		if (IsValid(client) and faction) then
			client.ixPendingCharFaction = faction
		end
	elseif (IsValid(client)) then
		faction = client.ixPendingCharFaction
	end

	local factionTable = faction and ix.faction.indices[faction]

	if (factionTable and factionTable.attPoints) then
		return factionTable.attPoints
	end
end

function Schema:CanProperty(client, property, entity)
	local class = IsValid(entity) and entity:GetClass()
	
	if (!client:IsAdmin() and class and property == "toggle_physgun") then
		return false
	end
end