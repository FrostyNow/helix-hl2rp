ITEM.name = "Pager"
ITEM.model = Model("models/gibs/shield_scanner_gib1.mdl")
ITEM.description = "itemPagerDesc"
ITEM.category = "Utility"
ITEM.price = 50

-- Visual representation of power status
if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		if (item:GetData("power")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end

	function ITEM:PopulateTooltip(tooltip)
		if (self:GetData("power")) then
			local name = tooltip:GetRow("name")
			name:SetBackgroundColor(derma.GetColor("Success", tooltip))
		end
	end
end

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
				
				-- Mutually pair item IDs
				item:SetData("pairItemID", targetPager.id)
				targetPager:SetData("pairItemID", item.id)

				client:NotifyLocalized("pagerSynced", L(targetChar:GetName(), client))
				target:NotifyLocalized("pagerSynced", L(clientChar:GetName(), target))

				local plugin = ix.plugin.Get("pager")
				if (plugin) then
					plugin:SendPagerMe(client)
				end
			else
				client:NotifyLocalized("pagerNoPager")
				return false
			end
		elseif (IsValid(target) and target:GetClass() == "ix_pager_button") then
			if (target.PairPager) then
				target:PairPager(item.id)
				
				client:NotifyLocalized("pagerSynced", L("pagerButton", client))
				item:SetData("pairItemID", nil)

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
		return (!IsValid(item.entity) and item:GetData("power", false) == true)
	end
}

ITEM.functions.Toggle = {
	name = "Toggle Power",
	icon = "icon16/lightbulb.png",
	OnRun = function(item)
		local bEnabled = !item:GetData("power", false)
		item:SetData("power", bEnabled)
		item.player:EmitSound("buttons/lever7.wav", 50, math.random(170, 180), 0.25)

		return false
	end,
	OnCanRun = function(item)
		return (!IsValid(item.entity))
	end
}

ITEM.functions.Unsync = {
	tip = "Disconnect from the paired pager.",
	icon = "icon16/link_break.png",
	OnRun = function(item)
		item:SetData("pairItemID", nil)
		item.player:NotifyLocalized("pagerUnsynced")
		return false
	end,
	OnCanRun = function(item)
		return (!IsValid(item.entity) and item:GetData("pairItemID") != nil)
	end
}

ITEM.functions.Signal = {
	name = "Send Signal",
	tip = "pagerSignalDesc",
	icon = "icon16/transmit.png",
	OnRun = function(item)
		local client = item.player
		local curTime = CurTime()
		local lastSignal = item:GetData("lastSignal", 0)

		-- 30-second cooldown check
		if (curTime < lastSignal + 10) then
			client:NotifyLocalized("pagerCooldown")
			return false
		end

		local pairItemID = item:GetData("pairItemID")

		if (pairItemID) then
			local id = tonumber(pairItemID)
			if (!id) then return false end

			local plugin = ix.plugin.Get("pager")
			if (plugin) then
				plugin:SendPagerMe(client)
				
				local targetItem = ix.item.instances[id]
				if (targetItem) then
					if (targetItem:GetData("power", false) == false) then
						client:NotifyLocalized("pagerTargetOffline")
						return false
					end

					local owner = targetItem:GetOwner()
					if (IsValid(owner) and owner:IsPlayer()) then
						plugin:SendPagerIt(owner)
						client:NotifyLocalized("pagerSignalSent")
						item:SetData("lastSignal", curTime) -- Update cooldown
						return false
					end
				end
			end
			
			client:NotifyLocalized("pagerTargetOffline")
		else
			client:NotifyLocalized("pagerNotSynced")
		end

		return false
	end,
	OnCanRun = function(item)
		return (!IsValid(item.entity) and item:GetData("power", false) == true)
	end
}