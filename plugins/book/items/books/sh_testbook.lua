ITEM.name = "testbook"
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

        client:EmitSound("items/ammocrate_open.png") -- 책 넘기는 비슷한 소리

        return false -- 읽어도 아이템이 사라지지 않음
	end,
	OnCanRun = function(item)
		local client = item.player
		local character = client:GetCharacter()
		local enabled = !Schema:IsCombineRank(client:Name(), "SCN")
		if (FACTION_OTA and client:Team() == FACTION_OTA) then enabled = false end

		return enabled
	end
}