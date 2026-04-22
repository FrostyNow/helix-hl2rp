
ITEM.name = "Pack of Cigarettes"
ITEM.description = "itemCigaretteDesc"
ITEM.price = 25
ITEM.model = "models/hls/alyxports/cigarette_pack.mdl"
ITEM.isjunk = true

ITEM.invWidth = 1
ITEM.invHeight = 1
ITEM.allowItems = {"cigarette"}

function ITEM:OnInstanced(invID, x, y)
	local inventory = ix.item.inventories[invID]

	ix.inventory.New(inventory and inventory.owner or 0, self.uniqueID, function(inv)
		local client = inv:GetOwner()

		inv.vars.isBag = self.uniqueID
		self:SetData("id", inv:GetID())

		if (IsValid(client)) then
			inv:AddReceiver(client)
		end

		-- Add 14 cigarettes initially
		for i = 1, 14 do
			inv:Add("cigarette")
		end
	end)
end