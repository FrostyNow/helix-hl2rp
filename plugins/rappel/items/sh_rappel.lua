ITEM.name = "Rappel Hook"
ITEM.description = "A hook used to rappel down buildings."
ITEM.model = "models/gibs/metal_gib4.mdl"

if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		if (item:GetData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end
end

ITEM.functions.Equip = {
	OnRun = function(item)
        local client = item.player
        local items = client:GetCharacter():GetInventory():GetItems()

		for _, v in pairs(items) do
			if (v.id != item.id) then
				local itemTable = ix.item.instances[v.id]

				if (v.uniqueID == item.uniqueID and itemTable:GetData("equip")) then
					client:NotifyLocalized("rappelAlreadyEquipped")
					return false
				end
			end
		end

        item:SetData("equip", true)
        client:EmitSound("npc/combine_soldier/zipline_clip1.wav")

        item:ApplyRappel(client)
        return false
	end,
    OnCanRun = function(item)
        local client = item.player

        return item:GetData("equip") != true
    end
}

ITEM.functions.EquipUn = {
	OnRun = function(item)
        local client = item.player
        item:RemoveRappel(client)

        item:SetData("equip", false)
        client:EmitSound("npc/combine_soldier/zipline_clip2.wav")

        return false
	end,
    OnCanRun = function(item)
        local client = item.player

        return item:GetData("equip") == true
    end
}

function ITEM:ApplyRappel(client)
    local index = client:FindBodygroupByName("Climber_Hook")
    if (index > -1) then
        client:SetBodygroup(index, 1)
    end

    client.HasRappelHook = true
    self:OnEquipped()
end

function ITEM:RemoveRappel(client)
    local index = client:FindBodygroupByName("Climber_Hook")
    if (index > -1) then
        client:SetBodygroup(index, 0)
    end

    client.HasRappelHook = false
    self:OnUnequipped()
end

function ITEM:OnEquipped()
	hook.Run("OnItemEquipped", self, self:GetOwner())
end

function ITEM:OnUnequipped()
	hook.Run("OnItemUnequipped", self, self:GetOwner())
end

function ITEM:OnLoadout()
	if (self:GetData("equip")) then
        local client = self.player or self:GetOwner()
		self:ApplyRappel(client)
	end
end