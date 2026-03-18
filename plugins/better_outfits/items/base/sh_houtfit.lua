
if (SERVER) then
	util.AddNetworkString("ixBagDrop")
end

ITEM.name = "hOutfit"
ITEM.isBag = false
ITEM.invWidth = 2
ITEM.invHeight = 2
ITEM.description = "A Better Outfit Base."
ITEM.category = "Outfit"
ITEM.model = "models/Gibs/HGIBS.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.outfitCategory = "model"
ITEM.pacData = {}
ITEM.equipSound = {
	"interface/items/inv_items_cloth_1.ogg",
	"interface/items/inv_items_cloth_2.ogg",
	"interface/items/inv_items_cloth_3.ogg"
}
ITEM.unequipSound = {
	"interface/items/inv_items_cloth_1.ogg",
	"interface/items/inv_items_cloth_2.ogg",
	"interface/items/inv_items_cloth_3.ogg"
}

local function PlayRandomSound(client, sound)
	if (istable(sound)) then
		client:EmitSound(sound[math.random(1, #sound)])
	elseif (isstring(sound)) then
		client:EmitSound(sound)
	end
end

local function NormalizeModel(model)
	return isstring(model) and model:gsub("\\", "/"):lower() or ""
end

local modelBodygroupNameCache = {}
local function GetModelBodygroupName(model, index)
	model = model:lower():gsub("\\", "/")
	if (modelBodygroupNameCache[model] and modelBodygroupNameCache[model][index]) then
		return modelBodygroupNameCache[model][index]
	end

	modelBodygroupNameCache[model] = modelBodygroupNameCache[model] or {}

	local entity
	if (SERVER) then
		entity = ents.Create("prop_dynamic")
	else
		entity = ClientsideModel(model)
	end

	if (IsValid(entity)) then
		entity:SetModel(model)
		for i = 0, entity:GetNumBodyGroups() - 1 do
			modelBodygroupNameCache[model][i] = entity:GetBodygroupName(i)
		end
		entity:Remove()
	end

	return modelBodygroupNameCache[model] and modelBodygroupNameCache[model][index]
end

local function GetBadAirPlugin()
	return ix.plugin.Get("badair")
end

--[[
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
]]--

-- Inventory drawing
if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		if (item:GetData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end

		if (item.isBag) then
			local panel = ix.gui["inv" .. item:GetData("id", "")]

			if (!IsValid(panel)) then
				return
			end

			if (vgui.GetHoveredPanel() == self) then
				panel:SetHighlighted(true)
			else
				panel:SetHighlighted(false)
			end
		end
	end

	net.Receive("ixBagDrop", function()
		local index = net.ReadUInt(32)
		local panel = ix.gui["inv"..index]

		if (panel and panel:IsVisible()) then
			panel:Close()
		end
	end)

	function ITEM:PopulateAffiliationTooltip(tooltip, labelText, labelColor)
		labelText = labelText or self.tooltipLabelText

		if (!labelText) then
			return
		end

		labelColor = labelColor or self.tooltipLabelColor

		if (!labelColor and self.tooltipLabelFactionColor) then
			labelColor = team.GetColor(self.tooltipLabelFactionColor)
		end

		if (!labelColor) then
			return
		end

		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(labelColor)
		data:SetText(L(labelText))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end

	function ITEM:PopulateTooltip(tooltip)

		local badair = GetBadAirPlugin()

		if (badair and badair:ItemRequiresGasmaskFilter(self)) then
			local filterRow = tooltip:AddRow("filter")
			filterRow:SetBackgroundColor(Color(70, 70, 70, 180))
			filterRow:SetText(string.format("%s: %s", L("filterStatus"), badair:GetFilterTooltipText(self, LocalPlayer())))
			filterRow:SetExpensiveShadow(0.5)
			filterRow:SizeToContents()
		end
		
		self:PopulateAffiliationTooltip(tooltip)
		self:PopulateModelSupportTooltip(tooltip)
	end

	function ITEM:PopulateModelSupportTooltip(tooltip)
		if (self.allowedModels and !table.HasValue(self.allowedModels, LocalPlayer():GetModel())) then
			local warning = tooltip:AddRow("warning")
			warning:SetBackgroundColor(derma.GetColor("Error", tooltip))
			warning:SetText(L("modelNotSupported"))
			warning:SetFont("DermaDefault")
			warning:SetExpensiveShadow(1, color_black)
			warning:SizeToContents()
		end
	end
end



-- Helper to check if an item is compatible with a specific model string
function ITEM:IsCompatibleWith(model)
	if (!model or !self.allowedModels or #self.allowedModels == 0) then return true end

	local modelLower = model:lower():gsub("\\", "/"):Trim()
	for _, v in ipairs(self.allowedModels) do
		if (isstring(v) and v:lower():gsub("\\", "/"):Trim() == modelLower) then
			return true
		end
	end
	return false
end

-- Top Layer Definition (Items that replace the character model)
local function IsTopLayer(item)
	return (item.replacement != nil or item.replacements != nil or isfunction(item.OnGetReplacement))
end

local function GetAppearanceStack(character)
	return character:GetData("appearanceStack", {})
end

local function AddToAppearanceStack(character, itemID)
	local stack = GetAppearanceStack(character)
	for _, id in ipairs(stack) do
		if (id == itemID) then return end -- Already in stack, preserve position on loadout
	end
	table.insert(stack, itemID)
	character:SetData("appearanceStack", stack)
end

local function ForceTopOfAppearanceStack(character, itemID)
	local stack = GetAppearanceStack(character)
	for i, id in ipairs(stack) do
		if (id == itemID) then table.remove(stack, i) break end
	end
	table.insert(stack, itemID)
	character:SetData("appearanceStack", stack)
end

local function RemoveFromAppearanceStack(character, itemID)
	local stack = GetAppearanceStack(character)
	for i, id in ipairs(stack) do
		if (id == itemID) then table.remove(stack, i) break end
	end
	character:SetData("appearanceStack", stack)
end

function ITEM:RemoveOutfit(client)
	local character = client:GetCharacter()
	if (!character) then return end

	if (IsTopLayer(self)) then
		RemoveFromAppearanceStack(character, self.id)
	end

	local inventory = character:GetInventory()

	-- If we are removing a Top Layer (Uniform), revert the model and remove incompatible items in ALL character inventories
	if (IsTopLayer(self)) then
		local baseModel = character:GetData("oldModelBase", client:GetModel())
		local charID = character:GetID()

		for _, inv in pairs(ix.item.inventories) do
			if (inv.owner == charID) then
				for _, v in pairs(inv:GetItems()) do
					if (v.id != self.id and v:GetData("equip") and v.IsCompatibleWith and !v:IsCompatibleWith(baseModel)) then
						v:RemoveOutfit(client)
					end
				end
			end
		end
	end

	if (self.newSkin) then
		local oldSkin = character:GetData("oldSkin" .. self.outfitCategory)

		if (oldSkin) then
			character:SetData("skin", oldSkin)
			character:SetData("oldSkin" .. self.outfitCategory, nil)
		else
			character:SetData("skin", 0)
		end
	end

	self:SetData("equip", false)
	self:UpdateAppearance(client) -- Centralized resolver for appearance changes

	if (self.attribBoosts) then
		for k, _ in pairs(self.attribBoosts) do
			character:RemoveBoost(self.uniqueID, k)
		end
	end

	if (Schema and Schema.RefreshFlashlight) then
		Schema:RefreshFlashlight(client)
	end

	self:OnUnequipped()
end

function ITEM:UpdateAppearance(client)
	if (!IsValid(client)) then return end
	local character = client:GetCharacter()
	if (!character) then return end

	-- 1. Resolve Best Model (Dynamic Stack)
	local charID = character:GetID()
	local items = {}
	for _, inv in pairs(ix.item.inventories) do
		if (inv.owner == charID) then
			for _, v in pairs(inv:GetItems()) do
				table.insert(items, v)
			end
		end
	end

	local stack = GetAppearanceStack(character)
	local hasTopLayer = false
	local stackChanged = false

	-- Migration: Ensure all equipped top-layer items are present in the stack
	for _, item in pairs(items) do
		if (item:GetData("equip") and IsTopLayer(item)) then
			hasTopLayer = true
			local inStack = false
			for _, id in ipairs(stack) do
				if (id == item.id) then inStack = true break end
			end
			if (!inStack) then
				table.insert(stack, 1, item.id)
				stackChanged = true
			end
		end
	end

	if (stackChanged) then
		character:SetData("appearanceStack", stack)
	end

	local isTopLayerVisible = hasTopLayer

	local baseModel = character:GetData("oldModelBase", client:GetModel())
	if (!character:GetData("oldModelBase")) then
		character:SetData("oldModelBase", client:GetModel())
	end

	-- Chain model transformations in stack order (bottom → top).
	-- Each item's transformation is applied to the result of the layer below it,
	-- so e.g. a vest replacement runs on top of a conscript duty model instead of
	-- always reverting to the raw base citizen model.
	local targetModel = baseModel
	local topSkinItem = nil

	for _, stackID in ipairs(stack) do
		for _, item in pairs(items) do
			if (item.id == stackID and item:GetData("equip") and IsTopLayer(item)) then
				if (isfunction(item.OnGetReplacement)) then
					local resolved = item:OnGetReplacement()
					if (resolved) then targetModel = resolved end
				elseif (item.replacement) then
					targetModel = item.replacement
				elseif (item.replacements) then
					if (isstring(item.replacements)) then
						targetModel = item.replacements
					elseif (istable(item.replacements)) then
						if (#item.replacements == 2 and isstring(item.replacements[1])) then
							-- Simple pair: {"pattern", "replacement"}
							targetModel = targetModel:gsub(item.replacements[1], item.replacements[2])
						else
							-- Array of pairs: {{"pattern", "replacement"}, ...}
							for _, v in ipairs(item.replacements) do
								if (istable(v)) then
									targetModel = targetModel:gsub(v[1], v[2])
								end
							end
						end
					end
				end
				if (item.newSkin != nil) then
					topSkinItem = item
				end
				break
			end
		end
	end

	-- 2. Apply Model and Reset Bodygroups
	if (NormalizeModel(client:GetModel()) != NormalizeModel(targetModel)) then
		client:SetModel(targetModel)
		client:SetupHands()
	end

	for i = 0, client:GetNumBodyGroups() - 1 do
		client:SetBodygroup(i, 0)
	end

	-- 3. Apply Character Base Groups (Always try by name, safe for MPF facialhair)
	local baseGroups = character:GetData("groups", {})

	for k, v in pairs(baseGroups) do
		local index = -1
		local name = nil

		if (isnumber(k)) then
			-- Numbers: Only apply on base character model for safety, OR try to resolve name
			if (!isTopLayerVisible) then
				index = k
			elseif (baseModel) then
				name = GetModelBodygroupName(baseModel, k)
			end
		else
			name = k
		end

		if (name) then
			-- Names: ALWAYS try to apply ONLY if they are approved shared groups
			-- We allow 'facialhair' by default, and also check if it's in the faction's shared list
			local faction = ix.faction.Get(client:Team())
			local nameLower = name:lower()
			local isShared = (nameLower == "facialhair")

			if (faction and faction.bodyGroups) then
				local config = faction.bodyGroups[name] or faction.bodyGroups[nameLower]

				if (config and (config.shared or config.shared == nil)) then
					isShared = true
				end
			end

			-- The user explicitly requested string matches to apply across model changes
			if (isTopLayerVisible and !isShared) then
				continue
			end

			index = client:FindBodygroupByName(name)
		end

		if (index > -1) then
			client:SetBodygroup(index, tonumber(v) or 0)
		end
	end

	-- 4. Audit Items (Visibility & Stats)
	local currentModel = targetModel:lower():gsub("\\", "/")

	for _, item in pairs(items) do
		if (item:GetData("equip")) then
			-- 1. Hard Compatibility check: If item is definitely NOT for this model, hide it.
			-- Also allow items whose allowedModels match the base (pre-replacement) model,
			-- so that e.g. a vest whose allowedModels lists "novest" variants still applies
			-- its bodygroups after its own replacement has transformed the model path.
			-- NOTE: We also check IsTopLayer because if an item changed the model itself, 
			-- it should be allowed to apply its own bodygroups to the result.
			if (item.IsCompatibleWith and !item:IsCompatibleWith(currentModel) and !item:IsCompatibleWith(baseModel) and !IsTopLayer(item)) then
				continue
			end

			-- Apply bodygroups if compatible
			if (item.eqBodyGroups) then
				for bgName, bgValue in pairs(item.eqBodyGroups) do
					local index = client:FindBodygroupByName(bgName)
					if (index > -1) then
						client:SetBodygroup(index, bgValue)
					end
				end
			end
		end
	end

	-- 5. Skin handling
	local targetSkin = tonumber(character:GetData("skin", 0)) or 0
	if (topSkinItem and topSkinItem.newSkin != nil) then
		targetSkin = topSkinItem.newSkin
	end
	client:SetSkin(targetSkin)
end

-- makes another outfit depend on this outfit in terms of requiring this item to be equipped in order to equip the attachment
-- also unequips the attachment if this item is dropped
function ITEM:AddAttachment(id)
	local attachments = self:GetData("outfitAttachments", {})
	attachments[id] = true

	self:SetData("outfitAttachments", attachments)
end

function ITEM:RemoveAttachment(id, client)
	local item = ix.item.instances[id]
	local attachments = self:GetData("outfitAttachments", {})

	if (item and attachments[id]) then
		item:OnDetached(client)
	end

	attachments[id] = nil
	self:SetData("outfitAttachments", attachments)
end

ITEM:Hook("drop", function(item)
	if (item:GetData("equip")) then
		local client = item:GetOwner()

		if (IsValid(client)) then
			PlayRandomSound(client, item.unequipSound)
		end

		item:RemoveOutfit(client)
	end
end)

ITEM.functions.View = {
	icon = "icon16/briefcase.png",
	OnClick = function(item)
		local index = item:GetData("id", "")

		if (index) then
			local panel = ix.gui["inv"..index]
			local inventory = ix.item.inventories[index]
			local parent = IsValid(ix.gui.menuInventoryContainer) and ix.gui.menuInventoryContainer or ix.gui.openedStorage

			if (IsValid(panel)) then
				panel:Remove()
			end

			if (inventory and inventory.slots) then
				panel = vgui.Create("ixInventory", IsValid(parent) and parent or nil)
				panel:SetInventory(inventory)
				panel:ShowCloseButton(true)
				panel:SetTitle(item.GetName and item:GetName() or L(item.name))

				if (parent != ix.gui.menuInventoryContainer) then
					panel:Center()

					if (parent == ix.gui.openedStorage) then
						panel:MakePopup()
					end
				else
					panel:MoveToFront()
				end

				ix.gui["inv"..index] = panel
			else
				ErrorNoHalt("[Helix] Attempt to view an uninitialized inventory '"..index.."'\n")
			end
		end

		return false
	end,
	OnCanRun = function(item)
		return item.isBag and !IsValid(item.entity) and item:GetData("id") and !IsValid(ix.gui["inv" .. item:GetData("id", "")])
	end
}

ITEM.functions.EquipUn = { -- sorry, for name order.
	name = "Unequip",
	tip = "equipTip",
	icon = "icon16/cross.png",
	OnRun = function(item)
		local client = item.player

		if (IsValid(client)) then
			PlayRandomSound(client, item.unequipSound)
		end

		item:RemoveOutfit(item.player)
		return false
	end,
	OnCanRun = function(item)
		local client = item.player or item:GetOwner()
		if (CLIENT and !IsValid(client)) then client = LocalPlayer() end
		if (!IsValid(client)) then return false end

		local char = client:GetCharacter()
		if (!char) then return false end

		-- Hierarchical Locking Logic (Dynamic Stack):
		local charID = char:GetID()
		local items = {}
		for _, inv in pairs(ix.item.inventories) do
			if (inv.owner == charID) then
				for _, v in pairs(inv:GetItems()) do
					table.insert(items, v)
				end
			end
		end

		local stack = char:GetData("appearanceStack", {})
		local bestModelItem = nil
		local highestStackIndex = -1

		for _, v in pairs(items) do
			if (v:GetData("equip") and IsTopLayer(v)) then
				local stackIndex = -1
				for i, id in ipairs(stack) do if (id == v.id) then stackIndex = i break end end
				if (stackIndex > highestStackIndex) then
					highestStackIndex = stackIndex
					bestModelItem = v
				end
			end
		end

		if (bestModelItem and item.id != bestModelItem.id) then
			local currentModel = client:GetModel() or ""
			local isCompatible = (item.IsCompatibleWith and item:IsCompatibleWith(currentModel))

			-- 1. Hard Lock: Incompatibility
			if (!isCompatible) then
				if (SERVER) then client:NotifyLocalized("cannotUnequipUnderarmor") end
				return false
			end

			-- 2. Layer Lock: Last-In-First-Out for items without allowedModels
			local bHasAllowedModels = (item.allowedModels and #item.allowedModels > 0)
			if (IsTopLayer(item) and !bHasAllowedModels) then
				local itemIndex = -1
				for i, id in ipairs(stack) do if (id == item.id) then itemIndex = i break end end

				local isOverridden = false
				for i = itemIndex + 1, #stack do
					local higherID = stack[i]
					for _, v in pairs(items) do
						if (v.id == higherID and v:GetData("equip") and IsTopLayer(v)) then
							isOverridden = true
							break
						end
					end
					if (isOverridden) then break end
				end

				if (isOverridden) then
					if (SERVER) then client:NotifyLocalized("cannotUnequipUnderarmor") end
					return false
				end
			end
		end

		-- Standard Helix Checks + Hook
		return !IsValid(item.entity) and item:GetData("equip") == true and
			hook.Run("CanPlayerUnequipItem", client, item) != false and item:GetOwner() == client
	end
}

function ITEM:ApplyOutfit(client)
	client = client or self.player or self:GetOwner()
	if (!IsValid(client)) then return end

	local char = client:GetCharacter()
	local outfitPlugin = ix.plugin.Get("better_outfits")
	if (!char) then return end

	if (IsTopLayer(self)) then
		AddToAppearanceStack(char, self.id)
	end

	local model = client:GetModel()

	-- Reset all bodygroups first BEFORE changing model
	for i = 0, client:GetNumBodyGroups() - 1 do
		client:SetBodygroup(i, 0)
	end

	if (isfunction(self.OnGetReplacement)) then
		local replacement = self:OnGetReplacement()
		char:SetData("oldModel" .. self.outfitCategory, char:GetData("oldModel" .. self.outfitCategory, model))
		char:SetModel(replacement)
	elseif (self.replacement or self.replacements) then
		char:SetData("oldModel" .. self.outfitCategory, char:GetData("oldModel" .. self.outfitCategory, model))

		if (istable(self.replacements)) then
			if (#self.replacements == 2 and isstring(self.replacements[1])) then
				local newModel = model:gsub(self.replacements[1], self.replacements[2])
				char:SetModel(newModel)
			else
				local newModel = model
				for _, v in ipairs(self.replacements) do
					newModel = newModel:gsub(v[1], v[2])
				end
				char:SetModel(newModel)
			end
		else
			local newModel = self.replacement or self.replacements
			char:SetModel(newModel)
		end
	end

	-- Reset all bodygroups AGAIN after changing model to clear Source Engine carry-over bugs
	for i = 0, client:GetNumBodyGroups() - 1 do
		client:SetBodygroup(i, 0)
	end

	if (self.newSkin) then
		if (!char:GetData("oldSkin" .. self.outfitCategory)) then
			char:SetData("oldSkin" .. self.outfitCategory, client:GetSkin())
		end

		char:SetData("skin", self.newSkin)
		client:SetSkin(self.newSkin)
	end

	-- Re-apply all appearance layers (Independent logic)
	self:UpdateAppearance(client)

	if (self.attribBoosts) then
		for k, v in pairs(self.attribBoosts) do
			char:AddBoost(self.uniqueID, k, v)
		end
	end

	if (outfitPlugin) then
		outfitPlugin:ApplyTemporaryOutfitOverrides(client, char)
	end

	if (Schema and Schema.RefreshFlashlight) then
		Schema:RefreshFlashlight(client)
	end

	self:OnEquipped()
end

ITEM.functions.Equip = {
	name = "Equip",
	tip = "equipTip",
	icon = "icon16/tick.png",
	OnRun = function(item)
		local client = item.player
		local char = client:GetCharacter()
		local items = char:GetInventory():GetItems()

		for _, v in pairs(items) do
			if (v.id != item.id and v:GetData("equip") and v.outfitCategory == item.outfitCategory) then
				-- Allow equipping over a same-category bodygroup-only item that is dormant:
				-- a non-model-replacing item whose allowedModels no longer matches the current
				-- rendered model (e.g. a citizen head-scarf under a conscript suit).
				local vIsModelChanger = (v.replacement != nil or v.replacements != nil or isfunction(v.OnGetReplacement))
				if (!vIsModelChanger and v.IsCompatibleWith) then
					local currentModel = client:GetModel():lower():gsub("\\", "/")
					if (!v:IsCompatibleWith(currentModel)) then
						continue -- dormant on this model, allow the new item
					end
				end

				client:NotifyLocalized(item.equippedNotify or "outfitAlreadyEquipped")
				return false
			end
		end

		PlayRandomSound(client, item.equipSound)
		item:SetData("equip", true)
		item:ApplyOutfit(client)

		if (IsTopLayer(item)) then
			local equipChar = client:GetCharacter()
			if (equipChar) then
				ForceTopOfAppearanceStack(equipChar, item.id)
				item:UpdateAppearance(client)
			end
		end

		return false
	end,
	OnCanRun = function(item)
		local client = item.player or item:GetOwner()
		if (!IsValid(client)) then return false end

		if (item.allowedModels and !table.HasValue(item.allowedModels, client:GetModel())) then
			return false
		end

		local char = client:GetCharacter()
		return !IsValid(item.entity) and item:GetData("equip") != true and item:CanEquipOutfit() and
			hook.Run("CanPlayerEquipItem", client, item) != false and item:GetOwner() == client
	end
}

ITEM.functions.InstallFilter = {
	name = "installFilter",
	tip = "useTip",
	icon = "icon16/add.png",
	OnRun = function(item)
		local client = item.player or item:GetOwner()
		if (!IsValid(client)) then return false end

		local badair = GetBadAirPlugin()
		if (!badair or !badair:ItemRequiresGasmaskFilter(item)) then
			return false
		end

		if (badair:HasItemFilterInstalled(item)) then
			client:NotifyLocalized("filterAlreadyInstalled")
			return false
		end

		local character = client:GetCharacter()
		local filterItem = nil

		-- Search all inventories associated with the character
		for _, inv in pairs(ix.item.inventories) do
			if (inv.owner == character:GetID()) then
				filterItem = badair:GetFirstAvailableFilterItem(inv)
				if (filterItem) then break end
			end
		end

		if (!filterItem) then
			client:NotifyLocalized("filterNoCompatibleMask")
			return false
		end

		if (!badair:InstallFilterOnItem(item, filterItem)) then
			client:NotifyLocalized("filterAlreadyInstalled")
			return false
		end

		filterItem:Remove()

		client:EmitSound("weapons/usp/usp_silencer_on.wav")
		client:NotifyLocalized("filterInstalledNotify")

		return false
	end,
	OnCanRun = function(item)
		local client = item.player or item:GetOwner()
		if (!IsValid(client)) then return false end

		local badair = GetBadAirPlugin()
		if (!badair or !badair:ItemRequiresGasmaskFilter(item) or badair:HasItemFilterInstalled(item)) then
			return false
		end

		local char = client:GetCharacter()
		return !IsValid(item.entity) and item:GetOwner() == client
			and badair:GetFirstAvailableFilterItem(char:GetInventory()) != nil -- Simplified for basic canrun
	end
}

ITEM.functions.RemoveFilter = {
	name = "removeFilter",
	tip = "useTip",
	icon = "icon16/delete.png",
	OnRun = function(item)
		local client = item.player or item:GetOwner()
		if (!IsValid(client)) then return false end

		local badair = GetBadAirPlugin()

		if (!badair or !badair:ItemRequiresGasmaskFilter(item) or !badair:HasItemFilterInstalled(item)) then
			client:NotifyLocalized("filterNotInstalled")
			return false
		end

		local inventory = client:GetCharacter():GetInventory()
		badair:RemoveFilterFromItem(item, inventory, client)

		client:EmitSound("weapons/usp/usp_silencer_off.wav")
		client:NotifyLocalized("filterRemovedNotify")

		return false
	end,
	OnCanRun = function(item)
		local client = item.player or item:GetOwner()
		if (!IsValid(client)) then return false end

		local badair = GetBadAirPlugin()
		local char = client:GetCharacter()
		return !IsValid(item.entity) and item:GetOwner() == client
			and badair and badair:ItemRequiresGasmaskFilter(item) and badair:HasItemFilterInstalled(item)
	end
}

function ITEM:CanTransfer(oldInventory, newInventory)
	if (self:GetData("equip")) then
		return false
	end

	if (self.isBag) then
		if (newInventory) then
			if (newInventory.vars and newInventory.vars.isBag) then
				return false
			end

			local index = self:GetData("id")
			local index2 = newInventory:GetID()

			if (index == index2) then
				return false
			end

			local myInv = self:GetInventory()
			if (myInv) then
				for _, v in pairs(myInv:GetItems()) do
					if (v:GetData("id") == index2) then
						return false
					end
				end
			end
		end
	end

	return true
end

function ITEM:OnRemoved()
	if (self.invID != 0 and self:GetData("equip")) then
		self.player = self:GetOwner()
        if (self.player) then
		    self:RemoveOutfit(self.player)
        end
		self.player = nil
	end

	if (self.isBag) then
		local index = self:GetData("id")

		if (index) then
			local query = mysql:Delete("ix_items")
				query:Where("inventory_id", index)
			query:Execute()

			query = mysql:Delete("ix_inventories")
				query:Where("inventory_id", index)
			query:Execute()
		end
	end
end

function ITEM:OnEquipped()
	hook.Run("OnItemEquipped", self, self:GetOwner())
end

function ITEM:OnUnequipped()
	hook.Run("OnItemUnequipped", self, self:GetOwner())
end

function ITEM:OnLoadout()
	if (self:GetData("equip")) then
		self:ApplyOutfit(self.player or self:GetOwner())
	end
end

function ITEM:CanEquipOutfit()
	return true
end

-- Bag Functionality
function ITEM:OnInstanced(invID, x, y)
	if (self.isBag) then
		local inventory = ix.item.inventories[invID]

		ix.inventory.New(inventory and inventory.owner or 0, self.uniqueID, function(inv)
			local client = inv:GetOwner()

			inv.vars.isBag = self.uniqueID
			self:SetData("id", inv:GetID())

			if (IsValid(client)) then
				inv:AddReceiver(client)
			end
		end)
	end
end

function ITEM:GetInventory()
	if (self.isBag) then
		local index = self:GetData("id")

		if (index) then
			return ix.item.inventories[index]
		end
	end
end
ITEM.GetInv = ITEM.GetInventory

function ITEM:OnSendData()
	if (self.isBag) then
		local index = self:GetData("id")

		if (index) then
			local inventory = ix.item.inventories[index]

			if (inventory) then
				inventory.vars.isBag = self.uniqueID
				inventory:Sync(self.player)
				inventory:AddReceiver(self.player)
			else
				local owner = self.player:GetCharacter():GetID()

				ix.item.RestoreInv(self:GetData("id"), self.invWidth, self.invHeight, function(inv)
					inv.vars.isBag = self.uniqueID
					inv:SetOwner(owner, true)

					if (!inv.owner) then
						return
					end

					for client, character in ix.util.GetCharacters() do
						if (character:GetID() == inv.owner) then
							inv:AddReceiver(client)
							break
						end
					end
				end)
			end
		else
			ix.inventory.New(self.player:GetCharacter():GetID(), self.uniqueID, function(inv)
				self:SetData("id", inv:GetID())
			end)
		end
	end
end

function ITEM:OnTransferred(curInv, inventory)
	if (self.isBag) then
		local bagInventory = self:GetInventory()
		if (bagInventory) then
			if (isfunction(curInv.GetOwner)) then
				local owner = curInv:GetOwner()
				if (IsValid(owner)) then
					bagInventory:RemoveReceiver(owner)
				end
			end

			if (isfunction(inventory.GetOwner)) then
				local owner = inventory:GetOwner()
				if (IsValid(owner)) then
					bagInventory:AddReceiver(owner)
					bagInventory:SetOwner(owner)
				end
			else
				bagInventory:SetOwner(nil)
			end
		end
	end
end

function ITEM:OnRegistered()
	if (self.isBag) then
		ix.inventory.Register(self.uniqueID, self.invWidth, self.invHeight, true)
	end
end

ITEM.postHooks = ITEM.postHooks or {}
ITEM.postHooks.drop = function(item, result)
	if (item.isBag) then
		local index = item:GetData("id")

		local query = mysql:Update("ix_inventories")
			query:Update("character_id", 0)
			query:Where("inventory_id", index)
		query:Execute()

		net.Start("ixBagDrop")
			net.WriteUInt(index, 32)
		net.Send(item.player)
	end
end
