ITEM.name = "Carrot"
ITEM.model = "models/props_lab/headcrabprepcarrot3.mdl"
ITEM.description = "itemCarrotDesc"
ITEM.price = 10
ITEM.hunger = 10
ITEM.heal = 5

ITEM.functions = ITEM.functions or {}
ITEM.functions.Plant = {
    name = "심기",
    icon = "icon16/arrow_down.png",
    OnRun = function(item)
        local client = item.player
        local trace = client:GetEyeTraceNoCursor()
        local entity = trace.Entity

        if (IsValid(entity) and entity:GetClass() == "ix_farmbox" and entity:GetPos():DistToSqr(client:GetPos()) <= 10000) then
            if (entity:GetCropType() == "") then
                entity:SetCropType("carrot")
                entity:SetProgress(0)
                client:NotifyLocalized("farmPlanted", L("cropCarrot", client))
                return true
            else
                client:NotifyLocalized("farmAlreadyPlanted")
            end
        else
            client:NotifyLocalized("farmLookAtBox")
        end
        return false
    end
}