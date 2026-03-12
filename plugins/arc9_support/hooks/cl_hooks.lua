local PLUGIN = PLUGIN
local retryTimer = "ixARC9ClientHookRetry"

local function getPanelItemTable(panel)
    if (not IsValid(panel)) then
        return
    end

    if (panel.GetItemTable) then
        return panel:GetItemTable()
    end

    return panel.itemTable
end

local function walkPanels(panel, callback)
    if (not IsValid(panel)) then
        return
    end

    callback(panel)

    for _, child in ipairs(panel:GetChildren()) do
        walkPanels(child, callback)
    end
end

local function applyARC9IconPanel(panel, itemTable, attempts)
    if (not IsValid(panel) or not itemTable or not ix.arc9 or not ix.arc9.IsARC9Item or not ix.arc9.IsARC9Item(itemTable)) then
        return false
    end

    if (ix.arc9.SetupItemIcon and ix.arc9.SetupItemIcon(panel, itemTable)) then
        return true
    end

    attempts = (attempts or 0) + 1

    if (attempts >= 5) then
        return false
    end

    timer.Simple(0, function()
        applyARC9IconPanel(panel, itemTable, attempts)
    end)

    return false
end

local function refreshARC9Panels(itemID)
    local rendered = false
    local worldPanel = vgui.GetWorldPanel()

    if (not IsValid(worldPanel)) then
        return false
    end

    walkPanels(worldPanel, function(panel)
        if (not IsValid(panel)) then
            return
        end

        local itemTable = getPanelItemTable(panel)

        if (not itemTable or (itemID ~= nil and itemTable.id ~= itemID)) then
            return
        end

        if (ix.arc9 and ix.arc9.IsARC9Item and ix.arc9.IsARC9Item(itemTable) and applyARC9IconPanel(panel, itemTable)) then
            rendered = true
        end
    end)

    return rendered
end

local function refreshARC9ItemIcon(itemID)
    local itemTable = ix.item.instances[itemID]

    if (not itemTable or not ix.arc9 or not ix.arc9.IsARC9Item or not ix.arc9.IsARC9Item(itemTable)) then
        return false
    end

    local rendered = false

    for i = 1, 100 do
        local panel = ix.gui and ix.gui["inv" .. i]

        if (IsValid(panel) and panel.panels) then
            local icon = panel.panels[itemID]

            if (icon ~= nil and not IsValid(icon)) then
                panel.panels[itemID] = nil
            elseif (IsValid(icon) and applyARC9IconPanel(icon, itemTable)) then
                rendered = true
            end
        end
    end

    rendered = refreshARC9Panels(itemID) or rendered

    if (ix.arc9) then
        ix.arc9.SafeRefreshItemIcon = refreshARC9ItemIcon
    end

    return rendered
end

local function patchIconRendering()
    local originalRefreshItemIcon = ix.gui and ix.gui.RefreshItemIcon

    if (isfunction(originalRefreshItemIcon) and not ix.gui.ixARC9RefreshPatched) then
        ix.gui.ixARC9RefreshPatched = true

        ix.gui.RefreshItemIcon = function(itemID)
            local itemTable = ix.item.instances[itemID]

            if (ix.arc9 and ix.arc9.IsARC9Item and ix.arc9.IsARC9Item(itemTable)) then
                return refreshARC9ItemIcon(itemID)
            end

            return originalRefreshItemIcon(itemID)
        end
    end

    local inventoryPanel = vgui.GetControlTable("ixInventory")

    if (inventoryPanel and not inventoryPanel.ixARC9SupportPatched) then
        inventoryPanel.ixARC9SupportPatched = true

        local originalAddIcon = inventoryPanel.AddIcon

        function inventoryPanel:AddIcon(model, x, y, w, h, skin)
            local panel = originalAddIcon(self, model, x, y, w, h, skin)

            if (not IsValid(panel)) then
                return panel
            end

            timer.Simple(0, function()
                if (not IsValid(panel)) then
                    return
                end

                local itemTable = getPanelItemTable(panel)

                if (itemTable and ix.arc9 and ix.arc9.IsARC9Item and ix.arc9.IsARC9Item(itemTable)) then
                    applyARC9IconPanel(panel, itemTable)
                end
            end)

            return panel
        end
    end

    return inventoryPanel ~= nil
end
local function patchItemEntityRendering()
    local stored = scripted_ents.GetStored("ix_item")
    local entityTable = stored and stored.t

    if (entityTable and not entityTable.ixARC9SupportPatched) then
        entityTable.ixARC9SupportPatched = true
    end

    return entityTable ~= nil and entityTable.ixARC9SupportPatched
end

local function patchClientHooks()
    local iconPatched = patchIconRendering()
    local entityPatched = patchItemEntityRendering()

    if (ix.arc9) then
        ix.arc9.SafeRefreshItemIcon = refreshARC9ItemIcon
    end

    return iconPatched and entityPatched
end

function PLUGIN:InitializedPlugins()
    timer.Simple(0, patchClientHooks)

    if (timer.Exists(retryTimer)) then
        timer.Remove(retryTimer)
    end

    timer.Create(retryTimer, 1, 15, function()
        if (patchClientHooks()) then
            timer.Remove(retryTimer)
        end
    end)
end

if (CLIENT) then
    local nextARC9Sync = 0

    local function updateDroppedItemOverrides()
        for _, entity in ipairs(ents.FindByClass("ix_item")) do
            if (not IsValid(entity)) then
                continue
            end

            local itemTable = entity.GetItemTable and entity:GetItemTable()
            local shouldHide = ix.arc9 and ix.arc9.IsARC9Item(itemTable)

            if (entity:GetNoDraw() ~= shouldHide) then
                entity:SetNoDraw(shouldHide)
            end
        end
    end

    hook.Add("PostDrawTranslucentRenderables", "ixARC9DrawDroppedItems", function(depth, skybox)
        if (skybox) then
            return
        end

        for _, entity in ipairs(ents.FindByClass("ix_item")) do
            if (not IsValid(entity)) then
                continue
            end

            local itemTable = entity.GetItemTable and entity:GetItemTable()

            if (ix.arc9 and ix.arc9.IsARC9Item(itemTable)) then
                ix.arc9.DrawItemEntity(itemTable, entity, entity)
            end
        end
    end)

    hook.Add("Think", "ixARC9SyncWeapons", function()
        if (nextARC9Sync > CurTime()) then
            return
        end

        nextARC9Sync = CurTime() + 0.25

        updateDroppedItemOverrides()
        refreshARC9Panels()

        local client = LocalPlayer()

        if (not IsValid(client)) then
            return
        end

        local character = client:GetCharacter()
        local inventory = character and character:GetInventory()

        if (not inventory) then
            return
        end

        for itemTable, _ in inventory:Iter() do
            if (itemTable.isARC9Weapon) then
                local modelInfo = ix.arc9 and ix.arc9.GetModelInfo and ix.arc9.GetModelInfo(itemTable) or nil

                if (modelInfo) then
                    itemTable.ixARC9IconReady = true
                else
                    itemTable.ixARC9IconReady = nil
                end
            end

            if (itemTable.isARC9Weapon and itemTable.SetWeapon) then
                local weapon = itemTable:GetData("equip", false) and client:GetWeapon(itemTable.class) or nil

                if (IsValid(weapon)) then
                    itemTable:SetWeapon(weapon)
                    weapon.ixItem = itemTable
                    weapon.LoadedPreset = true

                    if (isfunction(weapon.SetNoPresets)) then
                        weapon:SetNoPresets(true)
                    end

                    ix.arc9.ApplyWorldModelOffset(weapon, itemTable)
                else
                    itemTable:SetWeapon(nil)
                end
            end
        end
    end)
end

concommand.Add("ix_arc9_dumptrace", function()
    if (not ix.arc9 or not ix.arc9.DumpTraceData) then
        print("[ix_arc9] arc9 support is not ready")
        return
    end

    local ok, result = ix.arc9.DumpTraceData()

    if (ok) then
        print("[ix_arc9] dumped trace data to data/" .. result)
    else
        print("[ix_arc9] dump failed: " .. tostring(result))
    end
end)



