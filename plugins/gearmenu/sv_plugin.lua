local PLUGIN = PLUGIN

util.AddNetworkString("ixGearEquipReq")
util.AddNetworkString("ixGearUnequipReq")
util.AddNetworkString("ixGearReorderReq")
util.AddNetworkString("ixGearSync")

-- ============================================================
-- Gear Inventory Management
-- ============================================================

local function GetOrCreateGearInventory(character, callback)
	local gearInvID = character:GetData("gearInvID")

	if (gearInvID) then
		ix.inventory.Restore(gearInvID, PLUGIN.GearInvWidth, PLUGIN.GearInvHeight, function(inv)
			if (inv) then
				inv:SetOwner(character:GetID())
				inv.vars.isGear = true
				
				local client = character:GetPlayer()
				if (IsValid(client)) then
					inv:AddReceiver(client)
					inv:Sync(client)
				end

				callback(inv)
			else
				character:SetData("gearInvID", nil)
				GetOrCreateGearInventory(character, callback)
			end
		end)
	else
		ix.inventory.New(character:GetID(), "ixGearInv", function(inv)
			if (inv) then
				inv:SetOwner(character:GetID())
				inv.vars.isGear = true
				character:SetData("gearInvID", inv:GetID())
				
				local client = character:GetPlayer()
				if (IsValid(client)) then
					inv:AddReceiver(client)
				end

				callback(inv)
			else
				ErrorNoHalt("Failed to create character gear inventory.")
				callback(nil)
			end
		end)
	end
end

-- ============================================================
-- Transfer helpers
-- ============================================================

local function SyncGearSlots(client)
	local character = client:GetCharacter()
	if (!character) then return end

	local gearInvID = character:GetData("gearInvID") or 0

	net.Start("ixGearSync")
		net.WriteUInt(gearInvID, 32)
	net.Send(client)
end

local function IsValidTransferTarget(inventory, x, y, item)
    if (!inventory or !x or !y or !item) then
        return false
    end

    if (x < 1 or y < 1) then
        return false
    end

    local invW, invH = inventory:GetSize()
    local itemW = item.width or 1
    local itemH = item.height or 1

    if ((x + itemW - 1) > invW or (y + itemH - 1) > invH) then
        return false
    end

    return inventory:CanItemFit(x, y, itemW, itemH, item)
end

local function DoGearTransfer(item, newInvID, x, y, client)
    item.bGearTransfer = true
    local oldCanTransfer = item.CanTransfer
    item.CanTransfer = function() return true end

    local success, err = item:Transfer(newInvID, x, y, client)
    
    item.CanTransfer = oldCanTransfer
    item.bGearTransfer = nil
    
    return success
end

local function TransferToGear(item, owner)
    local character = owner:GetCharacter()
    if (!character) then return end
    
    local gearInvID = character:GetData("gearInvID")
    if (!gearInvID) then return end
    
    local gearInv = ix.item.inventories[gearInvID]
    if (!gearInv) then return end
    
    timer.Simple(0, function()
        if (!item or item.invID == gearInvID or item:GetData("equip") != true) then return end
        
        local x, y = gearInv:FindEmptySlot(item.width, item.height)
        if (x and y) then
            DoGearTransfer(item, gearInvID, x, y, owner)

            if (item.isBag) then
                local bagInvID = item:GetData("id")
                local bagInv = bagInvID and ix.item.inventories[bagInvID]
                if (bagInv and IsValid(owner)) then
                    bagInv:AddReceiver(owner)
                end
            end
        end
    end)
end

local function TransferToMain(item, owner)
    if (!item or item.bPendingRemoval or ix.item.instances[item:GetID()] != item) then return end

    local character = owner:GetCharacter()
    local mainInv = character:GetInventory()
    if (!mainInv) then return end

    if (item.bDropOnUnequip) then
        item.bDropOnUnequip = nil
        timer.Simple(0, function()
            if (!item or item.bPendingRemoval or ix.item.instances[item:GetID()] != item or item:GetData("equip") == true) then return end
            
            item.bGearTransfer = true
            local oldCanTransfer = item.CanTransfer
            item.CanTransfer = function() return true end

            local success = item:Transfer(0, nil, nil, owner)
            if (!success) then
                item:SetData("equip", true)
                owner:NotifyLocalized("noFit")
            end

            item.CanTransfer = oldCanTransfer
            item.bGearTransfer = nil
        end)
        return
    end

    local targetX, targetY = nil, nil
    local targetInvID = mainInv:GetID()

    if (item.targetSlot) then
        targetInvID = item.targetSlot.invID
        targetX = item.targetSlot.x
        targetY = item.targetSlot.y
        item.targetSlot = nil
    end

    timer.Simple(0, function()
        if (!item or item.bPendingRemoval or ix.item.instances[item:GetID()] != item or item:GetData("equip") == true) then return end
        
        local x, y = targetX, targetY
        local tInv = ix.item.inventories[targetInvID]

        if (x and y and !IsValidTransferTarget(tInv, x, y, item)) then
            x, y = nil, nil
        end

        if (!x or !y) then
            -- Fallback to next empty slot if coordinates are taken or missing
            if (mainInv:GetID() == targetInvID) then
                x, y = mainInv:FindEmptySlot(item.width, item.height)
            else
                if (tInv) then x, y = tInv:FindEmptySlot(item.width, item.height) end
            end
        end

        local success = false
        if (x and y) then
            success = DoGearTransfer(item, targetInvID, x, y, owner)
        end

        -- ROLLBACK on failure
        if (!success) then
            item:SetData("equip", true)
            owner:NotifyLocalized("noFit")
            print("[GearMenu] Rollback: Re-equipped item because transfer failed.")
        end
    end)
end

local function GetOrderedEquippedWeapons(character)
    local inventory = character and character.GetInventory and character:GetInventory() or nil
    local items = inventory and inventory.GetItems and inventory:GetItems() or {}
    local equippedWeapons = {}

    for _, item in pairs(items) do
        local equipTime = tonumber(item:GetData("equipTime", 0)) or 0

        if (item.isWeapon and item:GetData("equip") == true and equipTime > 0 and item.class != "weapon_physgun" and item.class != "gmod_tool") then
            equippedWeapons[#equippedWeapons + 1] = item
        end
    end

    table.sort(equippedWeapons, function(a, b)
        local aTime = tonumber(a:GetData("equipTime", 0)) or 0
        local bTime = tonumber(b:GetData("equipTime", 0)) or 0

        if (aTime != bTime) then
            return aTime < bTime
        end

        return a.id < b.id
    end)

    return equippedWeapons
end

local function NormalizeEquipTimes(items)
    for index, item in ipairs(items) do
        item:SetData("equipTime", index)
    end
end
-- ============================================================
-- Hooks
-- ============================================================

hook.Add("OnItemEquipped", "ixGearMenu", function(item, owner)
    if (!item or !IsValid(owner)) then return end
    item:SetData("equipTime", os.time())
    TransferToGear(item, owner)
end)

hook.Add("OnItemUnequipped", "ixGearMenu", function(item, owner)
    if (!item or item.bPendingRemoval or ix.item.instances[item:GetID()] != item or !IsValid(owner)) then return end
    item:SetData("equipTime", nil)
    TransferToMain(item, owner)
end)

-- ============================================================
-- Network Receivers
-- ============================================================

net.Receive("ixGearReorderReq", function(len, client)
    local itemID = net.ReadUInt(32)
    local direction = math.Clamp(net.ReadInt(4), -1, 1)

    if (direction == 0) then return end

    local item = ix.item.instances[itemID]
    if (!item or !item.isWeapon or item:GetData("equip") != true) then return end
    if ((item.player != client and item:GetOwner() != client) or item.class == "weapon_physgun" or item.class == "gmod_tool") then return end

    local character = client:GetCharacter()
    local equippedWeapons = GetOrderedEquippedWeapons(character)
    local currentIndex

    for index, equippedItem in ipairs(equippedWeapons) do
        if (equippedItem == item) then
            currentIndex = index
            break
        end
    end

    if (!currentIndex) then return end

    local targetIndex = currentIndex + direction
    if (!equippedWeapons[targetIndex]) then return end

    equippedWeapons[currentIndex], equippedWeapons[targetIndex] = equippedWeapons[targetIndex], equippedWeapons[currentIndex]
    NormalizeEquipTimes(equippedWeapons)
end)
net.Receive("ixGearEquipReq", function(len, client)
    local itemID = net.ReadUInt(32)
    local item = ix.item.instances[itemID]
    if (!item or (item.player != client and item:GetOwner() != client)) then return end
    
    local equipFunc
    for k, v in pairs(item.functions or {}) do
        if (k:lower() == "equip") then equipFunc = v break end
    end
    if (!equipFunc) then return end
    
    item.player = client
    if (equipFunc.OnCanRun and equipFunc.OnCanRun(item) == false) then
        item.player = nil return
    end
    if (equipFunc.OnRun) then
        equipFunc.OnRun(item)
    else
        item:SetData("equip", true)
    end
    item.player = nil
end)

net.Receive("ixGearUnequipReq", function(len, client)
    local itemID = net.ReadUInt(32)
    local targetInvID = net.ReadUInt(32)
    local x = net.ReadInt(16)
    local y = net.ReadInt(16)
    local bDropToGround = net.ReadBool()
    
    local item = ix.item.instances[itemID]
    if (!item or (item.player != client and item:GetOwner() != client)) then return end

    if (bDropToGround) then
        item.bDropOnUnequip = true
    end

    item.player = client
    local character = client:GetCharacter()
    local mainInv = character and character:GetInventory()
    local targetInv = (targetInvID > 0 and ix.item.inventories[targetInvID]) or mainInv

    item.targetSlot = nil

    if (!bDropToGround) then
        local targetX, targetY = x, y
        local bHasExplicitTarget = false

        if (targetInv and targetX != -1 and targetY != -1) then
            if (IsValidTransferTarget(targetInv, targetX, targetY, item)) then
                bHasExplicitTarget = true
            else
                targetX, targetY = -1, -1
            end
        end

        if (!targetX or targetX == -1 or !targetY or targetY == -1) then
            local tInv = targetInv or mainInv
            if (tInv) then
                local tx, ty = tInv:FindEmptySlot(item.width, item.height)
                if (!tx or !ty) then
                    client:NotifyLocalized("noFit")
                    item.player = nil
                    return
                end
            end
        end

        if (bHasExplicitTarget) then
            item.targetSlot = {invID = targetInv:GetID(), x = targetX, y = targetY}
        end
    end

    if (item.functions.EquipUn and item.functions.EquipUn.OnRun) then
        item.functions.EquipUn.OnRun(item)
    else
        item:SetData("equip", false)
    end
    item.player = nil
end)

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

-- Validate transfers TO gear inventory natively (prevent drag/drop natively into gear inv)
function PLUGIN:CanTransferItem(item, curInv, newInv)
	if (item.bGearTransfer) then return true end

	local curIsGear = curInv and curInv.vars and curInv.vars.isGear
	local newIsGear = (istable(newInv) and newInv.vars and newInv.vars.isGear) or false

	if (newIsGear or curIsGear) then
		return false
	end
end

-- Character loaded ??setup gear inventory.
function PLUGIN:CharacterLoaded(character)
	local client = character:GetPlayer()

	if (IsValid(client)) then
		timer.Simple(1, function()
			if (IsValid(client) and client:GetCharacter() == character) then
				GetOrCreateGearInventory(character, function(inv)
					if (inv and IsValid(client)) then
						inv:AddReceiver(client)
						inv:Sync(client)
						inv.vars.isGear = true
						
						-- Trigger OnLoadout for already loaded items inside the gear inventory
						-- once it finishes restoring so they apply properly to the active player model
						for _, item in pairs(inv:GetItems()) do
							if (item.isBag) then
								local bagInvID = item:GetData("id")
								local bagInv = bagInvID and ix.item.inventories[bagInvID]
								if (bagInv) then bagInv:AddReceiver(client) end
							end

							if (item.Call) then
								item:Call("OnLoadout", client)
							end
							
							if (item:GetData("equip") and item.attribBoosts) then
								for attribKey, attribValue in pairs(item.attribBoosts) do
									character:AddBoost(item.uniqueID, attribKey, attribValue)
								end
							end
						end
					end

					SyncGearSlots(client)
				end)
			end
		end)
	end
end

-- Hook into player spawning to re-trigger gear item loadouts synchronously for future respawns
function PLUGIN:PostPlayerLoadout(client)
	local character = client:GetCharacter()
	if (!character) then return end

	local gearInvID = character:GetData("gearInvID")
	if (!gearInvID) then return end

	local gearInv = ix.item.inventories[gearInvID]
	if (!gearInv) then return end

	-- Wait slightly to ensure weapons/loadout are granted so we don't double dip/fail
	timer.Simple(0.1, function()
		if (!IsValid(client) or client:GetCharacter() != character) then return end

		for _, item in pairs(gearInv:GetItems()) do
			if (item:GetData("equip") == true) then
				if (item.Call) then
					item:Call("OnLoadout", client)
				end

				if (item.attribBoosts) then
					for attribKey, attribValue in pairs(item.attribBoosts) do
						character:AddBoost(item.uniqueID, attribKey, attribValue)
					end
				end
			end
		end
	end)
end
