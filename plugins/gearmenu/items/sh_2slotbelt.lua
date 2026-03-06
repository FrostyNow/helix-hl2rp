ITEM.name = "2 Slot Belt"
ITEM.description = "A belt that provides an additional slot for equipment."
ITEM.model = "models/props_junk/popcan01a.mdl"
ITEM.width = 2
ITEM.height = 1.
ITEM.gearSlot = "belt"

if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		if (item:GetData("equip") == true) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end
end

-- When equipped, tell the character they have an extra weapon slot.
function ITEM:OnEquip()
end

-- When unequipped, remove the slot and unequip any items sitting in it.
function ITEM:OnUnequip()
end