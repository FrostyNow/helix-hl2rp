ITEM.name = "Lottery Box"
ITEM.model = "models/lottery_ticket_box/lottery_ticket_box.mdl"
ITEM.description = "itemLotteryBoxDesc"
ITEM.category = "Utility"
ITEM.price = 200
ITEM.width = 1
ITEM.height = 1
ITEM.invWidth = 1
ITEM.invHeight = 1
ITEM.allowItems = {"lottery"}

function ITEM:OnInstanced(invID, x, y)
	local inventory = ix.item.inventories[invID]

	ix.inventory.New(inventory and inventory.owner or 0, self.uniqueID, function(inv)
		local client = inv:GetOwner()

		inv.vars.isBag = self.uniqueID
		self:SetData("id", inv:GetID())

		if (IsValid(client)) then
			inv:AddReceiver(client)
		end

		-- Add 5 lottery tickets initially
		for i = 1, 5 do
			inv:Add("lottery")
		end
	end)
end
