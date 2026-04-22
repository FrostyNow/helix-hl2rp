
ITEM.name = "Carton of Cigarettes"
ITEM.description = "itemCigaretteDesc"
ITEM.price = 300
ITEM.model = "models/mosi/fallout4/props/junk/cigarettecarton.mdl"
ITEM.isjunk = true

ITEM.invWidth = 2
ITEM.invHeight = 1
ITEM.allowItems = {"misc_cigarettepack"}

function ITEM:OnInstanced(invID, x, y)
	local inventory = ix.item.inventories[invID]

	ix.inventory.New(inventory and inventory.owner or 0, self.uniqueID, function(inv)
		local client = inv:GetOwner()

		inv.vars.isBag = self.uniqueID
		self:SetData("id", inv:GetID())

		if (IsValid(client)) then
			inv:AddReceiver(client)
		end

		-- Add 10 cigarette packs initially
		for i = 1, 5 do
			inv:Add("misc_cigarettepack")
		end
		for i = 1, 5 do
			inv:Add("misc_cigarettepack")
		end
	end)
end