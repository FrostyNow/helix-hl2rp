ITEM.base = "base_bags"
ITEM.name = "itemWateringCan"
ITEM.description = "itemWateringCanDesc"
ITEM.model = "models/noble/limelight/watering_can.mdl"
ITEM.invWidth = 1
ITEM.invHeight = 1

ITEM.functions.Water = {
    name = "물 주기",
    icon = "icon16/water.png",
    OnRun = function(item)
        local client = item.player
        local trace = client:GetEyeTraceNoCursor()
        local entity = trace.Entity

        if (IsValid(entity) and entity:GetClass() == "ix_farmbox" and entity:GetPos():DistToSqr(client:GetPos()) <= 10000) then
            local inv = item:GetInventory()
            if (inv) then
                local waterItems = inv:GetItems()
                local waterItem = nil
                
                for _, v in pairs(waterItems) do
                    -- Helix basic waters
                    if (string.find(v.uniqueID, "water") or string.find(v.name, "물")) then
                        waterItem = v
                        break
                    end
                end

                if (waterItem) then
                    local isClean = (waterItem.uniqueID == "water_boiled" or waterItem.uniqueID == "water")
                    
                    entity:SetWaterAmount(entity:GetWaterAmount() + 43200)
                    if (isClean) then
                        entity:SetWaterQuality(entity:GetWaterQuality() + 1)
                    end
                    
                    client:NotifyLocalized("farmWaterGiven", waterItem.name)
                    waterItem:Remove()
                    return false
                else
                    client:NotifyLocalized("farmNoWaterItem")
                    return false
                end
            else
                client:NotifyLocalized("farmNoWaterInventory")
            end
        else
            client:NotifyLocalized("farmLookAtBox")
        end
        return false
    end
}
