local PLUGIN = PLUGIN

util.AddNetworkString("ixGearEquipReq")
util.AddNetworkString("ixGearUnequipReq")
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
        end
    end)
end

local function TransferToMain(item, owner)
    local character = owner:GetCharacter()
    local mainInv = character:GetInventory()
    if (!mainInv) then return end

    local targetX, targetY = nil, nil
    local targetInvID = mainInv:GetID()

    if (item.targetSlot) then
        targetInvID = item.targetSlot.invID
        targetX = item.targetSlot.x
        targetY = item.targetSlot.y
        item.targetSlot = nil
    end

    timer.Simple(0, function()
        if (!item or item:GetData("equip") == true) then return end
        
        local x, y = targetX, targetY
        if (!x or !y) then
            -- Fallback to next empty slot if coordinates are taken or missing
            if (mainInv:GetID() == targetInvID) then
                x, y = mainInv:FindEmptySlot(item.width, item.height)
            else
                local tInv = ix.item.inventories[targetInvID]
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
            owner:NotifyLocalized("noSpace")
            print("[GearMenu] Rollback: Re-equipped item because transfer failed.")
        end
    end)
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
    if (!item or !IsValid(owner)) then return end
    item:SetData("equipTime", nil)
    TransferToMain(item, owner)
end)

-- ============================================================
-- FIX: Override RemoveOutfit AFTER items are loaded
-- The base sh_outfit.lua only scans character:GetInventory()
-- so items in gear inv lose their bodygroups on unequip.
-- ============================================================

local function SetupBodygroupFix()
    local baseOutfit = ix.item.list and ix.item.list["base_outfit"]
    if (!baseOutfit) then return end
    if (baseOutfit.ixGearMenuOverridden) then return end
    baseOutfit.ixGearMenuOverridden = true

    local origRemoveOutfit = baseOutfit.RemoveOutfit

    baseOutfit.RemoveOutfit = function(self, client)
        origRemoveOutfit(self, client)

        if (!IsValid(client) or !client:GetCharacter()) then return end
        local charID = client:GetCharacter():GetID()

        for _, item in pairs(ix.item.instances) do
            if (item.id != self.id and item.characterID == charID and item:GetData("equip") == true) then
                local bgs = item.eqBodyGroups or item.bodyGroups

                if (istable(bgs) and !table.IsEmpty(bgs)) then
                    for bgName, bgValue in pairs(bgs) do
                        local index = tonumber(bgName) or client:FindBodygroupByName(tostring(bgName))
                        if (index and index > -1) then
                            client:SetBodygroup(index, tonumber(bgValue) or 0)
                        end
                    end
                end
            end
        end
    end
end

hook.Add("InitializedSchema", "ixGearMenuBodygroupFix", SetupBodygroupFix)
SetupBodygroupFix() -- run immediately for hot-reload

-- ============================================================
-- Network Receivers
-- ============================================================

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
    
    local item = ix.item.instances[itemID]
    if (!item or (item.player != client and item:GetOwner() != client)) then return end

    item.player = client
    local character = client:GetCharacter()
    local targetInv = ix.item.inventories[targetInvID] or (character and character:GetInventory())
    
    -- Preserve explicit unequip coordinates
    if (targetInv and x != -1 and y != -1) then
        item.targetSlot = {invID = targetInv:GetID(), x = x, y = y}
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

concommand.Add("ix_gear_rescue", function(ply, cmd, args)
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
    
    local mainInv = char:GetInventory()
    local gearInvID = char:GetData("gearInvID")
    if (!mainInv or !gearInvID) then return end
    
    local count = 0
    for id, item in pairs(ix.item.instances) do
        if (item.invID == gearInvID and item:GetData("equip") != true) then
            -- Use bGearTransfer to pass CanTransferItem check
            item.bGearTransfer = true
            local oldCanTransfer = item.CanTransfer
            item.CanTransfer = function() return true end

            local tx, ty = mainInv:FindEmptySlot(item.width, item.height)
            if (tx and ty) then
                item:Transfer(mainInv:GetID(), tx, ty)
            else
                item:Spawn(targetPly:GetPos())
                item:Transfer(0, nil, nil)
            end

            item.CanTransfer = oldCanTransfer
            item.bGearTransfer = nil
            count = count + 1
        end
    end
    
    if (IsValid(ply)) then
        ply:Notify("Rescued " .. count .. " items.")
    end
end)

-- Validate transfers TO gear inventory natively (prevent drag/drop natively into gear inv)
function PLUGIN:CanTransferItem(item, curInv, newInv)
	if (!item or !curInv or !newInv) then return end
	local curIsGear = curInv.vars and curInv.vars.isGear
	local newIsGear = newInv.vars and newInv.vars.isGear
	if (item.bGearTransfer) then return true end
	if (newIsGear or curIsGear) then return false end
end

-- Character loaded → setup gear inventory.
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

function PLUGIN:CanPlayerEquipItem(client, item)
	if (!item or !item.isWeapon or !item.weaponCategory) then return end
	local character = client:GetCharacter()
	if (!character) then return end
	local charID = character:GetID()
	for id, other in pairs(ix.item.instances) do
		if (other.id != item.id and other.isWeapon and other.weaponCategory == item.weaponCategory and other:GetData("equip") == true and other.characterID == charID) then
			client:NotifyLocalized("weaponSlotFilled", item.weaponCategory)
			return false
		end
	end
end