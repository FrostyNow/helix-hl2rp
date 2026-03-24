ITEM.name = "itemFertilizer"
ITEM.description = "itemFertilizerDesc"
ITEM.model = "models/noble/limelight/fertilizer.mdl"

ITEM.functions.Fertilize = {
    name = "비료 주기",
    icon = "icon16/arrow_up.png",
    OnRun = function(item)
        local client = item.player
        local trace = client:GetEyeTraceNoCursor()
        local entity = trace.Entity

        if (IsValid(entity) and entity:GetClass() == "ix_farmbox" and entity:GetPos():DistToSqr(client:GetPos()) <= 10000) then
            if (entity:GetCropType() != "") then
                if (!entity:GetHasFertilizer()) then
                    entity:SetHasFertilizer(true)
                    client:NotifyLocalized("farmFertilizerApplied")
                    return true -- 소비됨
                else
                    client:NotifyLocalized("farmAlreadyFertilized")
                end
            else
                client:NotifyLocalized("farmFertilizeFirst")
            end
        else
            client:NotifyLocalized("farmLookAtBox")
        end
        return false
    end
}
