local PLUGIN = PLUGIN
local retryTimer = "ixARC9SupportRetry"

local function patchARC9Items()
    if (ix.arc9 and ix.arc9.PatchWeaponItems) then
        ix.arc9.PatchWeaponItems()
    end
end

local function patchARC9BaseSWEP()
    local swep = weapons.GetStored("arc9_base")

    if (not swep) then
        return false
    end

    if (swep.ixARC9SupportPatched) then
        return true
    end

    swep.ixARC9SupportPatched = true

    if (CLIENT) then
        function swep:UpdateItemPreset()
            local client = LocalPlayer()
            local character = IsValid(client) and client:GetCharacter()

            if (not character) then
                return
            end

            net.Start("ixARC9UpdatePreset")
                net.WriteUInt(character:GetID(), 32)
                net.WriteUInt(self:EntIndex(), 32)
                net.WriteString(self:GeneratePresetExportCode())
            net.SendToServer()
        end

        local originalPostModify = swep.PostModify

        if (isfunction(originalPostModify)) then
            function swep:PostModify(...)
                local results = {originalPostModify(self, ...)}
                local owner = self.GetOwner and self:GetOwner()

                if (not self.ixARC9BlockPresetUpdate and IsValid(owner) and owner == LocalPlayer() and isfunction(self.UpdateItemPreset)) then
                    self:UpdateItemPreset()
                end

                return unpack(results)
            end
        end

        local originalLoadPreset = swep.LoadPreset

        if (isfunction(originalLoadPreset)) then
            function swep:LoadPreset(...)
                local results = {originalLoadPreset(self, ...)}
                local owner = self.GetOwner and self:GetOwner()

                if (not self.ixARC9BlockPresetUpdate and IsValid(owner) and owner == LocalPlayer() and isfunction(self.UpdateItemPreset)) then
                    self:UpdateItemPreset()
                end

                return unpack(results)
            end
        end
    end

    return true
end

local function initializeARC9Support()
    local attachmentItemsReady = true

    if (ix.arc9 and ix.arc9.CacheAttachmentTemplates) then
        ix.arc9.CacheAttachmentTemplates(true)
    end

    if (ix.arc9 and ix.arc9.RegisterAttachmentItems) then
        attachmentItemsReady = ix.arc9.RegisterAttachmentItems(true) ~= false
    end

    patchARC9Items()
    return patchARC9BaseSWEP() and attachmentItemsReady
end
function PLUGIN:InitializedPlugins()
    timer.Simple(0, initializeARC9Support)

    if (timer.Exists(retryTimer)) then
        timer.Remove(retryTimer)
    end

    timer.Create(retryTimer, 1, 30, function()
        if (initializeARC9Support()) then
            timer.Remove(retryTimer)
        end
    end)
end

function PLUGIN:InitializedConfig()
    initializeARC9Support()
end


function PLUGIN:ARC9_PlayerGetAtts(client, att)
    if (not ix.arc9 or not ix.arc9.CountAttachmentItems) then
        return
    end

    return ix.arc9.CountAttachmentItems(client, att)
end
function PLUGIN:ARC9_PlayerTakeAtt(client, att, amount)
    if (CLIENT or not ix.arc9 or not ix.arc9.TakeAttachmentItems) then
        return
    end

    if ((client.ixARC9SuppressAttInventorySync or 0) > 0) then
        return true
    end

    return ix.arc9.TakeAttachmentItems(client, att, amount)
end

function PLUGIN:ARC9_PlayerGiveAtt(client, att, amount)
    if (CLIENT or not ix.arc9 or not ix.arc9.GiveAttachmentItems) then
        return
    end

    if ((client.ixARC9SuppressAttInventorySync or 0) > 0) then
        return true
    end

    return ix.arc9.GiveAttachmentItems(client, att, amount)
end














