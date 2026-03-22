ITEM.name = "craftbook"
ITEM.description = "Simple."
ITEM.category = "Book_Base"
ITEM.model = "models/props_lab/bindergraylabel01b.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.empty = false

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local usenum = self:GetData("usenum", self.usenum)
		if (usenum) then
			local row = tooltip:AddRow("usenum")
			row:SetText(L("usesLabel", usenum))
			row:SetBackgroundColor(ix.config.Get("color"))
		end
	end
end

ITEM.functions.ReadBook = {
	icon = "icon16/book.png",
	OnRun = function(item)
		local client = item.player
		local char = client:GetCharacter()
		
		net.Start("ix_book_read")
            --net.WriteString(title)
            --net.WriteString(content)
        net.Send(client)
	end,
	
	OnCanRun = function(item)
		local client = item.player
		local character = client:GetCharacter()
		local enabled = !Schema:IsCombineRank(client:Name(), "SCN")
		if (FACTION_OTA and client:Team() == FACTION_OTA) then enabled = false end

		return enabled
	end
}