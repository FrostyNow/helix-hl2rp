if (SERVER) then
    util.AddNetworkString("ixARC9UpdatePreset")
    util.AddNetworkString("ixARC9SendPreset")

    net.Receive("ixARC9UpdatePreset", function(_, client)
        local character = client:GetCharacter()
        local characterID = net.ReadUInt(32)

        if (not character or character:GetID() ~= characterID) then
            return
        end

        local weapon = ents.GetByIndex(net.ReadUInt(32))
        local preset = net.ReadString()

        if (IsValid(weapon) and weapon.ixItem) then
            weapon.ixItem:SetData("preset", preset)
        end
    end)
else
    net.Receive("ixARC9SendPreset", function()
        local weapon = net.ReadEntity()
        local preset = net.ReadString()

        if (not IsValid(weapon) or not weapon.ARC9) then
            return
        end

        weapon.LoadedPreset = true
        weapon.ixARC9BlockPresetUpdate = true

        if (isfunction(weapon.SetNoPresets)) then
            weapon:SetNoPresets(true)
        end

        if (preset == "__ix_default__") then
            if (ix.arc9 and ix.arc9.ResetWeaponAttachments) then
                ix.arc9.ResetWeaponAttachments(weapon, weapon.ixItem)
            end

            weapon.ixARC9BlockPresetUpdate = nil
            return
        end

        if (isfunction(weapon.ImportPresetCode)) then
            local ok, presetTable = pcall(weapon.ImportPresetCode, weapon, preset)

            if (ok and istable(presetTable) and isfunction(weapon.LoadPresetFromTable)) then
                if (ix.arc9 and ix.arc9.ResetWeaponAttachments) then
                    ix.arc9.ResetWeaponAttachments(weapon, weapon.ixItem)
                end

                weapon:LoadPresetFromTable(presetTable, true)
            end
        end

        weapon.ixARC9BlockPresetUpdate = nil
    end)
end
