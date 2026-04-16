ITEM.name = "Radio Pack"
ITEM.description = "radioPackDesc"
ITEM.model = "models/mosi/fallout4/props/junk/ammobag.mdl"
ITEM.height = 1
ITEM.width = 1
ITEM.price = 20
ITEM.eqBodyGroups = {
	["Backpack"] = 1,
}
ITEM.outfitCategory = "bag"

ITEM.isBag = true
ITEM.invWidth = 2
ITEM.invHeight = 2
ITEM.allowBases = {"radios"}

ITEM.allowedModels = {
	"models/jq/theparrygod/transition_period_overwatch_soldier_npc.mdl",
}

ITEM.tooltipLabelText = "securitizedItemTooltip"
ITEM.tooltipLabelFactionColor = FACTION_MPF

function ITEM:OnInstanced(invID, x, y)
	local inventory = ix.plugin.Get("radio_extended") and ix.item.inventories[invID]

	ix.inventory.New(inventory and inventory.owner or 0, self.uniqueID, function(inv)
		local client = inv:GetOwner()

		inv.vars.isBag = self.uniqueID
		self:SetData("id", inv:GetID())

		if (IsValid(client)) then
			inv:AddReceiver(client)
		end

		inv:Add("longrange")
	end)
end
