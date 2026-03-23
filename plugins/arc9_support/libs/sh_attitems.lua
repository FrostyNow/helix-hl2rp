ix.arc9 = ix.arc9 or {}
ix.arc9.attachmentItems = ix.arc9.attachmentItems or {}
ix.arc9.attachmentItemSources = ix.arc9.attachmentItemSources or {}

local defaultAttachmentModel = "models/mosi/fallout4/props/junk/modcrate.mdl"

local function getAttachmentTable(att)
    if (not ARC9 or not isstring(att) or att == "" or not isfunction(ARC9.GetAttTable)) then
        return
    end

    local atttbl = ARC9.GetAttTable(att)

    if (not istable(atttbl) or atttbl.Ignore) then
        return
    end

    return atttbl
end

local function getInventoryForClient(client)
    if (not IsValid(client) or not client:IsPlayer()) then
        return
    end

    local character = client:GetCharacter()
    return character and character:GetInventory() or nil
end

local function getAttachmentItemModel(atttbl)
    if (not istable(atttbl)) then
        return defaultAttachmentModel
    end

    local candidates = {
        atttbl.BoxModel,
        atttbl.WorldModel,
        atttbl.Model,
    }

    for _, model in ipairs(candidates) do
        if (isstring(model) and model ~= "") then
            return model
        end
    end

    return defaultAttachmentModel
end

local function getAttachmentItemName(att, atttbl)
    if (ARC9 and isfunction(ARC9.GetPhraseForAtt)) then
        local phrase = ARC9:GetPhraseForAtt(att, "PrintName") or ARC9:GetPhraseForAtt(att, "CompactName")

        if (isstring(phrase) and phrase ~= "") then
            return phrase
        end
    end

    if (istable(atttbl)) then
        if (isstring(atttbl.PrintName) and atttbl.PrintName ~= "") then
            return atttbl.PrintName
        end

        if (isstring(atttbl.CompactName) and atttbl.CompactName ~= "") then
            return atttbl.CompactName
        end
    end

    return att
end

local function getAttachmentItemDescription(atttbl)
    if (not istable(atttbl) or not isstring(atttbl.Description) or atttbl.Description == "") then
        return "An ARC9 weapon attachment."
    end

    return atttbl.Description
end

function ix.arc9.GetInventoryAttachmentID(att)
    local atttbl = getAttachmentTable(att)

    if (not atttbl) then
        return
    end

    if (isstring(atttbl.InvAtt) and atttbl.InvAtt ~= "") then
        return atttbl.InvAtt
    end

    return att
end

function ix.arc9.GetAttachmentItemID(att)
    local inventoryAtt = ix.arc9.GetInventoryAttachmentID(att) or att
    return ix.arc9.attachmentItems[inventoryAtt]
end

function ix.arc9.RegisterAttachmentItemBase()
    local itemTable = ix.item.Register("base_arc9_attachment", nil, true, nil, true)

    itemTable.name = "ARC9 Attachment"
    itemTable.description = "An ARC9 weapon attachment."
    itemTable.category = "ARC9 Attachments"
    itemTable.model = defaultAttachmentModel
    itemTable.width = 1
    itemTable.height = 1
    itemTable.isARC9Attachment = true
    itemTable.noBusiness = true

    if (CLIENT) then
        function itemTable:PopulateTooltip(tooltip)
            local attachmentID = self.arc9AttachmentID or self:GetData("arc9AttachmentID")

            if (not isstring(attachmentID) or attachmentID == "") then
                return
            end

            local row = tooltip:AddRow("arc9AttachmentID")
            row:SetText(attachmentID)
            row:SizeToContents()
        end
    end

    return itemTable
end

function ix.arc9.RegisterAttachmentItems(force)
    if (not ARC9 or not istable(ARC9.Attachments)) then
        return false
    end

    ix.arc9.RegisterAttachmentItemBase()

    if (force) then
        ix.arc9.attachmentItems = {}
        ix.arc9.attachmentItemSources = {}
    end

    local representatives = {}

    for att in pairs(ARC9.Attachments) do
        local atttbl = getAttachmentTable(att)

        if (atttbl and not atttbl.Free) then
            local inventoryAtt = ix.arc9.GetInventoryAttachmentID(att)

            if (inventoryAtt and not representatives[inventoryAtt]) then
                representatives[inventoryAtt] = att
            end
        end
    end

    for inventoryAtt, sourceAtt in pairs(representatives) do
        local atttbl = getAttachmentTable(sourceAtt)

        if (atttbl) then
            local itemID = ix.arc9.attachmentItems[inventoryAtt] or ("arc9att_" .. util.CRC(inventoryAtt))
            local itemTable = ix.item.Register(itemID, "base_arc9_attachment", false, nil, true)

            itemTable.name = getAttachmentItemName(sourceAtt, atttbl)
            itemTable.description = getAttachmentItemDescription(atttbl)
            itemTable.category = "ARC9 Attachments"
            itemTable.model = getAttachmentItemModel(atttbl)
            itemTable.width = 1
            itemTable.height = 1
            itemTable.arc9AttachmentID = inventoryAtt
            itemTable.arc9SourceAttachmentID = sourceAtt
            itemTable.isARC9Attachment = true
            itemTable.noBusiness = true

            ix.arc9.attachmentItems[inventoryAtt] = itemID
            ix.arc9.attachmentItemSources[inventoryAtt] = sourceAtt
        end
    end

    return true
end

function ix.arc9.CountAttachmentItems(client, att)
    local inventoryAtt = ix.arc9.GetInventoryAttachmentID(att)
    local itemID = inventoryAtt and ix.arc9.attachmentItems[inventoryAtt]
    local inventory = getInventoryForClient(client)

    if (not itemID or not inventory) then
        return 0
    end

    local count = 0

    for _, item in pairs(inventory:GetItemsByUniqueID(itemID) or {}) do
        if (item and not item.bPendingRemoval) then
            count = count + 1
        end
    end

    return count
end

function ix.arc9.TakeAttachmentItems(client, att, amount)
    if (CLIENT) then
        return false
    end

    amount = math.max(tonumber(amount) or 1, 0)

    if (amount == 0) then
        return true
    end

    local inventoryAtt = ix.arc9.GetInventoryAttachmentID(att)
    local itemID = inventoryAtt and ix.arc9.attachmentItems[inventoryAtt]
    local inventory = getInventoryForClient(client)

    if (not itemID or not inventory) then
        return false
    end

    local items = inventory:GetItemsByUniqueID(itemID) or {}

    if (#items < amount) then
        return false
    end

    for index = 1, amount do
        local item = items[index]

        if (not item or item:Remove() == false) then
            return false
        end
    end

    return true
end

function ix.arc9.GiveAttachmentItems(client, att, amount)
    if (CLIENT) then
        return false
    end

    amount = math.max(tonumber(amount) or 1, 0)

    if (amount == 0) then
        return true
    end

    local inventoryAtt = ix.arc9.GetInventoryAttachmentID(att)
    local itemID = inventoryAtt and ix.arc9.attachmentItems[inventoryAtt]
    local inventory = getInventoryForClient(client)
    local itemTable = itemID and ix.item.list[itemID]
    local droppedAny = false

    if (not itemID or not itemTable) then
        return false
    end

    for _ = 1, amount do
        local added = false

        if (inventory) then
            local x, y = inventory:FindEmptySlot(itemTable.width, itemTable.height)

            if (x and y) then
                local result = inventory:Add(itemID, 1, nil, x, y)
                added = result != false
            end
        end

        if (not added) then
            ix.item.Spawn(itemID, client)
            droppedAny = true
        end
    end

    return true, droppedAny
end
