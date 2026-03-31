ITEM.name = "Pager"
ITEM.model = Model("models/gibs/shield_scanner_gib1.mdl")
ITEM.description = "pagerSignalDesc"
ITEM.category = "Utility"
ITEM.price = 50

ITEM.functions.Sync = {
	name = "Sync",
	tip = "pagerSyncDesc",
	icon = "icon16/arrow_refresh.png",
	OnRun = function(item)
		local client = item.player
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 96
			data.filter = client
		local target = util.TraceLine(data).Entity

		if (IsValid(target) and target:IsPlayer()) then
			local targetChar = target:GetCharacter()
			local targetInv = targetChar:GetInventory()
			local targetPager = targetInv:HasItem("pager")

			if (targetPager) then
				local clientChar = client:GetCharacter()
				
				-- Clear previous pairings to enforce 1:1 person-to-person
				item:SetData("pairCharID", targetChar:GetID())

				-- Pair B to A (Mutual)
				targetPager:SetData("pairCharID", clientChar:GetID())

				client:NotifyLocalized("pagerSynced", targetChar:GetName())
				target:NotifyLocalized("pagerSynced", clientChar:GetName())

				-- Optional: notify via novelizer me from A
				local plugin = ix.plugin.Get("pager")
				if (plugin) then
					plugin:SendPagerMe(client)
				end
			else
				client:NotifyLocalized("pagerNoPager")
				return false
			end
		elseif (IsValid(target) and target:GetClass() == "ix_pager_button") then
			local clientChar = client:GetCharacter()

			if (target.PairCharacter) then
				target:PairCharacter(clientChar:GetID())
				
				-- Notify client they've synced with button
				client:NotifyLocalized("pagerSynced", "Pager Button")

				item:SetData("pairCharID", nil) -- Reset person pairing

				local plugin = ix.plugin.Get("pager")
				if (plugin) then
					plugin:SendPagerMe(client)
				end
			end
		else
			client:NotifyLocalized("pagerNoTarget")
			return false
		end

		return false
	end,
	OnCanRun = function(item)
		return (!IsValid(item.entity))
	end
}

ITEM.functions.Signal = {
	name = "Send Signal",
	tip = "pagerSignalDesc",
	icon = "icon16/transmit.png",
	OnRun = function(item)
		local client = item.player
		local pairCharID = item:GetData("pairCharID")

		if (pairCharID) then
			local targetPlayer
			for _, v in ipairs(player.GetAll()) do
				local char = v:GetCharacter()
				if (char and char:GetID() == pairCharID) then
					targetPlayer = v
					break
				end
			end

			if (IsValid(targetPlayer)) then
				local plugin = ix.plugin.Get("pager")
				if (plugin) then
					-- Send 'me' for sender
					plugin:SendPagerMe(client)
					
					-- Send 'it' for receiver
					plugin:SendPagerIt(targetPlayer)
				end
				
				client:NotifyLocalized("pagerSignalSent")
			else
				client:NotifyLocalized("pagerTargetOffline")
			end
		else
			client:NotifyLocalized("pagerNotSynced")
		end

		return false
	end,
	OnCanRun = function(item)
		return (!IsValid(item.entity))
	end
}