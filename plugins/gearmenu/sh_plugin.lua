local PLUGIN = PLUGIN

PLUGIN.Title = "Gear Menu"
PLUGIN.Author = "Ronald and Frosty"
PLUGIN.Description = "Make menu for store equipment gear so it doesn't have slot in inventory."
PLUGIN.Version = "2.0.0"

PLUGIN.GearInvWidth = 50
PLUGIN.GearInvHeight = 50

ix.lang.AddTable("english", {
	["gear"] = "Inventory",
	gearTooltip = "Drag and drop\nto equip or unequip.",
})
ix.lang.AddTable("korean", {
	["gear"] = "소지품 및 장비",
	["Inventory"] = "소지품",
	["Equipment"] = "장비",
	gearTooltip = "장비를 드래그 드랍하여\n장착하거나 해제하실 수 있습니다.",
})

ix.inventory.Register("ixGearInv", PLUGIN.GearInvWidth, PLUGIN.GearInvHeight, true)

-- Helper: check if an inventory is a gear inventory.
function PLUGIN:IsGearInventory(invID)
	local inv = ix.item.inventories[invID]
	return inv and inv.vars and inv.vars.isGear
end

-- ============================================================
-- GLOBAL OVERRIDE: ix.meta.inventory
-- Make GetItems() universally return Gear Items for compatibility
-- ============================================================
local ix_inv = ix.meta.inventory
if (ix_inv) then
	ix_inv.GearOriginalGetItems = ix_inv.GearOriginalGetItems or ix_inv.GetItems

	function ix_inv:GetItems(onlyMain)
		local items = self:GearOriginalGetItems(onlyMain)

		-- Only inject gear items when directly querying a character's primary main inventory.
		-- onlyMain = false natively allows bags via base GetItems. Here we extend it to gear.
		if (onlyMain != true and !self.vars.isBag and !self.vars.isGear and self.owner) then
			local character = ix.char.loaded and ix.char.loaded[self.owner]
			
			if (character and character:GetInventory() == self) then
				local gearID = character:GetData("gearInvID")
				local gearInv = gearID and ix.item.inventories[gearID]

				if (gearInv and gearInv != self) then
					for itemID, itemInst in pairs(gearInv:GearOriginalGetItems(true)) do
						items[itemID] = itemInst
					end
				end
			end
		end

		return items
	end
end

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")

-- ============================================================
-- Commands
-- ============================================================

concommand.Add("ix_gear_dump", function(ply, cmd, args)
    if (IsValid(ply) and !ply:IsSuperAdmin()) then return end
    
    local targetPly = ply
    if (args[1]) then
        for _, v in ipairs(player.GetAll()) do
            if (string.find(string.lower(v:Nick()), string.lower(args[1])) or v:SteamID() == args[1]) then
                targetPly = v break
            end
        end
    end
    if (!IsValid(targetPly)) then return end

    local char = targetPly:GetCharacter()
    if (!char) then return end

    local charID = char:GetID()
    local mainInv = char:GetInventory()
    local gearInvID = char:GetData("gearInvID")
    local dropPos = targetPly:GetPos() + Vector(0, 0, 32)
    local count = 0

    -- Collect ALL items belonging to this character
    local itemsToDump = {}
    for id, item in pairs(ix.item.instances) do
        if (item.characterID == charID and item.invID and item.invID > 0) then
            itemsToDump[#itemsToDump + 1] = item
        end
    end

    for _, item in ipairs(itemsToDump) do
        -- Unequip if equipped
        if (item:GetData("equip") == true) then
            item.player = targetPly

            if (item.functions and item.functions.EquipUn and item.functions.EquipUn.OnRun) then
                item.functions.EquipUn.OnRun(item)
            else
                item:SetData("equip", false)
            end

            item.player = nil
            item:SetData("equipTime", nil)
        end

        -- Force transfer to world
        item.bGearTransfer = true
        local oldCanTransfer = item.CanTransfer
        item.CanTransfer = function() return true end

        local oldInvID = item.invID
        local success = item:Transfer(0, nil, nil, targetPly)
        
        if (success) then
            count = count + 1
        else
            -- If Transfer fails, force cleanup and spawn
            item.invID = 0
            item:SetData("equip", false)
            item:Spawn(dropPos)

            local oldInv = ix.item.inventories[oldInvID]
            if (oldInv) then
                oldInv:Remove(item.id, false) -- Manually remove from server-side inv to trigger sync
            end
            count = count + 1
        end

        item.CanTransfer = oldCanTransfer
        item.bGearTransfer = nil
    end

    -- Clear gear inventory slots to fix any ghost data
    if (gearInvID) then
        local gearInv = ix.item.inventories[gearInvID]
        if (gearInv) then
            gearInv.slots = {}
            if (gearInv.Sync) then
                gearInv:Sync(targetPly)
            end
        end
    end

    -- Re-sync main inventory to fix ghost slots
    if (mainInv and mainInv.Sync) then
        mainInv:Sync(targetPly)
    end

    if (IsValid(ply)) then
        ply:Notify("Dumped " .. count .. " items to the ground and re-synced inventories.")
    end
    print("[GearMenu] ix_gear_dump: " .. count .. " items dumped for " .. targetPly:Nick())
end)