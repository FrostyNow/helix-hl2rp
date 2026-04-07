local PLUGIN = PLUGIN
PLUGIN.name = "Bad Air"
PLUGIN.author = "Black Tea and Subleader"
PLUGIN.desc = "Remastered Bad Air"

ix.lang.AddTable("korean", {
	toxicity = "오염도",
	toxicityLow = "약간 거친 호흡",
	toxicityMedium = "거친 호흡과 비틀거림",
	toxicityHigh = "숨을 제대로 못 쉬고, 심하게 비틀거림",
	badairEnter1 = "갑자기 숨 쉬기가 답답하고 쓰라린 듯 따갑습니다.",
	badairEnter2 = "뭔가 매캐한 냄새가 나는 것 같습니다.",
	badairEnter3 = "공기 중에 무거운 입자가 깔리는 듯한 느낌이 듭니다.",
	badairExit1 = "숨 쉬기가 한결 편안해졌습니다.",
	badairExit2 = "불쾌한 냄새가 사라지는 것 같습니다.",
	badairExit3 = "뭔가 상쾌해진 것 같습니다.",
	badairMaskDepleted = "방독면의 정화통이 다 되어 숨이 막혀옵니다.",
	filterInstalled = "정화통 장착됨",
	filterMissing = "정화통 없음",
	filterDepleted = "정화통 소진",
	filterStatus = "정화통 상태",
	filterInstalledNotify = "정화통을 장착했습니다.",
	filterRemovedNotify = "정화통을 분리했습니다.",
	filterAlreadyInstalled = "이미 정화통이 장착되어 있습니다.",
	filterNotInstalled = "장착된 정화통이 없습니다.",
	filterNoCompatibleMask = "정화통을 장착할 수 있는 방독면이 없습니다.",
	installFilter = "정화통 장착",
	removeFilter = "정화통 분리"
})

ix.lang.AddTable("english", {
	toxicity = "Toxicity",
	toxicityLow = "Slightly heavy breathing",
	toxicityMedium = "Heavy breathing and staggering",
	toxicityHigh = "Cannot breathe properly and severe staggering",
	badairEnter1 = "It suddenly feels stuffy and your breathing stings.",
	badairEnter2 = "It smells as if there's something acrid here.",
	badairEnter3 = "It feels as though heavy particles are settling in the air.",
	badairExit1 = "Breathing has become much easier.",
	badairExit2 = "The unpleasant smell seems to have disappeared.",
	badairExit3 = "It feels somehow refreshing.",
	badairMaskDepleted = "The filter in your gasmask runs out, making it hard to breathe.",
	filterInstalled = "Filter installed",
	filterMissing = "No filter installed",
	filterDepleted = "Filter depleted",
	filterStatus = "Filter status",
	filterInstalledNotify = "You installed the filter.",
	filterRemovedNotify = "You removed the filter.",
	filterAlreadyInstalled = "This mask already has a filter installed.",
	filterNotInstalled = "There is no installed filter to remove.",
	filterNoCompatibleMask = "You do not have a compatible mask for this filter.",
	installFilter = "Install Filter",
	removeFilter = "Remove Filter"
})

do
	ix.char.RegisterVar("toxicity", {
		field = "toxicity",
		fieldType = ix.type.float,
		default = 0,
		isLocal = false,
		bNoDisplay = true
	})
end

local badairEnterMessages = {
	"badairEnter1",
	"badairEnter2",
	"badairEnter3"
}

local badairExitMessages = {
	"badairExit1",
	"badairExit2",
	"badairExit3"
}

local DEFAULT_FILTER_MAX_DURABILITY = 100

function PLUGIN:ItemRequiresGasmaskFilter(item)
	return item and item.requiresGasmaskFilter == true
end

function PLUGIN:GetItemFilterMaxDurability(item)
	local maxDurability = item and tonumber(item.filterMaxDurability or item.maxFilterDurability) or nil

	if (!maxDurability or maxDurability <= 0) then
		maxDurability = DEFAULT_FILTER_MAX_DURABILITY
	end

	local filterID = item:GetData("FilterID")
	local filterTable = filterID and ix.item.list[filterID]
	if (filterTable and filterTable.maxDurability) then
		maxDurability = math.max(maxDurability, tonumber(filterTable.maxDurability) or 0)
	end

	return maxDurability
end

function PLUGIN:GetItemFilterDurability(item)
	if (!self:HasItemFilterInstalled(item)) then
		return 0
	end

	return math.max(0, tonumber(item:GetData("FilterDurability", self:GetItemFilterMaxDurability(item))) or 0)
end

function PLUGIN:SetItemFilterDurability(item, durability)
	if (!self:ItemRequiresGasmaskFilter(item)) then
		return 0
	end

	local maxDurability = self:GetItemFilterMaxDurability(item)
	local clamped = math.Clamp(tonumber(durability) or maxDurability, 0, maxDurability)

	item:SetData("FilterDurability", clamped)

	return clamped
end

function PLUGIN:HasItemFilterInstalled(item)
	if (!self:ItemRequiresGasmaskFilter(item)) then
		return false
	end

	return item:GetData("filterInstalled") == true
end

function PLUGIN:SetItemFilterInstalled(item, installed)
	if (!self:ItemRequiresGasmaskFilter(item)) then
		return false
	end

	installed = (installed == true)
	item:SetData("filterInstalled", installed)

	if (!installed) then
		item:SetData("FilterDurability", nil)
	end

	return installed
end

function PLUGIN:RestoreItemFilterDurability(item)
	self:SetItemFilterInstalled(item, true)
	return self:SetItemFilterDurability(item, self:GetItemFilterMaxDurability(item))
end

function PLUGIN:ConsumeItemFilterDurability(item, amount)
	if (!self:ItemRequiresGasmaskFilter(item)) then
		return 0, 0
	end

	local before = self:GetItemFilterDurability(item)
	local after = self:SetItemFilterDurability(item, before - math.max(tonumber(amount) or 0, 0))

	return before, after
end

function PLUGIN:GetFilterTooltipText(item, client)
	if (!self:ItemRequiresGasmaskFilter(item)) then
		return nil
	end

	if (!self:HasItemFilterInstalled(item)) then
		return L("filterMissing", client)
	end

	local durability = math.floor(self:GetItemFilterDurability(item))
	local maxDurability = self:GetItemFilterMaxDurability(item)

	if (durability <= 0) then
		return string.format("%s (0 / %d)", L("filterDepleted", client), maxDurability)
	end

	return string.format("%s (%d / %d)", L("filterInstalled", client), durability, maxDurability)
end

function PLUGIN:CharacterRequiresGasmaskFilter(character)
	return self:CanEquipInternalFilter(character:GetPlayer() or character:GetInventory().owner)
end

function PLUGIN:CanEquipInternalFilter(client)
	if (!IsValid(client)) then
		return false
	end

	local faction = client:Team()
	return faction == FACTION_OTA
end

function PLUGIN:GetFirstAvailableFilterItem(inventory)
	if (!inventory) then
		return nil
	end

	for _, filterItem in pairs(inventory:GetItems()) do
		if (filterItem.isGasmaskFilter == true and (tonumber(filterItem:GetData("Durability", filterItem.maxDurability or DEFAULT_FILTER_MAX_DURABILITY)) or 0) > 0) then
			return filterItem
		end
	end

	return nil
end

function PLUGIN:GetFilterInstallTarget(character)
	if (!character) then
		return nil
	end

	local charID = character:GetID()
	local fallback

	for _, inventory in pairs(ix.item.inventories) do
		if (inventory.owner == charID) then
			for _, item in pairs(inventory:GetItems()) do
				if (!self:ItemRequiresGasmaskFilter(item) or self:HasItemFilterInstalled(item)) then
					continue
				end

				if (item:GetData("equip")) then
					return item
				end

				fallback = fallback or item
			end
		end
	end

	return fallback
end

function PLUGIN:InstallFilterOnItem(item, filterItem)
	if (!self:ItemRequiresGasmaskFilter(item) or !filterItem or filterItem.isGasmaskFilter != true) then
		return false
	end

	if (self:HasItemFilterInstalled(item)) then
		return false
	end

	local filterMax = tonumber(filterItem.maxDurability) or self:GetItemFilterMaxDurability(item)
	local durability = math.Clamp(
		tonumber(filterItem:GetData("Durability", filterMax)) or filterMax,
		0,
		filterMax
	)

	if (durability <= 0) then
		return false
	end

	self:SetItemFilterInstalled(item, true)
	item:SetData("FilterID", filterItem.uniqueID)
	self:SetItemFilterDurability(item, durability)

	return true
end

function PLUGIN:RemoveFilterFromItem(item, inventory, client)
	if (!self:HasItemFilterInstalled(item)) then
		return false
	end

	local durability = self:GetItemFilterDurability(item)
	local filterID = item:GetData("FilterID", "gasmask_filter")
	
	self:SetItemFilterInstalled(item, false)
	item:SetData("FilterID", nil)

	local data = {
		Durability = durability
	}

	if (inventory and inventory.Add and inventory:Add(filterID, 1, data)) then
		return true
	end

	if (IsValid(client)) then
		ix.item.Spawn(filterID, client, nil, Angle(0, 0, 0), data)
		return true
	end

	return false
end

function PLUGIN:CanItemProtectFromBadAir(item)
	if (!item) then
		return false
	end

	if (self:ItemRequiresGasmaskFilter(item) and self:GetItemFilterDurability(item) <= 0) then
		return false
	end

	if (item.filterIgnoreItemDurability) then
		return true
	end

	local maxDurability = tonumber(item.maxDurability)

	if (maxDurability and maxDurability > 0 and item:GetData("Durability", maxDurability) <= 0) then
		return false
	end

	return true
end

function PLUGIN:GetEquippedBadAirProtectionItem(character, predicate)
	if (!character) then
		return nil
	end

	local charID = character:GetID()

	for _, inventory in pairs(ix.item.inventories) do
		if (inventory.owner == charID) then
			for _, item in pairs(inventory:GetItems()) do
				if (!item:GetData("equip") or !item.badAirProtection) then
					continue
				end

				if (!predicate or predicate(item)) then
					return item
				end
			end
		end
	end

	return nil
end

function PLUGIN:TryProtectWithBadAirItem(client, item)
	if (!IsValid(client) or !item) then
		return false
	end

	if (!item.filterIgnoreItemDurability) then
		local maxDurability = tonumber(item.maxDurability)

		if (maxDurability and maxDurability > 0 and item:GetData("Durability", maxDurability) <= 0) then
			return false
		end
	end

	if (self:ItemRequiresGasmaskFilter(item)) then
		local before, after = self:ConsumeItemFilterDurability(item, self:GetItemFilterMaxDurability(item) / 600)

		if (before > 0 and after <= 0) then
			ix.chat.Send(client, "it", L("badairMaskDepleted", client), false, {client})
		end
	elseif (item.isGasmaskFilter) then
		-- For items that are filters themselves (equipped by OTA)
		local before = tonumber(item:GetData("Durability", item.maxDurability or DEFAULT_FILTER_MAX_DURABILITY)) or 0
		local amount = (item.maxDurability or DEFAULT_FILTER_MAX_DURABILITY) / 600
		local after = math.max(0, before - amount)

		item:SetData("Durability", after)

		if (before > 0 and after <= 0) then
			ix.chat.Send(client, "it", L("badairMaskDepleted", client), false, {client})
		end
		
		if (after <= 0) then
			return false
		end
	end

	return self:CanItemProtectFromBadAir(item)
end

function PLUGIN:SetupAreaProperties()
	ix.area.AddProperty("badair", ix.type.bool, false)
end

if (!CLIENT) then
	-- This timer does the effect of bad air.
	timer.Create("badairTick", 1, 0, function()
		for _, client in ipairs(player.GetAll()) do
			local char = client:GetCharacter()

			if (client:Alive() and char) then
				local isInBadAirArea = false
				local toxicity = char:GetToxicity(0)

				if (client:IsInArea()) then
					local areaID = client:GetArea()

					if (areaID and areaID != "") then
						local areaMeta = ix.area.stored[areaID]

						if (areaMeta and areaMeta.properties and areaMeta.properties.badair) then
							isInBadAirArea = true
						end
					end
				end

				local bIsProtected = client:GetMoveType() == MOVETYPE_NOCLIP
				local bCombineProtected = false

				if (!bIsProtected and char.IsVortigaunt and char:IsVortigaunt()) then
					bIsProtected = true
				end

				-- Only check complex protection if they are in bad air or have high toxicity
				if (!bIsProtected and (isInBadAirArea or toxicity >= 20)) then
					if (client:IsCombine()) then
						if (Schema:IsConceptCombine(client)) then
							local index = client:FindBodygroupByName("mask")

							if (index != -1 and client:GetBodygroup(index) >= 1) then
								local combineMask = PLUGIN:GetEquippedBadAirProtectionItem(char, function(item)
									return item.combineMaskProtection == true
								end)

								if (combineMask) then
									if (isInBadAirArea) then
										bIsProtected = PLUGIN:TryProtectWithBadAirItem(client, combineMask)
									else
										bIsProtected = PLUGIN:CanItemProtectFromBadAir(combineMask)
									end
									bCombineProtected = true
								end
							end
						else
							local activeFilter = PLUGIN:GetEquippedBadAirProtectionItem(char, function(item)
								return item.isGasmaskFilter == true
							end)

							if (activeFilter) then
								if (isInBadAirArea) then
									bIsProtected = PLUGIN:TryProtectWithBadAirItem(client, activeFilter)
								else
									bIsProtected = PLUGIN:CanItemProtectFromBadAir(activeFilter)
								end
							elseif (PLUGIN:CharacterRequiresGasmaskFilter(char)) then
								bIsProtected = false
							else
								bIsProtected = true
							end
							bCombineProtected = true
						end
					end

					if (!bCombineProtected and client:GetNetVar("gasmask") and client:GetMoveType() != MOVETYPE_NOCLIP) then
						local activeMask = PLUGIN:GetEquippedBadAirProtectionItem(char, function(item)
							return item.gasmask == true
						end)

						if (activeMask) then
							if (isInBadAirArea) then
								bIsProtected = PLUGIN:TryProtectWithBadAirItem(client, activeMask)
							else
								bIsProtected = PLUGIN:CanItemProtectFromBadAir(activeMask)
							end
						end
					end
				end

				local isInGas = isInBadAirArea and !bIsProtected
				local wasInGas = client.ixInBadAir or false

				if (isInGas and !wasInGas) then
					client.ixInBadAir = true

					if ((client.ixNextBadAirEnterMessage or 0) < CurTime()) then
						local msg = table.Random(badairEnterMessages)
						ix.chat.Send(client, "it", L(msg, client), false, {client})

						client.ixNextBadAirEnterMessage = CurTime() + 5
					end
				elseif (!isInGas and wasInGas) then
					client.ixInBadAir = false

					if ((client.ixNextBadAirExitMessage or 0) < CurTime()) then
						local msg = table.Random(badairExitMessages)
						ix.chat.Send(client, "it", L(msg, client), false, {client})

						client.ixNextBadAirExitMessage = CurTime() + 5
					end
				end

				if (isInGas) then
					toxicity = math.Clamp(toxicity + 3, 0, 100)
					char:SetToxicity(toxicity)

					if (toxicity >= 100) then
						local dmg = math.max(1, client:GetMaxHealth() / 33)
						client:TakeDamage(dmg)
						client:ScreenFade(1, ColorAlpha(color_white, 150), .5, 0)
					end
				else
					if (toxicity > 0) then
						toxicity = math.Clamp(toxicity - 0.3, 0, 100)
						char:SetToxicity(toxicity)
					end
				end

				-- Cough logic: triggered by either being in gas or having high toxicity, provided not protected
				if (!bIsProtected and (isInGas or toxicity >= 20)) then
					if ((client.ixNextCough or 0) < CurTime()) then
						client.ixNextCough = CurTime() + math.Rand(3, 5)

						local pitch = client:IsFemale() and math.random(115, 125) or math.random(95, 105)
						client:EmitSound("ambient/voices/cough" .. math.random(1, 4) .. ".wav", 75, pitch)
						client:ViewPunch(Angle(math.Rand(-3, 3), math.Rand(-2, 2), math.Rand(-1, 1)))
					end
				end
			end
		end
	end)
else
	ix.bar.Add(function()
		local char = LocalPlayer():GetCharacter()
		return char and math.max(char:GetToxicity(0) / 100, 0) or 0
	end, Color(34, 139, 34), nil, "toxicity")

	function PLUGIN:PopulateCharacterInfo(player, character, tooltip)
		local row = tooltip:AddRow("toxicityStatus")
		row:SetBackgroundColor(Color(34, 139, 34))
		row:SetTextColor(color_white)
		row:SizeToContents()

		function row:Think()
			local toxicity = character:GetToxicity(0)
			local text = ""
			local bVisible = false

			if (toxicity >= 80) then
				text = L("toxicityHigh")
				bVisible = true
			elseif (toxicity >= 50) then
				text = L("toxicityMedium")
				bVisible = true
			elseif (toxicity >= 20) then
				text = L("toxicityLow")
				bVisible = true
			end

			if (self:GetText() != text) then
				self:SetText(text)
				self:SizeToContents()
			end

			if (self:IsVisible() != bVisible) then
				self:SetVisible(bVisible)
			end
		end
	end
end

ix.command.Add("AreaBadAir", {
	description = "@cmdAreaBadAir",
	adminOnly = true,
	OnRun = function(self, client, arguments)
		local areaID = client:GetArea()

		if (!client:IsInArea() or !areaID or areaID == "") then
			return "@areaBadAirReq"
		end

		local areaInfo = ix.area.stored[areaID]
		if (!areaInfo) then
			return "@areaBadAirInvalid"
		end

		areaInfo.properties.badair = not areaInfo.properties.badair

		-- Network the change to all clients
		net.Start("ixAreaAdd")
			net.WriteString(areaID)
			net.WriteString(areaInfo.type)
			net.WriteVector(areaInfo.startPosition)
			net.WriteVector(areaInfo.endPosition)
			net.WriteTable(areaInfo.properties)
		net.Broadcast()

		-- Save the area plugin data
		local areaPlugin = ix.plugin.list["area"]
		if (areaPlugin) then
			areaPlugin:SaveData()
		end

		if (areaInfo.properties.badair) then
			return "@areaBadAirEnabled", areaID
		else
			return "@areaBadAirDisabled", areaID
		end
	end
})
