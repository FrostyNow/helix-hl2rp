
ITEM.name = "Book"
ITEM.model = Model("models/willardnetworks/misc/book.mdl")
ITEM.description = "cookBookDesc"
ITEM.price = 100
ITEM.bodyGroups = {
	["color"] = 7,
}
ITEM.isStackable = true

ITEM.functions.Use = {
	name = "Read",
	icon = "icon16/book_open.png",
	OnRun = function(item)
		local client = item.player
		local cook = client:GetCharacter():GetAttribute("cooking", 0)
		local lck = client:GetCharacter():GetAttribute("lck", 0)
		local amount = 0.5 + lck * 0.5
		local maxAttributes = ix.config.Get("maxAttributes", 30)
		
		if cook + amount <= maxAttributes then
			client:GetCharacter():SetAttrib("cooking", cook + amount)
		else
			client:GetCharacter():SetAttrib("cooking", maxAttributes)
		end

		for i = 0, 2 do
			timer.Simple(i * 0.3, function()
				if (IsValid(client)) then
					client:EmitSound("interface/items/inv_items_money_paper.ogg")
				end
			end)
		end

	end,
	OnCanRun = function(item)
		local client = item.player
		local int = client:GetCharacter():GetAttribute("cooking", 0)
		local maxAttributes = ix.config.Get("maxAttributes", 30)
		return int < maxAttributes
	end
}
