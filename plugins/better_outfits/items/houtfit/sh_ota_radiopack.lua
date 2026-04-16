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
	"models/combine_soldierproto.mdl",
	"models/combine_soldierproto_drt.mdl",
	"models/combine_super_soldierproto.mdl",
	"models/combine_super_soldierprotodirt.mdl",
	"models/combine_soldiersnow.mdl",
	"models/combine_soldieros.mdl",
	"models/combine_soldiergrunt.mdl",
	"models/combine_soldier2000.mdl",
	"models/combine_darkelite_soldier.mdl",
	"models/combine_darkelite1_soldier.mdl",
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
