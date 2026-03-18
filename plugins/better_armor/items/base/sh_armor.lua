if (SERVER) then
	util.AddNetworkString("ixBagDrop")
end

ITEM.name = "Armor"
ITEM.isBag = false
ITEM.invWidth = 2
ITEM.invHeight = 2
ITEM.description = "An Armor Base."
ITEM.category = "Outfit"
ITEM.model = "models/props_c17/SuitCase_Passenger_Physics.mdl"
ITEM.width = 1
ITEM.armorAmount = 1
ITEM.resiAmount = 1
ITEM.height = 1
ITEM.outfitCategory = "model"
ITEM.gasmask = false
ITEM.resistance = false
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

local function GetBadAirPlugin()
	return ix.plugin.Get("badair")
end

ITEM.damage = {1, 1, 1, 1, 1, 1, 1}
ITEM.maxDurability = 100
ITEM.intAttr = 1

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

function ITEM:GetDescription()
	if (self.entity) then
		return (L(self.description) .. L("durabilityDesc") .. math.floor(self:GetData("Durability", self.maxDurability)).. " / ".. self.maxDurability)
	else
		return (L(self.description) .. L("durabilityDesc") .. math.floor(self:GetData("Durability", self.maxDurability)) .. " / ".. self.maxDurability .. L("bulletproof") .. (self.damage[1]) .. L("stabProof") .. (self.damage[2]) .. L("electricResistance") .. (self.damage[3]) .. L("fireResistance") .. (self.damage[4]) .. L("radiationResistance") .. (self.damage[5]) .. L("poisonResistance") .. (self.damage[6]) .. L("shockResistance") .. (self.damage[7]))
	end
end


local function armorPlayer(client, target, amount)
	hook.Run("OnPlayerArmor", client, target, amount)

	if (client:Alive() and target:Alive()) then
		target:SetArmor(amount)
	end
end
-- Inventory drawing
if (CLIENT) then
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

	function ITEM:PopulateTooltip(tooltip)
		self:PopulateModelSupportTooltip(tooltip)
		self:PopulateAffiliationTooltip(tooltip)

		local badair = GetBadAirPlugin()

		if (badair and badair:ItemRequiresGasmaskFilter(self)) then
			local filterRow = tooltip:AddRow("filter")
			filterRow:SetBackgroundColor(Color(70, 70, 70, 180))
			filterRow:SetText(string.format("%s: %s", L("filterStatus"), badair:GetFilterTooltipText(self, LocalPlayer())))
			filterRow:SetExpensiveShadow(0.5)
			filterRow:SizeToContents()
		end
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

-- Top Layer Definition
local function IsTopLayer(item)
	return (item.replacement != nil or item.replacements != nil or isfunction(item.OnGetReplacement))
end

local function GetAppearanceStack(character)
	return character:GetData("appearanceStack", {})
end

local function AddToAppearanceStack(character, itemID)
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

	client:SetNetVar("gasmask", false)
	armorPlayer(client, client, 0)

	self:SetData("equip", false)
	self:UpdateAppearance(client) -- Centralized resolver for appearance changes

	if (self.attribBoosts) then
		for k, _ in pairs(self.attribBoosts) do
			character:RemoveBoost(self.uniqueID, k)
		end
	end

	for k, _ in pairs(self:GetData("outfitAttachments", {})) do
		self:RemoveAttachment(k, client)
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

	-- 1. Resolve Best Model (Priority: suit > torso > base)
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
	local bestModelItem = nil
	local highestStackIndex = -1
	local stackChanged = false

	for _, item in pairs(items) do
		if (item:GetData("equip") and IsTopLayer(item)) then
			local stackIndex = -1
			for i, id in ipairs(stack) do
				if (id == item.id) then
					stackIndex = i
					break
				end
			end
			
			-- Migration: If equipped but not in stack, add to bottom
			if (stackIndex == -1) then
				table.insert(stack, 1, item.id)
				stackIndex = 1
				stackChanged = true
			end

			if (stackIndex > highestStackIndex) then
				highestStackIndex = stackIndex
				bestModelItem = item
			end
		end
	end

	if (stackChanged) then
		character:SetData("appearanceStack", stack)
	end

	local baseModel = character:GetData("oldModelBase", client:GetModel())
	if (!character:GetData("oldModelBase")) then
		character:SetData("oldModelBase", client:GetModel())
	end

	local targetModel = baseModel
	if (bestModelItem) then
		if (isfunction(bestModelItem.OnGetReplacement)) then
			targetModel = bestModelItem:OnGetReplacement()
		elseif (bestModelItem.replacement or bestModelItem.replacements) then
			targetModel = bestModelItem.replacement or bestModelItem.replacements
			if (istable(targetModel)) then
				-- Handle string replacements if table
				local result = baseModel
				for _, v in ipairs(targetModel) do
					if (istable(v)) then
						result = result:gsub(v[1], v[2])
					end
				end
				targetModel = result
			end
		end
	end

	-- 2. Apply Model and Reset Bodygroups
	client:SetModel(targetModel)
	for i = 0, client:GetNumBodyGroups() - 1 do
		client:SetBodygroup(i, 0)
	end

	-- 3. Audit Items (Visibility & Stats)
	local currentModel = targetModel:lower():gsub("\\", "/")
	
	for _, item in pairs(items) do
		if (item:GetData("equip")) then
			-- 1. Hard Compatibility check: If item is definitely NOT for this model, hide it.
			if (item.IsCompatibleWith and !item:IsCompatibleWith(currentModel)) then
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

	-- 4. Apply Character Base Groups (Always try by name, safe for MPF facialhair)
	local baseGroups = character:GetData("groups", {})
	local isSuitVisible = (bestModelItem != nil)

	for k, v in pairs(baseGroups) do
		local index = -1
		if (isnumber(k)) then
			-- Numbers: Only apply on base character model for safety
			if (!isSuitVisible) then index = k end 
		else
			-- Names: ALWAYS try to apply (MPF with facialhair will work, Hazmat will safely return -1)
			index = client:FindBodygroupByName(k)
		end

		if (index > -1) then
			client:SetBodygroup(index, tonumber(v) or 0)
		end
	end

	-- 5. Skin handling
	local targetSkin = tonumber(character:GetData("skin", 0)) or 0
	if (bestModelItem and bestModelItem.newSkin) then
		targetSkin = bestModelItem.newSkin
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
    
    self:UpdateResistance(client)
end

function ITEM:UpdateResistance(client)
	client = client or self.player or self:GetOwner()
	if (!IsValid(client)) then return end

	local char = client:GetCharacter()
	if (!char) then return end
	local items = char:GetInventory():GetItems()
	
	local bestDamage = {1, 1, 1, 1, 1, 1, 1}
	local anyResistance = false
	local anyGasmask = false
	
	for _, item in pairs(items) do
		if (item:GetData("equip") and item.base == "base_armor") then
			if (item.gasmask) then anyGasmask = true end
			
			if (item.resistance) then
				anyResistance = true
				
				local durability = item:GetData("Durability", item.maxDurability)
				local fraction = 1
		
				if (durability <= 0) then
					fraction = 0.5
				end
		
				local function GetEffectiveScale(base, frac)
					return base * frac + (1 - frac)
				end
				
				local dmg = item.damage or {1,1,1,1,1,1,1}
				
				for i = 1, 7 do
					local val = GetEffectiveScale(dmg[i], fraction)
					if (val < bestDamage[i]) then
						bestDamage[i] = val
					end
				end
			end
		end
	end

	if (anyResistance) then
		client:SetNetVar("resistance", true)
		client:SetNWFloat("dmg_bullet", bestDamage[1])
		client:SetNWFloat("dmg_slash", bestDamage[2])
		client:SetNWFloat("dmg_shock", bestDamage[3])
		client:SetNWFloat("dmg_burn", bestDamage[4])
		client:SetNWFloat("dmg_radiation", bestDamage[5])
		client:SetNWFloat("dmg_acid", bestDamage[6])
		client:SetNWFloat("dmg_explosive", bestDamage[7])
	else
		client:SetNetVar("resistance", false)
	end
	
	-- also update gasmask state to be safe (though usually handled by Equip/Unequip logic, checking all items is safer)
	-- Note: RemoveOutfit sets gasmask false blindly, so this restores it if other mask is present.
	if (anyGasmask) then
		client:SetNetVar("gasmask", true)
	else
		client:SetNetVar("gasmask", false)
	end
end

function ITEM:OnInstanced(client)
	self:SetData("Durability", self.maxDurability)
end

ITEM:Hook("drop", function(item)
	local client = item:GetOwner()
	if (item:GetData("equip")) then
		if (IsValid(client)) then
			PlayRandomSound(client, item.unequipSound)
		end

		item:RemoveOutfit(client)
		armorPlayer(client, client, 0)
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
	name = "unequip",
	tip = "equipTip",
	icon = "icon16/cross.png",
	OnRun = function(item)
		local client = item.player
		
		if (IsValid(client)) then
			PlayRandomSound(client, item.unequipSound)
		end

		armorPlayer(item.player, item.player, 0)
		
		item:RemoveOutfit(item.player)
		
		client:SetNetVar("gasmask", false)
		client:SetNetVar("resistance", false)
		
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
		local invID = char:GetInventory():GetID()
		return !IsValid(item.entity) and item:GetData("equip") != false and
			hook.Run("CanPlayerUnequipItem", client, item) != false and item.invID == invID
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

	self:SetData("equip", true)
	self:UpdateAppearance(client)

	local armorAmount = self.armorAmount
	if (self:GetData("Durability", self.maxDurability) <= 0) then
		armorAmount = armorAmount * 0.5
	end
	armorPlayer(client, client, armorAmount)

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

	if (self.UpdateResistance) then
		self:UpdateResistance(client)
	end

	self:OnEquipped()
end

ITEM.functions.Equip = {
	name = "equip",
	tip = "equipTip",
	icon = "icon16/tick.png",
	OnRun = function(item)
			local client = item.player
			local char = client:GetCharacter()
			local items = char:GetInventory():GetItems()

			for _, v in pairs(items) do
				if (v.id != item.id and v:GetData("equip") and v.outfitCategory == item.outfitCategory) then
					client:NotifyLocalized(item.equippedNotify or "outfitAlreadyEquipped")
					return false
				end
			end
			
			item:SetData("equip", true)
			PlayRandomSound(client, item.equipSound)
			item:ApplyOutfit(client)

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

ITEM.functions.Repair = {
	icon = "icon16/bullet_wrench.png",
	OnRun = function(item)
		local client = item.player
		local character = client:GetCharacter()
		local inventory = character:GetInventory()
		local items = inventory:GetItems()
		local number = 0
		local repairSounds = {"interface/inv_repair_kit.ogg", "interface/inv_repair_kit_with_brushes.ogg"}
		local randomsound = table.Random(repairSounds)
		local int = character:GetAttribute("int", 0)
		
		if int >= item.intAttr then
			for k, v in pairs(items) do
				if (v.uniqueID == "repair_tools") then
					item:SetData("Durability", math.min(item:GetData("Durability") + item:GetRepairAmount(client), item.maxDurability))
					item:UpdateResistance(client)
					character:SetAttrib("int", math.Clamp(int + 0.2, 0, ix.config.Get("maxAttributes", 100)))
					client:EmitSound(randomsound)
					v:Remove()
					
					break
				end
			end
		else
			client:NotifyLocalized("lackKnowledge")
			return false
		end
		
		return false
	end,
	OnCanRun = function(item)
		local client = item.player or item:GetOwner()
		if (CLIENT and !IsValid(client)) then client = LocalPlayer() end
		if (!IsValid(client)) then return false end
		
		return !IsValid(item.entity) and item:GetData("Durability") < item.maxDurability and item:GetOwner() == client
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

		if (item.UpdateResistance) then
			item:UpdateResistance(client)
		end

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
			and badair:GetFirstAvailableFilterItem(char:GetInventory()) != nil -- Simplified check
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

		if (item.UpdateResistance) then
			item:UpdateResistance(client)
		end

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
		
function ITEM:GetRepairAmount(client)
	local character = client:GetCharacter()
	local int = character:GetAttribute("int", 0)
	local maxAttr = ix.config.Get("maxAttributes", 100)

	if (int < maxAttr * 0.2) then
		return self.maxDurability * 0.2
	elseif (int < maxAttr * 0.4) then
		return self.maxDurability * 0.4
	elseif (int < maxAttr * 0.6) then
		return self.maxDurability * 0.6
	elseif (int < maxAttr * 0.8) then
		return self.maxDurability * 0.8
	else
		return self.maxDurability * 1
	end
end
		
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
