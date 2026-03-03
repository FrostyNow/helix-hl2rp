ITEM.name = "Armor"
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
	function ITEM:PaintOver(item, w, h)
		if (item:GetData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end

	function ITEM:PopulateTooltip(tooltip)
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

function ITEM:RemoveOutfit(client)
	local character = client:GetCharacter()
			
	client:SetNetVar("gasmask", false)

	armorPlayer(client, client, 0)

	self:SetData("equip", false)
	if (character:GetData("oldModel" .. self.outfitCategory)) then
		character:SetModel(character:GetData("oldModel" .. self.outfitCategory))
		character:SetData("oldModel" .. self.outfitCategory, nil)
	end

	if (self.newSkin) then
		if (character:GetData("oldSkin" .. self.outfitCategory)) then
			client:SetSkin(character:GetData("oldSkin" .. self.outfitCategory))
			character:SetData("oldSkin" .. self.outfitCategory, nil)
		else
			client:SetSkin(0)
		end
	end

	for k, _ in pairs(self.eqBodyGroups or {}) do
		local index = client:FindBodygroupByName(k)

		if (index > -1) then
			client:SetBodygroup(index, 0)
		end
	end

	-- restore the original bodygroups
	if (character:GetData("oldGroups" .. self.outfitCategory)) then
		for k, v in pairs(character:GetData("oldGroups" .. self.outfitCategory, {})) do
			local index = isnumber(k) and k or client:FindBodygroupByName(k)

			if (index and index > -1) then
				client:SetBodygroup(index, tonumber(v) or 0)
			end
		end

		character:SetData("groups", character:GetData("oldGroups" .. self.outfitCategory, {}))
		character:SetData("oldGroups" .. self.outfitCategory, nil)
	end

	-- Re-apply bodygroups from other equipped items to handle intersections
	for _, item in pairs(character:GetInventory():GetItems()) do
		if (item.id != self.id and item:GetData("equip") and item.eqBodyGroups) then
			local bgs = item.eqBodyGroups
			for bgName, bgValue in pairs(bgs) do
				local index = client:FindBodygroupByName(bgName)
				if (index > -1) then
					client:SetBodygroup(index, bgValue)
					
					local currentGroups = character:GetData("groups", {})
					currentGroups[index] = bgValue
					character:SetData("groups", currentGroups)
				end
			end
		end
	end

	if (self.attribBoosts) then
		for k, _ in pairs(self.attribBoosts) do
			character:RemoveBoost(self.uniqueID, k)
		end
	end

	for k, _ in pairs(self:GetData("outfitAttachments", {})) do
		self:RemoveAttachment(k, client)
	end

	self:OnUnequipped()
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
		local client = item.player

		return !IsValid(item.entity) and IsValid(client) and item:GetData("equip") == true and
			hook.Run("CanPlayerUnequipItem", client, item) != false and item.invID == client:GetCharacter():GetInventory():GetID()
	end
}

function ITEM:ApplyOutfit(client)
	client = client or self.player or self:GetOwner()
	if (!IsValid(client)) then return end

	local char = client:GetCharacter()
	if (!char) then return end

	local model = client:GetModel()

	if (self.gasmask == true) then
		client:SetNetVar("gasmask", true)
	else
		client:SetNetVar("gasmask", false)
	end

	self:UpdateResistance(client)

	local armorAmount = self.armorAmount
	if (self:GetData("Durability", self.maxDurability) <= 0) then
		armorAmount = armorAmount * 0.5
	end
	armorPlayer(client, client, armorAmount)

	if (type(self.OnGetReplacement) == "function") then
		local replacement = self:OnGetReplacement()
		char:SetData("oldModel" .. self.outfitCategory, char:GetData("oldModel" .. self.outfitCategory, model))
		char:SetModel(replacement)
	elseif (self.replacement or self.replacements) then
		char:SetData("oldModel" .. self.outfitCategory, char:GetData("oldModel" .. self.outfitCategory, model))

		if (type(self.replacements) == "table") then
			if (#self.replacements == 2 and type(self.replacements[1]) == "string") then
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

	if (self.newSkin) then
		if (!char:GetData("oldSkin" .. self.outfitCategory)) then
			char:SetData("oldSkin" .. self.outfitCategory, client:GetSkin())
		end
		client:SetSkin(self.newSkin)
	end

	local groups = char:GetData("groups", {})

	if (!char:GetData("oldGroups" .. self.outfitCategory)) then
		local oldGroups = {}
		for i = 0, client:GetNumBodyGroups() - 1 do
			local name = client:GetBodygroupName(i)
			oldGroups[name] = client:GetBodygroup(i)
		end

		char:SetData("oldGroups" .. self.outfitCategory, oldGroups)
	end

	if (self.eqBodyGroups) then
		local outfitGroups = {}

		for k, value in pairs(self.eqBodyGroups) do
			local index = client:FindBodygroupByName(k)

			if (index > -1) then
				outfitGroups[index] = value
			end
		end

		local newGroups = table.Copy(char:GetData("groups", {}))

		for index, value in pairs(outfitGroups) do
			newGroups[index] = value
			client:SetBodygroup(index, value)
		end

		if (!table.IsEmpty(newGroups)) then
			char:SetData("groups", newGroups)
		end
	end

	if (self.attribBoosts) then
		for k, v in pairs(self.attribBoosts) do
			char:AddBoost(self.uniqueID, k, v)
		end
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
				if (v.id != item.id) then
					local itemTable = ix.item.instances[v.id]

					if (itemTable.pacData and v.outfitCategory == item.outfitCategory and itemTable:GetData("equip")) then
						client:NotifyLocalized(item.equippedNotify or "outfitAlreadyEquipped")
						return false
					end
				end
			end
			
			item:SetData("equip", true)
			PlayRandomSound(client, item.equipSound)
			item:ApplyOutfit(client)

			return false
	end,
	OnCanRun = function(item)
		local client = item.player

		if item.allowedModels and !table.HasValue(item.allowedModels, item.player:GetModel()) then return false end
		return !IsValid(item.entity) and IsValid(client) and item:GetData("equip") != true and item:CanEquipOutfit() and
			hook.Run("CanPlayerEquipItem", client, item) != false and item.invID == client:GetCharacter():GetInventory():GetID()
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
					character:SetAttrib("int", math.Clamp(int + 0.2, 0, 10))
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
		local client = item.player
		
		return !IsValid(item.entity) and IsValid(client) and
			item:GetData("Durability") < item.maxDurability and item.invID == client:GetCharacter():GetInventory():GetID()
	end
}
		
function ITEM:GetRepairAmount(client)
	local character = client:GetCharacter()
	local int = character:GetAttribute("int", 0)
	
	if (int < 2) then
	   return self.maxDurability * 0.2
	elseif (int < 4) then
		return self.maxDurability * 0.4
	elseif (int < 6) then
		return self.maxDurability * 0.6
	elseif (int < 8) then
		return self.maxDurability * 0.8
	else
		return self.maxDurability * 1
	end
end
		
function ITEM:CanTransfer(oldInventory, newInventory)
	if (self:GetData("equip")) then
		return false
	end

	return true
end

function ITEM:OnRemoved()
	if (self.invID != 0 and self:GetData("equip")) then
		self.player = self:GetOwner()
			self:RemoveOutfit(self.player)
		self.player = nil
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
