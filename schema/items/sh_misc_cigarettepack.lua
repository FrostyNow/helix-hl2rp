
ITEM.name = "Pack of Cigarettes"
ITEM.description = "itemCigaretteDesc"
ITEM.price = 30
ITEM.model = "models/hls/alyxports/cigarette_pack.mdl"
ITEM.isjunk = true
ITEM.isStackable = true
ITEM.maxStack = 10

ITEM.functions.Open = {
	icon = "icon16/email_open.png",
	OnRun = function(item)
		local client = item.player
		local char = client:GetCharacter()
		local inv = char:GetInventory()

		inv:Add("misc_cigarettepack_open")
	end,
	OnCanRun = function(item)
		local client = item.player
		local char = client:GetCharacter()
		local inv = char:GetInventory()

		return !IsValid(item.entity) and IsValid(inv)
	end
}