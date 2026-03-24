ITEM.name = "itemWheat"
ITEM.description = "itemWheatDesc"
ITEM.model = "models/noble/limelight/wheat_plant.mdl"
ITEM.width = 1
ITEM.height = 2

ITEM.functions.Consume = {
    name = "씹기",
    icon = "icon16/cup.png",
    OnRun = function(item)
        local client = item.player
        client:SetHealth(math.min(client:Health() + 5, client:GetMaxHealth()))
        client:NotifyLocalized("eatWheat", client)
        return true
    end
}
