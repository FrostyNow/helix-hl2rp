ix.arc9 = ix.arc9 or {}
ix.arc9.presetCache = ix.arc9.presetCache or {}
ix.arc9.attachmentTemplateCache = ix.arc9.attachmentTemplateCache or {}

local function copyValue(value)
    if (istable(value)) then
        return table.Copy(value)
    end

    return value
end

local function mergeTable(target, overrides)
    if (not istable(overrides)) then
        return target
    end

    for key, value in pairs(overrides) do
        target[key] = copyValue(value)
    end

    return target
end

local function normalizeModel(model)
    if (not isstring(model)) then
        return ""
    end

    return string.lower(model)
end

local function readItemData(itemTable, dataSource, key, default)
    if (IsValid(dataSource) and dataSource.GetData) then
        local value = dataSource:GetData(key, nil)

        if (value ~= nil) then
            return value
        end
    end

    if (istable(itemTable) and itemTable.GetData) then
        local value = itemTable:GetData(key, nil)

        if (value ~= nil) then
            return value
        end
    end

    return default
end

local function rotateAngle(ang, offset)
    if (not isangle(offset)) then
        return ang
    end

    ang:RotateAroundAxis(ang:Right(), offset.p)
    ang:RotateAroundAxis(ang:Up(), offset.y)
    ang:RotateAroundAxis(ang:Forward(), offset.r)

    return ang
end

local function setInstalled(slot, value)
    if (isstring(value)) then
        slot.Installed = value ~= "" and value or nil
        return
    end

    if (not istable(value)) then
        return
    end

    local installed = value.Installed or value.installed or value.Attachment or value.attachment or value.att

    if (isstring(installed)) then
        slot.Installed = installed ~= "" and installed or nil
    end

    if (value.ToggleNum ~= nil) then
        slot.ToggleNum = value.ToggleNum
    end
end

local function applyPresetNode(slot, presetNode)
    if (not istable(slot) or presetNode == nil) then
        return
    end

    -- ARC9 export keeps removed slots as empty tables, which should clear defaults.
    if (presetNode == false or (istable(presetNode) and next(presetNode) == nil)) then
        slot.Installed = nil
        slot.ToggleNum = nil
        slot.SubAttachments = nil
        return
    end

    slot.SubAttachments = nil
    slot.ToggleNum = nil
    setInstalled(slot, presetNode)

    if (not istable(presetNode)) then
        return
    end

    local subAttachments = presetNode.SubAttachments or presetNode.subAttachments

    if (not istable(subAttachments) or next(subAttachments) == nil) then
        return
    end

    slot.SubAttachments = {}

    for key, subNode in pairs(subAttachments) do
        local index = tonumber(key)

        if (index) then
            slot.SubAttachments[index] = slot.SubAttachments[index] or {}
            applyPresetNode(slot.SubAttachments[index], subNode)
        end
    end
end

local function locateSlotByAddress(slots, address)
    if (not isstring(address)) then
        return
    end

    local currentSlots = slots
    local currentSlot

    for section in string.gmatch(address, "[^%.]+") do
        local index = tonumber(section)

        if (not index or not istable(currentSlots)) then
            return
        end

        currentSlot = currentSlots[index]

        if (not istable(currentSlot)) then
            return
        end

        currentSlots = currentSlot.SubAttachments
    end

    return currentSlot
end

local function getMirrorModel(swep)
    if (not swep) then
        return
    end

    local model = swep.WorldModelMirror

    if (not isstring(model) or model == "") then
        model = swep.MirrorWorldModel
    end

    if (isstring(model) and model ~= "") then
        return model
    end

    if (swep.MirrorVMWM and isstring(swep.ViewModel) and swep.ViewModel ~= "") then
        return swep.ViewModel
    end
end

local function getBodygroupSeed(swep, useMirrorModel)
    if (not swep) then
        return
    end

    if (useMirrorModel) then
        return swep.DefaultBodygroups or swep.DefaultWMBodygroups
    end

    return swep.DefaultWMBodygroups or swep.DefaultBodygroups
end

local function applyBodygroupSet(entity, bodygroups)
    if (not IsValid(entity) or bodygroups == nil) then
        return
    end

    if (isstring(bodygroups) and bodygroups ~= "" and entity.SetBodyGroups) then
        entity:SetBodyGroups(bodygroups)
        return
    end

    if (not istable(bodygroups)) then
        return
    end

    for key, value in pairs(bodygroups) do
        local index = tonumber(key)

        if (index == nil) then
            index = entity:FindBodygroupByName(key)
        end

        if (index and index > -1) then
            entity:SetBodygroup(index, tonumber(value) or 0)
        end
    end
end

function ix.arc9.IsARC9WeaponClass(className)
    if (not isstring(className) or className == "") then
        return false
    end

    local swep = weapons.GetStored(className)
    local loweredClass = string.lower(className)

    if (string.StartWith(loweredClass, "arc9_")) then
        return true
    end

    if (not swep) then
        return false
    end

    if (swep.ARC9) then
        return true
    end

    if (weapons.IsBasedOn and weapons.IsBasedOn(className, "arc9_base")) then
        return true
    end

    local base = swep.Base

    return isstring(base) and string.find(string.lower(base), "arc9", 1, true) ~= nil
end

function ix.arc9.IsARC9Item(itemTable)
    return istable(itemTable) and isstring(itemTable.class) and ix.arc9.IsARC9WeaponClass(itemTable.class)
end

function ix.arc9.CacheAttachmentTemplates(force)
    if (force) then
        ix.arc9.attachmentTemplateCache = {}
    end

    for _, swep in ipairs(weapons.GetList() or {}) do
        local className = swep.ClassName

        if (isstring(className) and ix.arc9.IsARC9WeaponClass(className) and istable(swep.Attachments)) then
            if (force or not istable(ix.arc9.attachmentTemplateCache[className])) then
                ix.arc9.attachmentTemplateCache[className] = table.Copy(swep.Attachments)
            end

            local stored = weapons.GetStored(className)

            if (istable(stored)) then
                stored.ixARC9OriginalAttachments = table.Copy(ix.arc9.attachmentTemplateCache[className])
            end
        end
    end
end
function ix.arc9.GetWeaponTable(itemTable)
    local className = isstring(itemTable) and itemTable or (itemTable and itemTable.class)

    if (not isstring(className)) then
        return
    end

    return weapons.GetStored(className)
end

function ix.arc9.GetPreset(itemTable, dataSource)
    if (not ix.arc9.IsARC9Item(itemTable)) then
        return
    end

    return readItemData(itemTable, dataSource, "preset", itemTable.defaultPreset)
end

function ix.arc9.GetBodygroups(itemTable, dataSource)
    return readItemData(itemTable, dataSource, "bodygroups", itemTable.bodyGroups)
end

function ix.arc9.GetModelInfo(itemTable)
    if (not ix.arc9.IsARC9Item(itemTable)) then
        return
    end

    local swep = ix.arc9.GetWeaponTable(itemTable)

    if (not swep) then
        return
    end

    local mirrorModel = getMirrorModel(swep)
    local visualModel = itemTable.arc9VisualModel

    if (not isstring(visualModel) or visualModel == "") then
        visualModel = mirrorModel or swep.WorldModel or itemTable.model
    end

    local physicsModel = itemTable.arc9PhysicsModel

    if (not isstring(physicsModel) or physicsModel == "") then
        physicsModel = swep.WorldModel or itemTable.model or visualModel
    end

    local dropOffset = ix.arc9.GetConfiguredDroppedModelOffset(itemTable) or {}
    local useProxyModel = normalizeModel(visualModel) ~= normalizeModel(physicsModel)

    if (itemTable.arc9ForceVisualProxy ~= nil) then
        useProxyModel = itemTable.arc9ForceVisualProxy and true or false
    end

    return {
        baseBodygroups = getBodygroupSeed(swep, normalizeModel(visualModel) == normalizeModel(mirrorModel)),
        dropAng = itemTable.arc9DroppedAng or dropOffset.Ang,
        dropPos = itemTable.arc9DroppedPos or dropOffset.Pos,
        modelScale = itemTable.arc9DroppedScale or dropOffset.Scale or 1,
        physicsModel = physicsModel,
        swep = swep,
        useProxyModel = useProxyModel,
        visualModel = visualModel,
    }
end

function ix.arc9.GetVisualModel(itemTable)
    local info = ix.arc9.GetModelInfo(itemTable)
    return info and info.visualModel
end

function ix.arc9.GetPhysicsModel(itemTable)
    local info = ix.arc9.GetModelInfo(itemTable)
    return info and info.physicsModel
end

local function copyIconVector(value, default)
    default = default or Vector(0, 0, 0)

    if (isvector(value)) then
        return Vector(value.x, value.y, value.z)
    end

    if (istable(value)) then
        return Vector(value[1] or value.x or default.x, value[2] or value.y or default.y, value[3] or value.z or default.z)
    end

    return Vector(default.x, default.y, default.z)
end

local function copyIconAngle(value, default)
    default = default or Angle(0, 0, 0)

    if (isangle(value)) then
        return Angle(value.p, value.y, value.r)
    end

    if (istable(value)) then
        return Angle(value[1] or value.p or default.p, value[2] or value.y or default.y, value[3] or value.r or default.r)
    end

    return Angle(default.p, default.y, default.r)
end

local function compensateIconFOV(snapshotFOV, itemTable, swep)
    local scaledFOV = snapshotFOV * (tonumber(itemTable.arc9IconFOVMul) or tonumber(swep and swep.IXIconFOVMul) or 0.58)

    return math.Clamp(scaledFOV + (tonumber(itemTable.arc9IconFOVBias) or 0), 20, snapshotFOV)
end

local function buildARC9SnapshotIconLayout(itemTable, modelInfo)
    local swep = modelInfo and modelInfo.swep or ix.arc9.GetWeaponTable(itemTable)

    if (not swep) then
        return
    end

    local cameraPos = Vector(0, 0, 0)
    local cameraAng = Angle(0, 0, 0)
    local customPos = copyIconVector(swep.CustomizePos) + copyIconVector(swep.CustomizeSnapshotPos)
    local customAng = copyIconAngle(swep.CustomizeAng)
    local snapshotAng = copyIconAngle(swep.CustomizeSnapshotAng)
    local renderPos = Vector(0, 0, 1)
    local renderAng = Angle(0, 0, 0)

    customAng = Angle(customAng.p + snapshotAng.p, customAng.y + snapshotAng.y, customAng.r + snapshotAng.r)

    renderPos = renderPos + (cameraAng:Right() * customPos.x)
    renderPos = renderPos + (cameraAng:Forward() * customPos.y)
    renderPos = renderPos + (cameraAng:Up() * customPos.z)

    renderAng:RotateAroundAxis(cameraAng:Up(), customAng.p)
    renderAng:RotateAroundAxis(cameraAng:Right(), customAng.y)
    renderAng:RotateAroundAxis(cameraAng:Forward(), customAng.r)

    return {
        camera = {
            ang = cameraAng,
            fov = tonumber(itemTable.arc9IconFOV) or compensateIconFOV(tonumber(swep.CustomizeSnapshotFOV) or 90, itemTable, swep),
            pos = cameraPos,
        },
        renderAng = renderAng,
        renderPos = renderPos + Vector(0.5, -0.5, -0.5),
    }
end

function ix.arc9.GetIconLayout(itemTable, modelInfo)
    if (istable(itemTable.arc9IconCam)) then
        local iconCam = table.Copy(itemTable.arc9IconCam)

        return {
            camera = iconCam,
            renderAng = copyIconAngle(iconCam.renderAng or itemTable.arc9IconModelAng),
            renderPos = copyIconVector(iconCam.renderPos or itemTable.arc9IconModelPos),
        }
    end

    local layout = buildARC9SnapshotIconLayout(itemTable, modelInfo)

    if (layout) then
        return layout
    end

    local camera = nil

    if (itemTable.arc9UseItemIconCam != false and (not modelInfo or normalizeModel(modelInfo.visualModel) == normalizeModel(itemTable.model))) then
        camera = itemTable.iconCam and table.Copy(itemTable.iconCam) or nil
    end

    return {
        camera = camera,
        renderAng = copyIconAngle(itemTable.arc9IconModelAng),
        renderPos = copyIconVector(itemTable.arc9IconModelPos),
    }
end

function ix.arc9.GetIconCam(itemTable, modelInfo)
    local layout = ix.arc9.GetIconLayout(itemTable, modelInfo)
    return layout and layout.camera or nil
end

function ix.arc9.GetPresetTable(className, preset)
    if (not isstring(className) or not isstring(preset) or preset == "") then
        return
    end

    local cacheKey = className .. "::" .. preset

    if (ix.arc9.presetCache[cacheKey] ~= nil) then
        return table.Copy(ix.arc9.presetCache[cacheKey])
    end

    local swep = weapons.GetStored(className)
    local presetSource = swep
    local seen = {}

    while (istable(presetSource) and not isfunction(presetSource.ImportPresetCode)) do
        local baseName = presetSource.Base

        if (not isstring(baseName) or baseName == "" or seen[baseName]) then
            break
        end

        seen[baseName] = true
        presetSource = weapons.GetStored(baseName)
    end

    if (not istable(presetSource) or not isfunction(presetSource.ImportPresetCode)) then
        presetSource = weapons.GetStored("arc9_base")
    end

    if (not presetSource or not isfunction(presetSource.ImportPresetCode)) then
        return
    end

    local ok, result = pcall(presetSource.ImportPresetCode, presetSource, preset)

    if (ok and istable(result)) then
        ix.arc9.presetCache[cacheKey] = table.Copy(result)
        return result
    end
end
local function getAttachmentTemplate(itemTable, swep)
    local className = itemTable and itemTable.class

    if (not isstring(className) or className == "") then
        className = IsValid(swep) and swep:GetClass() or nil
    end

    if (not isstring(className) or className == "") then
        return
    end

    local stored = weapons.GetStored(className)
    local cached = ix.arc9.attachmentTemplateCache[className] or (istable(stored) and stored.ixARC9OriginalAttachments)

    if (istable(cached)) then
        return cached
    end

    local base = baseclass.Get(className)
    local source = (istable(base) and base.Attachments) or (swep and swep.Attachments)

    if (not istable(source)) then
        return
    end

    ix.arc9.attachmentTemplateCache[className] = table.Copy(source)
    return ix.arc9.attachmentTemplateCache[className]
end

local function getFreshAttachmentTree(itemTable, swep)
    local template = getAttachmentTemplate(itemTable, swep)

    if (not istable(template)) then
        return
    end

    return table.Copy(template)
end

local function stripAttachmentTree(slots)
    if (not istable(slots)) then
        return slots
    end

    for _, slot in ipairs(slots) do
        if (istable(slot)) then
            slot.Installed = nil
            slot.ToggleNum = nil

            if (istable(slot.SubAttachments)) then
                stripAttachmentTree(slot.SubAttachments)
            end

            slot.SubAttachments = nil
        end
    end

    return slots
end

function ix.arc9.ResetWeaponAttachments(weapon, itemTable)
    if (not IsValid(weapon)) then
        return false
    end

    itemTable = itemTable or weapon.ixItem or {class = weapon:GetClass()}

    local freshTree = getFreshAttachmentTree(itemTable, weapon)

    if (not istable(freshTree)) then
        return false
    end

    weapon.Attachments = table.Copy(freshTree)

    if (isfunction(weapon.BuildSubAttachments)) then
        weapon:BuildSubAttachments(freshTree)
    end

    if (isfunction(weapon.SetNoPresets)) then
        weapon:SetNoPresets(true)
    end

    if (isfunction(weapon.PostModify)) then
        weapon:PostModify()
    end

    return true
end

function ix.arc9.ApplyPresetToSlots(slots, presetTable)
    if (not istable(slots) or not istable(presetTable)) then
        return slots
    end

    for key, value in pairs(presetTable) do
        local index = tonumber(key)

        if (index and istable(slots[index])) then
            applyPresetNode(slots[index], value)
        elseif (isstring(key)) then
            local slot = locateSlotByAddress(slots, key)

            if (slot) then
                applyPresetNode(slot, value)
            end
        end
    end

    return slots
end

function ix.arc9.GetItemSlots(itemTable, dataSource)
    local swep = ix.arc9.GetWeaponTable(itemTable)

    if (not swep or not istable(swep.Attachments)) then
        return
    end

    local slots = getFreshAttachmentTree(itemTable, swep)
    local preset = ix.arc9.GetPreset(itemTable, dataSource)

    if (not istable(slots)) then
        return
    end

    local presetTable = ix.arc9.GetPresetTable(itemTable.class, preset)

    if (presetTable) then
        stripAttachmentTree(slots)
        ix.arc9.ApplyPresetToSlots(slots, presetTable)
    end

    return slots, swep
end
function ix.arc9.GetConfiguredWorldModelOffset(itemTable)
    if (not ix.arc9.IsARC9Item(itemTable)) then
        return
    end

    local swep = ix.arc9.GetWeaponTable(itemTable)
    local worldModelOffset = table.Copy((swep and swep.WorldModelOffset) or {})

    mergeTable(worldModelOffset, itemTable.arc9WorldModelOffset)
    mergeTable(worldModelOffset, itemTable.worldModelOffsetOverride)

    if (isvector(itemTable.arc9WorldPos)) then
        worldModelOffset.Pos = itemTable.arc9WorldPos
    end

    if (isangle(itemTable.arc9WorldAng)) then
        worldModelOffset.Ang = itemTable.arc9WorldAng
    end

    if (isvector(itemTable.arc9TPIKPos)) then
        worldModelOffset.TPIKPos = itemTable.arc9TPIKPos
    end

    if (isangle(itemTable.arc9TPIKAng)) then
        worldModelOffset.TPIKAng = itemTable.arc9TPIKAng
    end

    if (itemTable.arc9WorldScale ~= nil) then
        worldModelOffset.Scale = itemTable.arc9WorldScale
    end

    return worldModelOffset
end

function ix.arc9.GetConfiguredDroppedModelOffset(itemTable)
    if (not ix.arc9.IsARC9Item(itemTable)) then
        return
    end

    local droppedOffset = {
        Pos = Vector(0, 0, 0),
        Ang = Angle(0, 0, 0),
        Scale = 1,
    }

    mergeTable(droppedOffset, itemTable.arc9DroppedModelOffset)

    if (isvector(itemTable.arc9DroppedPos)) then
        droppedOffset.Pos = itemTable.arc9DroppedPos
    end

    if (isangle(itemTable.arc9DroppedAng)) then
        droppedOffset.Ang = itemTable.arc9DroppedAng
    end

    if (itemTable.arc9DroppedScale ~= nil) then
        droppedOffset.Scale = itemTable.arc9DroppedScale
    end

    return droppedOffset
end

function ix.arc9.ApplyWorldModelOffset(weapon, itemTable)
    if (not IsValid(weapon) or not ix.arc9.IsARC9Item(itemTable)) then
        return
    end

    local configured = ix.arc9.GetConfiguredWorldModelOffset(itemTable)

    if (configured) then
        weapon.WorldModelOffset = configured
    end

    if (CLIENT and isfunction(weapon.RecalculateIKGunMotionOffset)) then
        weapon:RecalculateIKGunMotionOffset()
    end
end

if (SERVER) then
    function ix.arc9.SendPreset(client, weapon, preset, setAmmo)
        if (not IsValid(client) or not client:IsPlayer() or not IsValid(weapon)) then
            return
        end

        local function applyAmmo()
            if (not setAmmo or not weapon.ixItem) then
                return
            end

            if (weapon.ixItem.isGrenade) then
                weapon:SetClip1(1)
            else
                weapon:SetClip1(weapon.ixItem:GetData("ammo", 0))
            end
        end

        local hasPreset = isstring(preset) and preset ~= ""

        ix.arc9.ResetWeaponAttachments(weapon, weapon.ixItem)

        timer.Simple(0.01, function()
            if (not IsValid(client) or not IsValid(weapon)) then
                return
            end

            net.Start("ixARC9SendPreset")
                net.WriteEntity(weapon)
                net.WriteString(hasPreset and preset or "__ix_default__")
            net.Send(client)

            if (hasPreset and isfunction(weapon.PostModify)) then
                weapon:PostModify()
            end

            applyAmmo()
        end)

        return
    end

    function ix.arc9.InitWeapon(client, weapon, itemTable)
        if (not IsValid(client) or not IsValid(weapon) or not ix.arc9.IsARC9Item(itemTable)) then
            return
        end

        ix.arc9.ApplyWorldModelOffset(weapon, itemTable)
        ix.arc9.SendPreset(client, weapon, ix.arc9.GetPreset(itemTable), true)
    end
end

function ix.arc9.GetWeapon(itemTable, client)
    local weapon = itemTable.GetWeapon and itemTable:GetWeapon()

    if (IsValid(weapon)) then
        return weapon
    end

    if (IsValid(client)) then
        weapon = client:GetWeapon(itemTable.class)

        if (IsValid(weapon)) then
            return weapon
        end
    end
end

function ix.arc9.HandleEquippedWeapon(itemTable, client)
    if (not ix.arc9.IsARC9Item(itemTable) or not IsValid(client)) then
        return
    end

    local weapon = ix.arc9.GetWeapon(itemTable, client)

    if (not IsValid(weapon)) then
        return
    end

    weapon.ixItem = itemTable

    if (itemTable.SetWeapon) then
        itemTable:SetWeapon(weapon)
    end

    ix.arc9.ApplyWorldModelOffset(weapon, itemTable)

    if (SERVER) then
        ix.arc9.InitWeapon(client, weapon, itemTable)
    end
end

function ix.arc9.RefreshWeaponItem(itemTable)
    if (not ix.arc9.IsARC9Item(itemTable)) then
        return
    end

    itemTable.isARC9Weapon = true
    itemTable.exRender = false

    local physicsModel = ix.arc9.GetPhysicsModel(itemTable)

    if (isstring(physicsModel) and physicsModel ~= "") then
        itemTable.worldModel = physicsModel
    end
end

function ix.arc9.PatchWeaponItem(itemTable)
    if (not ix.arc9.IsARC9Item(itemTable)) then
        return
    end

    ix.arc9.RefreshWeaponItem(itemTable)

    if (itemTable.ixARC9Patched) then
        return
    end

    itemTable.ixARC9Patched = true

    function itemTable:GetWeapon()
        local weapon = self.weapon

        if (IsValid(weapon)) then
            return weapon
        end

        self.weapon = nil
    end

    function itemTable:SetWeapon(weapon)
        self.weapon = IsValid(weapon) and weapon or nil
    end

    function itemTable:GetPreset()
        return ix.arc9.GetPreset(self)
    end

    local originalOnGetDropModel = itemTable.OnGetDropModel
    itemTable.OnGetDropModel = function(self, entity)
        local model = ix.arc9.GetPhysicsModel(self)

        if (isstring(model) and model ~= "") then
            return model
        end

        if (isfunction(originalOnGetDropModel)) then
            return originalOnGetDropModel(self, entity)
        end
    end

    if (CLIENT) then
        function itemTable:SavePreset()
            local weapon = self:GetWeapon()

            if (IsValid(weapon) and isfunction(weapon.UpdateItemPreset)) then
                weapon:UpdateItemPreset()
            end
        end

        function itemTable:DrawEntity(entity)
            ix.arc9.DrawItemEntity(self, entity, entity)
        end

        local originalOnDataChanged = itemTable.OnDataChanged
        itemTable.OnDataChanged = function(self, key, oldValue, newValue)
            if (isfunction(originalOnDataChanged)) then
                originalOnDataChanged(self, key, oldValue, newValue)
            end

            if ((key == "preset" or key == "bodygroups")) then
                ix.arc9.RefreshWeaponItem(self)

                if (ix.arc9 and ix.arc9.SafeRefreshItemIcon) then
                    ix.arc9.SafeRefreshItemIcon(self.id)
                end
            end
        end
    end

    local originalEquip = itemTable.Equip

    if (isfunction(originalEquip)) then
        itemTable.Equip = function(self, client, bNoSelect, bNoSound)
            local result = originalEquip(self, client, bNoSelect, bNoSound)

            if (SERVER and IsValid(client)) then
                ix.arc9.HandleEquippedWeapon(self, client)
            end

            return result
        end
    end

    local originalUnequip = itemTable.Unequip

    if (isfunction(originalUnequip)) then
        itemTable.Unequip = function(self, client, bPlaySound, bRemoveItem)
            local result = originalUnequip(self, client, bPlaySound, bRemoveItem)
            self:SetWeapon(nil)
            return result
        end
    end
    local originalOnRemoved = itemTable.OnRemoved
    itemTable.OnRemoved = function(self, ...)
        self:SetWeapon(nil)

        if (isfunction(originalOnRemoved)) then
            return originalOnRemoved(self, ...)
        end
    end

    itemTable.OnPostLoadout = function(self, client)
        if (not SERVER) then
            return
        end

        client = IsValid(client) and client or self.player or self:GetOwner()

        if (not IsValid(client) or not self:GetData("equip")) then
            return
        end

        ix.arc9.HandleEquippedWeapon(self, client)
    end
end

function ix.arc9.PatchWeaponItems()
    for _, itemTable in pairs(ix.item.list) do
        ix.arc9.PatchWeaponItem(itemTable)
    end
end

if (CLIENT) then
    ix.arc9.renderModels = ix.arc9.renderModels or {}

    function ix.arc9.OffsetTransform(pos, ang, offsetPos, offsetAng)
        local newPos = Vector(pos.x, pos.y, pos.z)
        local newAng = Angle(ang.p, ang.y, ang.r)

        if (isvector(offsetPos)) then
            newPos = newPos
                + newAng:Forward() * offsetPos.x
                + newAng:Right() * offsetPos.y
                + newAng:Up() * offsetPos.z
        end

        rotateAngle(newAng, offsetAng)

        return newPos, newAng
    end

    function ix.arc9.ApplyModelScale(entity, scale)
        if (not IsValid(entity)) then
            return
        end

        local matrix = Matrix()
        local amount = tonumber(scale) or 1
        matrix:Scale(Vector(amount, amount, amount))
        entity:EnableMatrix("RenderMultiply", matrix)
    end

    function ix.arc9.GetRenderModel(model)
        if (not isstring(model) or model == "") then
            return
        end

        local entity = ix.arc9.renderModels[model]

        if (not IsValid(entity)) then
            entity = ClientsideModel(model, RENDERGROUP_BOTH)

            if (not IsValid(entity)) then
                return
            end

            entity:SetNoDraw(true)
            ix.arc9.renderModels[model] = entity
        end

        if (entity:GetModel() ~= model) then
            entity:SetModel(model)
        end

        return entity
    end

    function ix.arc9.BuildRenderData(itemTable, dataSource)
        if (not ARC9 or not isfunction(ARC9.GetAttTable) or not ix.arc9.IsARC9Item(itemTable)) then
            return
        end

        local slots, swep = ix.arc9.GetItemSlots(itemTable, dataSource)
        local modelInfo = ix.arc9.GetModelInfo(itemTable)

        if (not swep or not modelInfo) then
            return
        end

        local data = {
            attachments = {},
            baseBodygroups = modelInfo.baseBodygroups,
            bodygroups = ix.arc9.GetBodygroups(itemTable, dataSource),
            dropAng = modelInfo.dropAng,
            dropPos = modelInfo.dropPos,
            indexedBodygroups = {},
            managedBodygroups = {},
            material = modelInfo.useProxyModel and swep.VMMaterial or swep.WMMaterial,
            modelScale = modelInfo.modelScale,
            physicsModel = modelInfo.physicsModel,
            poseParams = table.Copy((modelInfo.useProxyModel and swep.DefaultPoseParams) or swep.DefaultWMPoseParams or swep.DefaultPoseParams or {}),
            skin = modelInfo.useProxyModel and swep.DefaultSkin or swep.DefaultWMSkin or swep.DefaultSkin,
            slotMods = {},
            useProxyModel = modelInfo.useProxyModel,
            visualModel = modelInfo.visualModel,
        }

        local function addValues(target, values)
            if (not istable(values)) then
                return
            end

            for _, value in ipairs(values) do
                target[#target + 1] = value
            end
        end

        local function applyDropOverride(offsetOverride)
            if (not istable(offsetOverride)) then
                return
            end

            local pos = offsetOverride.Pos or offsetOverride.pos
            local ang = offsetOverride.Ang or offsetOverride.ang
            local scale = offsetOverride.Scale or offsetOverride.scale

            if (isvector(pos)) then
                data.dropPos = pos
            end

            if (isangle(ang)) then
                data.dropAng = ang
            end

            if (scale ~= nil) then
                data.modelScale = scale
            end
        end

        local function applyElementVisuals(element)
            if (not istable(element)) then
                return
            end

            if (istable(element.Bodygroups)) then
                for _, bodygroup in ipairs(element.Bodygroups) do
                    local index = tonumber(bodygroup[1])

                    if (index ~= nil) then
                        data.indexedBodygroups[index] = tonumber(bodygroup[2]) or 0
                        data.managedBodygroups[index] = true
                    end
                end
            end

            if (istable(poseParams)) then
                for key, value in pairs(poseParams) do
                    if (key ~= "BaseClass") then
                        data.poseParams[key] = value
                    end
                end
            end

            local skin = modelInfo.useProxyModel and element.VMSkin or element.WMSkin or element.VMSkin
            if (skin ~= nil) then
                data.skin = skin
            end

            local material = modelInfo.useProxyModel and element.VMMaterial or element.WMMaterial or element.VMMaterial
            if (material ~= nil) then
                data.material = material
            end
        end

        local activeElementNames = {}

        for _, slot in ipairs(slots or {}) do
            local installed = slot.Installed

            if (not installed) then
                addValues(activeElementNames, slot.DefaultEles)
            else
                if (slot.InstalledEles and installed ~= slot.EmptyFallback) then
                    addValues(activeElementNames, slot.InstalledEles)
                end

                local attTable = ARC9.GetAttTable(installed)

                if (istable(attTable)) then
                    addValues(activeElementNames, attTable.ActivateElements)

                    local toggleNum = slot.ToggleNum or 1
                    local toggleStats = attTable.ToggleStats and attTable.ToggleStats[toggleNum]

                    if (istable(toggleStats)) then
                        addValues(activeElementNames, toggleStats.ActivateElements)
                    end
                end

                activeElementNames[#activeElementNames + 1] = installed
            end
        end

        addValues(activeElementNames, swep.DefaultElements)

        local seenElements = {}

        for _, elementName in ipairs(activeElementNames) do
            if (seenElements[elementName]) then
                continue
            end

            seenElements[elementName] = true
            applyElementVisuals(swep.AttachmentElements and swep.AttachmentElements[elementName])
        end

        local function getSlotAngle(slot, slotMod)
            if (slotMod and isangle(slotMod.ang)) then
                return slotMod.ang
            end

            if (istable(slot.Offset)) then
                local key = modelInfo.useProxyModel and "vang" or "wang"

                if (isangle(slot.Offset[key])) then
                    return slot.Offset[key]
                end
            end

            return slot.Ang
        end

        local function getSlotPos(slot, slotMod)
            if (slotMod and isvector(slotMod.pos)) then
                return slotMod.pos
            end

            if (istable(slot.Offset)) then
                local key = modelInfo.useProxyModel and "vpos" or "wpos"

                if (isvector(slot.Offset[key])) then
                    return slot.Offset[key]
                end
            end

            return slot.Pos
        end

        local function mergeAngles(primary, secondary)
            if (not isangle(primary)) then
                return secondary
            end

            if (not isangle(secondary)) then
                return primary
            end

            return Angle(primary.p + secondary.p, primary.y + secondary.y, primary.r + secondary.r)
        end

        local function collectSlot(slot, slotIndex)
            if (not istable(slot)) then
                return
            end

            for _, elementName in ipairs(activeElementNames) do
                local element = swep.AttachmentElements and swep.AttachmentElements[elementName]
                local attPosMod = istable(element) and istable(element.AttPosMods) and element.AttPosMods[slotIndex]

                if (istable(attPosMod)) then
                    data.slotMods[slotIndex] = data.slotMods[slotIndex] or {}

                    local positionKey = modelInfo.useProxyModel and "vpos" or "wpos"
                    local angleKey = modelInfo.useProxyModel and "vang" or "wang"

                    if (isvector(attPosMod[positionKey])) then
                        data.slotMods[slotIndex].pos = attPosMod[positionKey]
                    end

                    if (isangle(attPosMod[angleKey])) then
                        data.slotMods[slotIndex].ang = attPosMod[angleKey]
                    end

                    if (isstring(attPosMod.bone) and attPosMod.bone ~= "") then
                        data.slotMods[slotIndex].bone = attPosMod.bone
                    end
                end
            end

            local installed = slot.Installed

            if (isstring(installed) and installed ~= "") then
                local attTable = ARC9.GetAttTable(installed)

                if (istable(attTable)) then
                    applyDropOverride(attTable.WorldModelOffsetOverride)

                    local slotMod = data.slotMods[slotIndex]
                    local attachmentBone = (slotMod and slotMod.bone) or slot.Bone

                    if (not modelInfo.useProxyModel and isstring(slot.WMBone) and slot.WMBone ~= "") then
                        attachmentBone = slot.WMBone
                    end

                    if (isstring(attTable.Model) and attTable.Model ~= "" and isstring(attachmentBone)) then
                        data.attachments[#data.attachments + 1] = {
                            ang = getSlotAngle(slot, slotMod),
                            bodygroups = attTable.ModelBodygroups,
                            bone = attachmentBone,
                            material = attTable.ModelMaterial or attTable.Material,
                            model = attTable.Model,
                            modelAngle = mergeAngles(slot.ModelAngleOffset or slot.ModelAng or attTable.ModelAngleOffset or attTable.ModelAng or attTable.ModelOffsetAng, attTable.OffsetAng),
                            modelOffset = slot.ModelOffset or attTable.ModelOffset,
                            pos = getSlotPos(slot, slotMod),
                            scale = slot.ModelScale or attTable.Scale or attTable.ModelScale,
                            skin = attTable.ModelSkin,
                        }
                    end
                end
            end

            for subIndex, subSlot in pairs(slot.SubAttachments or {}) do
                collectSlot(subSlot, subIndex)
            end
        end

        for index, slot in ipairs(slots or {}) do
            collectSlot(slot, index)
        end

        return data
    end

    function ix.arc9.ApplyRenderBodygroups(entity, data)
        if (not IsValid(entity) or not data) then
            return
        end

        for index = 0, entity:GetNumBodyGroups() - 1 do
            entity:SetBodygroup(index, 0)
        end

        applyBodygroupSet(entity, data.baseBodygroups)

        if (istable(data.bodygroups)) then
            for key, value in pairs(data.bodygroups) do
                local index = tonumber(key)

                if (index == nil) then
                    index = entity:FindBodygroupByName(key)
                end

                if (index and index > -1 and not (data.managedBodygroups and data.managedBodygroups[index])) then
                    entity:SetBodygroup(index, tonumber(value) or 0)
                end
            end
        else
            applyBodygroupSet(entity, data.bodygroups)
        end

        for index, value in pairs(data.indexedBodygroups or {}) do
            entity:SetBodygroup(index, value)
        end
    end

    function ix.arc9.ApplyPoseParameters(entity, poseParams)
        if (not IsValid(entity) or not istable(poseParams)) then
            return
        end

        for key, value in pairs(poseParams) do
            if (key ~= "BaseClass") then
                entity:SetPoseParameter(key, value)
            end
        end
    end

    function ix.arc9.ApplyStaticSequence(entity)
        if (not IsValid(entity)) then
            return
        end

        local sequence = entity:LookupSequence("idle")

        if (sequence == nil or sequence < 0) then
            sequence = entity:LookupSequence("ready")
        end

        if (sequence == nil or sequence < 0) then
            sequence = 0
        end

        entity:ResetSequence(sequence)
        entity:SetSequence(sequence)
        entity:SetCycle(0)
    end

    function ix.arc9.ApplyRenderAppearance(entity, itemTable, data, materialSource)
        if (not IsValid(entity) or not data) then
            return
        end

        local skin = data.skin
        local material = data.material

        if (itemTable and itemTable.GetSkin) then
            local itemSkin = itemTable:GetSkin()

            if (itemSkin ~= nil) then
                skin = itemSkin
            end
        end

        if (itemTable and itemTable.GetMaterial) then
            local itemMaterial = itemTable:GetMaterial(materialSource or entity)

            if (itemMaterial ~= nil) then
                material = itemMaterial
            end
        end

        entity:SetSkin(tonumber(skin) or 0)
        entity:SetMaterial(material or "")
        ix.arc9.ApplyPoseParameters(entity, data.poseParams)
    end

    function ix.arc9.GetSlotTransform(entity, attachmentData)
        local pos = entity:GetPos()
        local ang = entity:GetAngles()

        if (isstring(attachmentData.bone) and attachmentData.bone ~= "") then
            local bone = entity:LookupBone(attachmentData.bone)

            if (bone) then
                local matrix = entity:GetBoneMatrix(bone)

                if (matrix) then
                    pos = matrix:GetTranslation()
                    ang = matrix:GetAngles()
                else
                    local bonePos, boneAng = entity:GetBonePosition(bone)

                    if (bonePos and boneAng) then
                        pos = bonePos
                        ang = boneAng
                    end
                end
            end
        end

        return ix.arc9.OffsetTransform(pos, ang, attachmentData.pos, attachmentData.ang)
    end

    function ix.arc9.DrawAttachmentModels(entity, data)
        if (not IsValid(entity) or not data) then
            return
        end

        for _, attachmentData in ipairs(data.attachments or {}) do
            local modelEntity = ix.arc9.GetRenderModel(attachmentData.model)

            if (IsValid(modelEntity)) then
                local pos, ang = ix.arc9.GetSlotTransform(entity, attachmentData)
                pos, ang = ix.arc9.OffsetTransform(pos, ang, attachmentData.modelOffset, attachmentData.modelAngle)

                for index = 0, modelEntity:GetNumBodyGroups() - 1 do
                    modelEntity:SetBodygroup(index, 0)
                end

                applyBodygroupSet(modelEntity, attachmentData.bodygroups)
                modelEntity:SetMaterial(attachmentData.material or "")
                modelEntity:SetSkin(tonumber(attachmentData.skin) or 0)
                ix.arc9.ApplyStaticSequence(modelEntity)
                modelEntity:SetPos(pos)
                modelEntity:SetAngles(ang)
                ix.arc9.ApplyModelScale(modelEntity, attachmentData.scale)
                modelEntity:SetupBones()
                modelEntity:DrawModel()
            end
        end
    end

    function ix.arc9.PrepareVisualProxy(proxyEntity, carrierEntity, itemTable, data)
        if (not IsValid(proxyEntity) or not IsValid(carrierEntity)) then
            return
        end

        local pos, ang = carrierEntity:GetPos(), carrierEntity:GetAngles()
        pos, ang = ix.arc9.OffsetTransform(pos, ang, data.dropPos, data.dropAng)

        proxyEntity:SetPos(pos)
        proxyEntity:SetAngles(ang)
        ix.arc9.ApplyStaticSequence(proxyEntity)
        ix.arc9.ApplyRenderAppearance(proxyEntity, itemTable, data, carrierEntity)
        ix.arc9.ApplyModelScale(proxyEntity, data.modelScale)
    end

    function ix.arc9.DrawItemEntity(itemTable, entity, dataSource)
        local data = ix.arc9.BuildRenderData(itemTable, dataSource)

        if (not data) then
            return false
        end

        local renderEntity = ix.arc9.GetRenderModel(data.visualModel)

        if (not IsValid(renderEntity)) then
            return false
        end

        ix.arc9.PrepareVisualProxy(renderEntity, entity, itemTable, data)
        ix.arc9.ApplyRenderBodygroups(renderEntity, data)
        renderEntity:SetupBones()
        renderEntity:DrawModel()
        ix.arc9.DrawAttachmentModels(renderEntity, data)

        return true
    end

    function ix.arc9.GetIconRenderKey(itemTable)
        local modelInfo = ix.arc9.GetModelInfo(itemTable)
        local layout = ix.arc9.GetIconLayout(itemTable, modelInfo) or {}
        local camera = layout.camera or {}
        local runtime = ix.arc9.BuildRuntimeRenderData and ix.arc9.BuildRuntimeRenderData(itemTable) or nil
        local attachments = {}

        for _, attachment in ipairs((runtime and runtime.attachments) or {}) do
            attachments[#attachments + 1] = {
                address = attachment.slot and attachment.slot.Address,
                duplicate = attachment.duplicate,
                installed = attachment.installed,
                model = attachment.model,
            }
        end

        table.sort(attachments, function(a, b)
            local aKey = tostring(a.address or "") .. ":" .. tostring(a.duplicate or 0) .. ":" .. tostring(a.installed or "")
            local bKey = tostring(b.address or "") .. ":" .. tostring(b.duplicate or 0) .. ":" .. tostring(b.installed or "")
            return aKey < bKey
        end)

        local payload = {
            attachments = attachments,
            bodygroups = ix.arc9.GetBodygroups(itemTable),
            camera = {
                ang = camera.ang,
                fov = camera.fov,
                pos = camera.pos,
            },
            indexedBodygroups = runtime and runtime.indexedBodygroups or nil,
            managedBodygroups = runtime and runtime.managedBodygroups or nil,
            model = modelInfo and modelInfo.visualModel or itemTable:GetModel(),
            physicsModel = modelInfo and modelInfo.physicsModel or "",
            preset = ix.arc9.GetPreset(itemTable) or "",
            renderAng = layout.renderAng,
            renderPos = layout.renderPos,
            skin = runtime and runtime.skin or nil,
        }

        return "arc9_v8_" .. itemTable.uniqueID .. "_" .. util.CRC(util.TableToJSON(payload))
    end
    function ix.arc9.SetupItemIcon(panel, itemTable)
        if (not IsValid(panel) or not ix.arc9.IsARC9Item(itemTable)) then
            return false
        end

        local modelInfo = ix.arc9.GetModelInfo(itemTable)

        if (not modelInfo or not isstring(modelInfo.visualModel) or modelInfo.visualModel == "") then
            return false
        end

        local renderKey = ix.arc9.GetIconRenderKey(itemTable)

        if (panel.arc9IconRenderer and panel.arc9IconRenderKey == renderKey) then
            return true
        end

        panel.arc9IconItemID = itemTable.id
        panel.arc9IconModel = modelInfo.visualModel
        panel.arc9IconRenderKey = renderKey

        local modelPanel = IsValid(panel.Icon) and panel.Icon or panel:GetChild(0)

        if (IsValid(modelPanel)) then
            if (modelPanel.SetModel) then
                modelPanel:SetModel(modelInfo.visualModel, itemTable.GetSkin and itemTable:GetSkin() or 0)
            end

            modelPanel:SetVisible(false)
        end

        panel.arc9IconRenderer = true
        panel.ExtraPaint = function(this, width, height)
            local renderKey = this.arc9IconRenderKey or ix.arc9.GetIconRenderKey(itemTable)
            local icon = ikon:GetIcon(renderKey)

            if (icon) then
                surface.SetMaterial(icon)
                surface.SetDrawColor(color_white)
                surface.DrawTexturedRect(0, 0, width, height)
                return
            end

            local data = ix.arc9.BuildRenderData(itemTable)
            local iconCam = table.Copy(ix.arc9.GetIconCam(itemTable, modelInfo) or {})

            iconCam.drawHook = function(entity)
                if (not data) then
                    return
                end

                ix.arc9.ApplyStaticSequence(entity)
                ix.arc9.ApplyRenderAppearance(entity, itemTable, data, entity)
                ix.arc9.ApplyModelScale(entity, data.modelScale)
                ix.arc9.ApplyRenderBodygroups(entity, data)
                entity:SetupBones()
                ix.arc9.DrawAttachmentModels(entity, data)
            end

            ikon:renderIcon(
                renderKey,
                itemTable.width,
                itemTable.height,
                modelInfo.visualModel,
                iconCam
            )
        end

        return true
    end

    local boneVisibleScale = Vector(1, 1, 1)
    local boneHiddenScale = Vector(0, 0, 0)

    local function copyVector(value)
        if (not isvector(value)) then
            return
        end

        return Vector(value.x, value.y, value.z)
    end

    local function copyAngle(value)
        if (not isangle(value)) then
            return
        end

        return Angle(value.p, value.y, value.r)
    end

    local function addElements(target, source)
        if (not source) then
            return
        end

        if (isstring(source)) then
            if (source ~= "") then
                target[source] = true
            end

            return
        end

        if (not istable(source)) then
            return
        end

        for key, value in pairs(source) do
            local element = isnumber(key) and value or (value == true and key or nil)

            if (isstring(element) and element ~= "") then
                target[element] = true
            end
        end
    end

    local function getARC9BaseValue(swep, key)
        local seen = {}
        local current = swep

        while (istable(current)) do
            local value = rawget(current, key)

            if (value ~= nil) then
                return value
            end

            local baseName = rawget(current, "Base")

            if (not isstring(baseName) or baseName == "" or seen[baseName]) then
                break
            end

            seen[baseName] = true
            current = weapons.GetStored(baseName)
        end

        local arc9Base = weapons.GetStored("arc9_base")

        if (istable(arc9Base)) then
            return rawget(arc9Base, key)
        end
    end

    local function buildRenderContext(itemTable, dataSource)
        local swep = ix.arc9.GetWeaponTable(itemTable)

        if (not swep or not istable(swep.Attachments)) then
            return
        end

        local installTree = getFreshAttachmentTree(itemTable, swep)

        if (not istable(installTree)) then
            return
        end

        local presetTable = ix.arc9.GetPresetTable(itemTable.class, ix.arc9.GetPreset(itemTable, dataSource) or "")

        if (presetTable) then
            stripAttachmentTree(installTree)
            ix.arc9.ApplyPresetToSlots(installTree, presetTable)
        end
        local context = {
            Attachments = table.Copy(installTree),
            AttachmentTableOverrides = table.Copy(swep.AttachmentTableOverrides or {}),
            AttPosCache = {},
            ElementTablesCache = nil,
            ElementsCache = nil,
            WorldModelOffset = ix.arc9.GetConfiguredWorldModelOffset(itemTable) or table.Copy(swep.WorldModelOffset or {}),
        }

        setmetatable(context, {
            __index = function(_, key)
                return getARC9BaseValue(swep, key)
            end,
        })

        function context:GetElements(exclude)
            if (not exclude and self.ElementsCache) then
                return self.ElementsCache
            end

            local elements = {}

            for _, slot in ipairs(self:GetSubSlotList() or {}) do
                if (exclude and slot.Address and exclude[slot.Address]) then
                    continue
                end

                if (slot.Installed) then
                    addElements(elements, slot.InstalledElements)
                    addElements(elements, slot.Installed)

                    local atttbl = self:GetFinalAttTable(slot)
                    addElements(elements, atttbl.ActivateElements)
                    addElements(elements, atttbl.Category)
                else
                    addElements(elements, slot.UnInstalledElements)
                end
            end

            addElements(elements, self.DefaultElements)

            if (not exclude) then
                self.ElementsCache = elements
            end

            return elements
        end

        function context:GetAttachmentElements()
            if (self.ElementTablesCache) then
                return self.ElementTablesCache
            end

            local result = {}
            local seen = {}
            local elements = self:GetElements()

            for name in pairs(elements) do
                local element = self.AttachmentElements and self.AttachmentElements[name]

                if (istable(element) and not seen[element]) then
                    seen[element] = true
                    result[#result + 1] = element
                end
            end

            for _, slot in ipairs(self:GetSubSlotList() or {}) do
                local atttbl = self:GetFinalAttTable(slot)

                if (istable(atttbl.Element) and not seen[atttbl.Element]) then
                    seen[atttbl.Element] = true
                    result[#result + 1] = atttbl.Element
                end
            end

            self.ElementTablesCache = result

            return result
        end

        if (isfunction(context.BuildSubAttachments)) then
            context:BuildSubAttachments(installTree)
        else
            context.Attachments = installTree
        end

        return context, swep
    end

    local function collectActiveElements(context)
        local elements = {}

        for _, slot in ipairs(context:GetSubSlotList() or {}) do
            if (slot.Installed) then
                addElements(elements, slot.InstalledElements)
                addElements(elements, slot.Installed)

                local atttbl = context:GetFinalAttTable(slot)
                addElements(elements, atttbl.ActivateElements)
                addElements(elements, atttbl.Category)
            else
                addElements(elements, slot.UnInstalledElements)
            end
        end

        addElements(elements, context.DefaultElements)

        return elements
    end

    local function collectAttachmentElements(context, activeElements)
        local result = {}
        local seen = {}

        for name in pairs(activeElements or {}) do
            local element = context.AttachmentElements and context.AttachmentElements[name]

            if (istable(element) and not seen[element]) then
                seen[element] = true
                result[#result + 1] = element
            end
        end

        for _, slot in ipairs(context:GetSubSlotList() or {}) do
            local atttbl = context:GetFinalAttTable(slot)

            if (istable(atttbl.Element) and not seen[atttbl.Element]) then
                seen[atttbl.Element] = true
                result[#result + 1] = atttbl.Element
            end
        end

        return result
    end

    local function resolveStaticSequence(entity, swep)
        if (not IsValid(entity)) then
            return 0
        end

        local source

        if (istable(swep) and istable(swep.Animations)) then
            local animation = swep.Animations["idle"] or swep.Animations["ready"] or swep.Animations["draw"]
            source = animation and animation.Source
        end

        if (istable(source)) then
            source = source[1]
        end

        local sequence = isnumber(source) and source or -1

        if (sequence < 0 and isstring(source) and source ~= "") then
            sequence = entity:LookupSequence(source)
        end

        if (sequence == nil or sequence < 0) then
            sequence = entity:LookupSequence("idle")
        end

        if (sequence == nil or sequence < 0) then
            sequence = entity:LookupSequence("ready")
        end

        if (sequence == nil or sequence < 0) then
            sequence = 0
        end

        return sequence
    end

    local function getBoneTransform(entity, boneName, fallbackPos, fallbackAng)
        local pos = copyVector(fallbackPos) or vector_origin
        local ang = copyAngle(fallbackAng) or angle_zero

        if (not IsValid(entity)) then
            return pos, ang
        end

        entity:SetupBones()

        if (isstring(boneName) and boneName ~= "") then
            local bone = entity:LookupBone(boneName)

            if (bone and bone > -1) then
                local matrix = entity:GetBoneMatrix(bone)

                if (matrix) then
                    return matrix:GetTranslation(), matrix:GetAngles()
                end

                local bonePos, boneAng = entity:GetBonePosition(bone)

                if (isvector(bonePos) and isangle(boneAng)) then
                    return bonePos, boneAng
                end
            end
        end

        return copyVector(entity:GetPos()) or pos, copyAngle(entity:GetAngles()) or ang
    end

    local function getAttachmentTransform(context, slottbl, parentEntity, customPos, customAng, duplicate, attachmentElements)
        if (not istable(slottbl)) then
            return vector_origin, angle_zero
        end

        duplicate = tonumber(duplicate) or 0

        local atttbl = slottbl.Installed and context:GetFinalAttTable(slottbl) or {}
        local boneName = slottbl.Bone
        local offsetPos = copyVector(slottbl.Pos) or vector_origin
        local offsetAng = copyAngle(slottbl.Ang) or angle_zero
        local slotScale = tonumber(slottbl.Scale) or 1

        if (slottbl.WMBase) then
            boneName = "ValveBiped.Bip01_R_Hand"
        end

        if (duplicate > 0 and istable(slottbl.DuplicateModels) and istable(slottbl.DuplicateModels[duplicate])) then
            local duplicateData = slottbl.DuplicateModels[duplicate]

            if (isvector(duplicateData.Pos)) then
                offsetPos = copyVector(duplicateData.Pos)
            end

            if (isangle(duplicateData.Ang)) then
                offsetAng = copyAngle(duplicateData.Ang)
            end

            if (isstring(duplicateData.Bone) and duplicateData.Bone ~= "") then
                boneName = duplicateData.Bone
            end

            slotScale = slotScale * (tonumber(duplicateData.Scale) or 1)
        end

        if (slottbl.OriginalAddress) then
            for _, element in ipairs(attachmentElements or {}) do
                local mods = element.AttPosMods or {}
                local mod = mods[slottbl.OriginalAddress]

                if (istable(mod)) then
                    if (isvector(mod.Pos)) then
                        offsetPos = copyVector(mod.Pos)
                    end

                    if (isangle(mod.Ang)) then
                        offsetAng = copyAngle(mod.Ang)
                    end
                end
            end
        end

        local worldScale = (context.WorldModelOffset and tonumber(context.WorldModelOffset.Scale)) or 1
        offsetPos = offsetPos * worldScale

        local basePos, baseAng = getBoneTransform(parentEntity, boneName, customPos, customAng)
        local drawPos = copyVector(basePos) or vector_origin
        local drawAng = copyAngle(baseAng) or angle_zero

        drawPos = drawPos
            + drawAng:Forward() * offsetPos.x
            + drawAng:Right() * offsetPos.y
            + drawAng:Up() * offsetPos.z

        local appliedAng = copyAngle(offsetAng) or angle_zero
        local modelAngleOffset = copyAngle(atttbl.ModelAngleOffset)

        if (modelAngleOffset) then
            appliedAng = Angle(
                appliedAng.p + modelAngleOffset.p,
                appliedAng.y + modelAngleOffset.y,
                appliedAng.r + modelAngleOffset.r
            )
        end

        local forward = drawAng:Forward()
        local right = drawAng:Right()
        local up = drawAng:Up()

        drawAng:RotateAroundAxis(forward, appliedAng.r)
        drawAng:RotateAroundAxis(right, appliedAng.p)
        drawAng:RotateAroundAxis(up, appliedAng.y)

        local modelOffset = copyVector(atttbl.ModelOffset) or vector_origin
        modelOffset = modelOffset * slotScale * worldScale

        drawPos = drawPos
            + drawAng:Forward() * modelOffset.x
            + drawAng:Right() * modelOffset.y
            + drawAng:Up() * modelOffset.z

        return drawPos, drawAng
    end

    function ix.arc9.BuildRuntimeRenderData(itemTable, dataSource)
        if (not ARC9 or not isfunction(ARC9.GetAttTable) or not ix.arc9.IsARC9Item(itemTable)) then
            return
        end

        local context, swep = buildRenderContext(itemTable, dataSource)
        local modelInfo = ix.arc9.GetModelInfo(itemTable)

        if (not context or not swep or not modelInfo) then
            return
        end

        local activeElements = collectActiveElements(context)
        local attachmentElements = collectAttachmentElements(context, activeElements)
        local worldModelOffset = table.Copy(context.WorldModelOffset or swep.WorldModelOffset or {})
        local droppedOffset = ix.arc9.GetConfiguredDroppedModelOffset(itemTable) or {
            Pos = Vector(0, 0, 0),
            Ang = Angle(0, 0, 0),
            Scale = 1,
        }

        local runtime = {
            anchorToCarrierBone = modelInfo.useProxyModel and swep.MirrorVMWM and true or false,
            attachmentElements = attachmentElements,
            attachments = {},
            baseBodygroups = getBodygroupSeed(swep, normalizeModel(modelInfo.visualModel) == normalizeModel(getMirrorModel(swep))),
            bodygroups = ix.arc9.GetBodygroups(itemTable, dataSource),
            context = context,
            droppedOffset = table.Copy(droppedOffset),
            hiddenBones = {},
            iconScale = tonumber(worldModelOffset.Scale) or 1,
            indexedBodygroups = {},
            managedBodygroups = {},
            modelScale = (tonumber(worldModelOffset.Scale) or 1) * (tonumber(droppedOffset.Scale) or 1),
            physicsModel = modelInfo.physicsModel,
            skin = swep.DefaultSkin or 0,
            swep = swep,
            visualModel = modelInfo.visualModel,
            worldModelOffset = worldModelOffset,
        }

        local function applyDropOverride(offsetOverride)
            if (not istable(offsetOverride)) then
                return
            end

            if (isvector(offsetOverride.Pos)) then
                runtime.droppedOffset.Pos = copyVector(offsetOverride.Pos)
            end

            if (isangle(offsetOverride.Ang)) then
                runtime.droppedOffset.Ang = copyAngle(offsetOverride.Ang)
            end

            if (offsetOverride.Scale ~= nil) then
                runtime.droppedOffset.Scale = tonumber(offsetOverride.Scale) or runtime.droppedOffset.Scale
                runtime.modelScale = (tonumber(worldModelOffset.Scale) or 1) * (tonumber(runtime.droppedOffset.Scale) or 1)
            end
        end

        for _, element in ipairs(attachmentElements) do
            for _, bodygroup in ipairs(element.Bodygroups or {}) do
                local index = tonumber(bodygroup[1])

                if (index ~= nil) then
                    runtime.indexedBodygroups[index] = tonumber(bodygroup[2]) or 0
                    runtime.managedBodygroups[index] = true
                end
            end

            if (element.Skin ~= nil) then
                runtime.skin = element.Skin
            end
        end

        for _, boneName in ipairs(swep.HideBones or {}) do
            runtime.hiddenBones[boneName] = true
        end

        for _, slot in ipairs(context:GetSubSlotList() or {}) do
            if (slot.Installed and not slot.NoDraw) then
                local atttbl = context:GetFinalAttTable(slot)

                if (istable(atttbl) and not atttbl.NoDraw) then
                    applyDropOverride(atttbl.WorldModelOffsetOverride)

                    local model = (isstring(atttbl.WorldModel) and atttbl.WorldModel ~= "" and atttbl.WorldModel) or atttbl.Model

                    if (isstring(model) and model ~= "") then
                        local duplicateCount = 0

                        if (istable(slot.DuplicateModels)) then
                            duplicateCount = #slot.DuplicateModels
                        end

                        for duplicate = 0, duplicateCount do
                            runtime.attachments[#runtime.attachments + 1] = {
                                atttbl = atttbl,
                                duplicate = duplicate,
                                installed = slot.Installed,
                                model = model,
                                slot = slot,
                            }
                        end
                    end
                end
            end
        end

        return runtime
    end

    function ix.arc9.BuildRenderData(itemTable, dataSource)
        local runtime = ix.arc9.BuildRuntimeRenderData(itemTable, dataSource)

        if (not runtime) then
            return
        end

        local attachments = {}

        for _, attachment in ipairs(runtime.attachments or {}) do
            attachments[#attachments + 1] = {
                address = attachment.slot and attachment.slot.Address,
                duplicate = attachment.duplicate,
                installed = attachment.installed,
                model = attachment.model,
            }
        end

        return {
            anchorToCarrierBone = runtime.anchorToCarrierBone,
            attachments = attachments,
            droppedOffset = runtime.droppedOffset,
            iconScale = runtime.iconScale,
            indexedBodygroups = runtime.indexedBodygroups,
            modelScale = runtime.modelScale,
            physicsModel = runtime.physicsModel,
            skin = runtime.skin,
            visualModel = runtime.visualModel,
            worldModelOffset = runtime.worldModelOffset,
        }
    end

    function ix.arc9.ApplyStaticSequence(entity, sequenceSource)
        if (not IsValid(entity)) then
            return
        end

        local sequence = nil

        if (istable(sequenceSource) and sequenceSource.swep) then
            sequence = resolveStaticSequence(entity, sequenceSource.swep)
        elseif (isnumber(sequenceSource)) then
            sequence = sequenceSource
        end

        if (sequence == nil or sequence < 0) then
            sequence = resolveStaticSequence(entity)
        end

        entity:ResetSequence(sequence)
        entity:SetSequence(sequence)
        entity:SetCycle(0)
    end

    function ix.arc9.ApplyRenderBones(entity, runtime)
        if (not IsValid(entity)) then
            return
        end

        local boneCount = entity:GetBoneCount() or 0

        for bone = 0, boneCount - 1 do
            entity:ManipulateBoneScale(bone, boneVisibleScale)
        end

        for boneName in pairs(runtime and runtime.hiddenBones or {}) do
            local bone = isnumber(boneName) and boneName or entity:LookupBone(boneName)

            if (bone and bone > -1) then
                entity:ManipulateBoneScale(bone, boneHiddenScale)
            end
        end
    end

    function ix.arc9.DrawAttachmentModels(entity, runtime)
        if (not IsValid(entity) or not runtime) then
            return
        end

        for _, attachment in ipairs(runtime.attachments or {}) do
            local modelEntity = ix.arc9.GetRenderModel(attachment.model)

            if (IsValid(modelEntity)) then
                local pos, ang = getAttachmentTransform(
                    runtime.context,
                    attachment.slot,
                    entity,
                    nil,
                    nil,
                    attachment.duplicate,
                    runtime.attachmentElements
                )

                for index = 0, modelEntity:GetNumBodyGroups() - 1 do
                    modelEntity:SetBodygroup(index, 0)
                end

                applyBodygroupSet(modelEntity, attachment.atttbl.ModelBodygroups)
                modelEntity:SetMaterial(attachment.atttbl.ModelMaterial or "")
                modelEntity:SetSkin(tonumber(attachment.atttbl.ModelSkin) or 0)
                modelEntity:SetPos(pos)
                modelEntity:SetAngles(ang)

                local modelScale = (tonumber(runtime.worldModelOffset.Scale) or 1)
                    * (tonumber(attachment.slot.Scale) or 1)
                    * (tonumber(attachment.atttbl.Scale) or 1)

                if (attachment.duplicate > 0 and istable(attachment.slot.DuplicateModels) and istable(attachment.slot.DuplicateModels[attachment.duplicate])) then
                    modelScale = modelScale * (tonumber(attachment.slot.DuplicateModels[attachment.duplicate].Scale) or 1)
                end

                ix.arc9.ApplyModelScale(modelEntity, modelScale)
                modelEntity:SetupBones()
                modelEntity:DrawModel()
            end
        end
    end

    function ix.arc9.PrepareVisualProxy(proxyEntity, carrierEntity, itemTable, runtime)
        if (not IsValid(proxyEntity) or not IsValid(carrierEntity) or not runtime) then
            return
        end

        local pos = copyVector(carrierEntity:GetPos()) or vector_origin
        local ang = copyAngle(carrierEntity:GetAngles()) or angle_zero

        if (runtime.anchorToCarrierBone) then
            pos, ang = getAttachmentTransform(
                runtime.context,
                {
                    WMBase = true,
                    Pos = copyVector(runtime.worldModelOffset.Pos) or vector_origin,
                    Ang = copyAngle(runtime.worldModelOffset.Ang) or Angle(-5, 0, 180),
                },
                carrierEntity,
                nil,
                nil,
                0,
                runtime.attachmentElements
            )
        end

        pos, ang = ix.arc9.OffsetTransform(pos, ang, runtime.droppedOffset.Pos, runtime.droppedOffset.Ang)

        proxyEntity:SetPos(pos)
        proxyEntity:SetAngles(ang)
        ix.arc9.ApplyStaticSequence(proxyEntity, runtime)
        ix.arc9.ApplyRenderAppearance(proxyEntity, itemTable, runtime, carrierEntity)
        ix.arc9.ApplyModelScale(proxyEntity, runtime.modelScale)
        ix.arc9.ApplyRenderBodygroups(proxyEntity, runtime)
        ix.arc9.ApplyRenderBones(proxyEntity, runtime)
    end

    function ix.arc9.DrawItemEntity(itemTable, entity, dataSource)
        local runtime = ix.arc9.BuildRuntimeRenderData(itemTable, dataSource)

        if (not runtime) then
            return false
        end

        local renderEntity = ix.arc9.GetRenderModel(runtime.visualModel)

        if (not IsValid(renderEntity)) then
            return false
        end

        ix.arc9.PrepareVisualProxy(renderEntity, entity, itemTable, runtime)
        renderEntity:SetupBones()
        renderEntity:DrawModel()
        ix.arc9.DrawAttachmentModels(renderEntity, runtime)

        return true
    end

    function ix.arc9.SetupItemIcon(panel, itemTable)
        if (not IsValid(panel) or not ix.arc9.IsARC9Item(itemTable)) then
            return false
        end

        local modelInfo = ix.arc9.GetModelInfo(itemTable)

        if (not modelInfo or not isstring(modelInfo.visualModel) or modelInfo.visualModel == "") then
            return false
        end

        local renderKey = ix.arc9.GetIconRenderKey(itemTable)

        if (panel.arc9IconRenderer and panel.arc9IconRenderKey == renderKey) then
            return true
        end

        panel.arc9IconItemID = itemTable.id
        panel.arc9IconModel = modelInfo.visualModel
        panel.arc9IconRenderKey = renderKey

        local modelPanel = IsValid(panel.Icon) and panel.Icon or panel:GetChild(0)

        if (IsValid(modelPanel)) then
            if (modelPanel.SetModel) then
                modelPanel:SetModel(modelInfo.visualModel, itemTable.GetSkin and itemTable:GetSkin() or 0)
            end

            if (modelPanel.SetPaintedManually) then
                modelPanel:SetPaintedManually(true)
            end

            modelPanel:SetVisible(false)
        end

        if (not panel.arc9OriginalThink) then
            panel.arc9OriginalThink = panel.Think
        end

        panel.arc9IconRenderer = true
        panel.Think = function(this, ...)
            local innerPanel = IsValid(this.Icon) and this.Icon or this:GetChild(0)

            if (IsValid(innerPanel)) then
                if (innerPanel.SetPaintedManually) then
                    innerPanel:SetPaintedManually(true)
                end

                innerPanel:SetVisible(false)
            end

            if (isfunction(this.arc9OriginalThink)) then
                this.arc9OriginalThink(this, ...)
            end
        end

        panel.ExtraPaint = function(this, width, height)
            local renderKey = this.arc9IconRenderKey or ix.arc9.GetIconRenderKey(itemTable)
            local icon = ikon:GetIcon(renderKey)

            if (icon) then
                surface.SetMaterial(icon)
                surface.SetDrawColor(color_white)
                surface.DrawTexturedRect(0, 0, width, height)
                return
            end

            local runtime = ix.arc9.BuildRuntimeRenderData(itemTable)
            local iconLayout = ix.arc9.GetIconLayout(itemTable, modelInfo) or {}
            local iconCam = table.Copy(iconLayout.camera or {})

            iconCam.drawHook = function(entity)
                if (not runtime or not IsValid(entity)) then
                    return
                end

                entity:SetPos(copyIconVector(iconLayout.renderPos))
                entity:SetAngles(copyIconAngle(iconLayout.renderAng))
                ix.arc9.ApplyStaticSequence(entity, runtime)
                ix.arc9.ApplyRenderAppearance(entity, itemTable, runtime, entity)
                ix.arc9.ApplyModelScale(entity, runtime.iconScale)
                ix.arc9.ApplyRenderBodygroups(entity, runtime)
                ix.arc9.ApplyRenderBones(entity, runtime)
                entity:SetupBones()

                entity.RenderOverride = function(self)
                    local override = self.RenderOverride
                    self.RenderOverride = nil
                    self:DrawModel()
                    self.RenderOverride = override
                    ix.arc9.DrawAttachmentModels(self, runtime)
                end
            end

            ikon:renderIcon(
                renderKey,
                itemTable.width or 1,
                itemTable.height or 1,
                modelInfo.visualModel,
                iconCam
            )
        end

        return true
    end
end

    function ix.arc9.DumpTraceData()
        local client = LocalPlayer()

        if (not IsValid(client)) then
            return false, "invalid client"
        end

        local trace = client:GetEyeTraceNoCursor()
        local entity = trace.Entity

        if (not IsValid(entity)) then
            return false, "no entity"
        end

        local payload = {
            class = entity:GetClass(),
            entityAngles = tostring(entity:GetAngles()),
            entityModel = entity:GetModel(),
            entityPos = tostring(entity:GetPos()),
            itemID = entity.ixItemID,
        }

        if (entity.GetItemTable) then
            local itemTable = entity:GetItemTable()

            if (itemTable) then
                payload.itemClass = itemTable.class
                payload.itemModel = itemTable.model
                payload.isARC9Item = ix.arc9.IsARC9Item(itemTable)
                payload.modelInfo = ix.arc9.GetModelInfo(itemTable)
                payload.renderData = ix.arc9.BuildRenderData(itemTable, entity)
            end
        end

        local path = string.format("helix/%s/%s/arc9_support.txt", Schema and Schema.folder or "schema", game.GetMap())
        file.CreateDir(string.format("helix/%s/%s", Schema and Schema.folder or "schema", game.GetMap()))
        file.Write(path, util.TableToJSON(payload, true) or "{}")

        return true, path
    end




































