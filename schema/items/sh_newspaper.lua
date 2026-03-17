
ITEM.name = "Newspaper"
ITEM.model = Model("models/props_junk/garbage_newspaper001b.mdl")
ITEM.description = "itemNewspaperDesc"
ITEM.price = 100
ITEM.isStackable = true

ITEM.functions.Use = {
	name = "Read",
	icon = "icon16/book_open.png",
	OnRun = function(item)
		local client = item.player
		local int = client:GetCharacter():GetAttribute("int", 0)
		local lck = client:GetCharacter():GetAttribute("lck", 0)
		local amount = 0.2 + lck * 0.5
		local maxAttributes = ix.config.Get("maxAttributes", 30)
		
		if int + amount <= maxAttributes then
			client:GetCharacter():SetAttrib("int", int + amount)
		else
			client:GetCharacter():SetAttrib("int", maxAttributes)
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
		local int = client:GetCharacter():GetAttribute("int", 0)
		local maxAttributes = ix.config.Get("maxAttributes", 30)
		return int < maxAttributes
	end
}
