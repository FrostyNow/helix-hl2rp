ITEM.name = "2 Slot Belt"
ITEM.description = "A belt that provides an additional slot for equipment."
ITEM.model = "models/props_junk/popcan01a.mdl"
ITEM.width = 2
ITEM.height = 1.
ITEM.gearSlot = "belt"

if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		if (item:GetData("equipSlot") != nil) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end
end

-- When equipped, tell the character they have an extra weapon slot.
function ITEM:OnEquip()
	local client = self.player or self:GetOwner()
	if (!IsValid(client)) then return end

	local character = client:GetCharacter()
	if (!character) then return end

	-- We use character data to store dynamically granted slots
	local extraSlots = character:GetData("extraGearSlots", {})
	if (!table.HasValue(extraSlots, "weapon2")) then
		table.insert(extraSlots, "weapon2")
		character:SetData("extraGearSlots", extraSlots)
	end
end

-- When unequipped, remove the slot and unequip any items sitting in it.
function ITEM:OnUnequip()
	local client = self.player or self:GetOwner()
	if (!IsValid(client)) then return end

	local character = client:GetCharacter()
	if (!character) then return end

	local extraSlots = character:GetData("extraGearSlots", {})
	table.RemoveByValue(extraSlots, "weapon2")
	character:SetData("extraGearSlots", extraSlots)

	-- If the slot disappears, any item equipped to that slot must be unequipped.
	local gearInvID = character:GetData("gearInvID")
	local gearInv = gearInvID and ix.item.inventories[gearInvID]
	
	if (gearInv) then
		for _, item in pairs(gearInv:GetItems()) do
			if (item:GetData("equipSlot") == "weapon2") then
				
				-- Unequip the weapon2 item natively and move back to main inventory
				if (item.OnUnequip) then item:OnUnequip() end
				item:SetData("equipSlot", nil)
				
				local mainInv = character:GetInventory()
				local emptyX, emptyY = mainInv:FindEmptySlot(item.width, item.height)
				
				if (emptyX and emptyY) then
					item:Transfer(mainInv:GetID(), emptyX, emptyY, client)
				else
					-- Drop on floor if inventory full
					local bStatus = item:Transfer(0, 0, 0, client)
					if (bStatus and IsValid(item.entity)) then
						item.entity:SetPos(client:GetPos() + Vector(0,0,10))
					end
				end
			end
		end
	end
end