ITEM.name = "Lottery"
ITEM.model = "models/lottery_ticket/lottery_ticket.mdl"
ITEM.category = "Utility"
ITEM.description = "itemLotteryDesc"
ITEM.price = 40
ITEM.width = 1
ITEM.height = 1
ITEM.iconCam = {
	pos = Vector(509.64, 427.61, 310.24),
	ang = Angle(25, 220, 0),
	fov = 0.4
}
ITEM.exRender = true

ITEM.slotWinChance = 10 -- 10% per slot (0.1% total for 3 slots)
ITEM.winAmountRange = {1000, 10000}
ITEM.isStackable = true

function ITEM:PopulateTooltip(tooltip)
	if (self:GetData("used")) then
		local status = tooltip:AddRow("lotteryStatus")
		
		if (self:GetData("isWin")) then
			status:SetTextColor(derma.GetColor("Success", tooltip))
			status:SetText(L("lotteryStatusWin"))
		else
			status:SetTextColor(derma.GetColor("Error", tooltip))
			status:SetText(L("lotteryStatusLoss"))
		end
		
		status:SizeToContents()
	end
end

function ITEM:OnInstantiated()
	self.model = self:GetData("model", self.model)
end

function ITEM:OnDataChanged(key, oldValue, newValue)
	if (key == "model") then
		self.model = newValue

		if (CLIENT) then
			ix.gui.RefreshItemIcon(self.id)
		end
	end
end

ITEM.functions.Scratch = {
	name = "lotteryScratch",
	tip = "lotteryScratchTip",
	icon = "icon16/pencil.png",
	OnRun = function(item)
		local client = item.player
		local character = client:GetCharacter()
		
		-- Logic: 3 slots, each 10% base chance
		local luck = character:GetAttribute("lck", 0)
		local maxAttribs = ix.config.Get("maxAttributes", 10)
		local luckMlt = ix.config.Get("luckMultiplier", 1)
		
		-- Normalize luck bonus based on maximum possible attributes
		local luckNormalized = math.Clamp(luck / maxAttribs, 0, 1)
		local finalSlotChance = item.slotWinChance + (luckNormalized * luckMlt)
		
		local bWin = true
		for i = 1, 3 do
			if (math.random(1, 100) > finalSlotChance) then
				bWin = false
				break
			end
		end
		
		item:SetData("used", true)
		item:SetData("isWin", bWin)
		
		-- Feedback
		client:EmitSound("physics/cardboard/cardboard_box_impact_bullet1.wav", 65, math.random(90, 110))
		
		if (bWin) then
			client:NotifyLocalized("lotteryWonNotify")
		else
			client:NotifyLocalized("lotteryLostNotify")
		end

		item:SetData("model", "models/lottery_ticket_win/lottery_ticket_win.mdl")

		return false
	end,
	OnCanRun = function(item)
		return !IsValid(item.entity) and !item:GetData("used", false)
	end
}

-- Manual Transaction
-- ITEM.functions.Redeem = {
-- 	name = "lotteryRedeem",
-- 	tip = "lotteryRedeemTip",
-- 	icon = "icon16/money_add.png",
-- 	OnRun = function(item)
-- 		local client = item.player
-- 		local character = client:GetCharacter()
		
-- 		local amount = math.random(item.winAmountRange[1], item.winAmountRange[2])
-- 		character:GiveMoney(amount)
-- 		client:Notify(L("lotteryRedeemed", ix.currency.Get(amount)))
		
-- 		return true -- Consume item after redemption
-- 	end,
-- 	OnCanRun = function(item)
-- 		return !IsValid(item.entity) and item:GetData("used") and item:GetData("isWin")
-- 	end
-- }

