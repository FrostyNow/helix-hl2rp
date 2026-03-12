local PLUGIN = PLUGIN

function PLUGIN:PostPlayerLoadout(client)
    local character = client:GetCharacter()

    if (not character or not character:GetInventory()) then
        return
    end

    if (client.loadoutPredictedARC9) then
        for itemTable, _ in character:GetInventory():Iter() do
            if (itemTable.isARC9Weapon and itemTable:GetData("equip", false)) then
                itemTable:Call("OnPostLoadout", client)
            end
        end

        client.loadoutPredictedARC9 = nil
        return
    end

    client.loadoutPredictedARC9 = true
end
