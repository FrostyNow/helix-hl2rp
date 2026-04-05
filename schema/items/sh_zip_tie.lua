
ITEM.name = "Zip Tie"
ITEM.description = "zipTieDesc"
ITEM.category = "Utility"
ITEM.price = 8
ITEM.isStackable = true
ITEM.model = "models/items/crossbowrounds.mdl"
ITEM.factions = {FACTION_MPF, FACTION_OTA}
ITEM.functions.Use = {
	OnRun = function(itemTable)
		local client = itemTable.player
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 96
			data.filter = client
		local entity = util.TraceLine(data).Entity
		local target = (IsValid(entity) and entity:GetClass() == "prop_ragdoll") and entity:GetNetVar("player") or entity
		local bIsCorpse = IsValid(entity) and entity:GetClass() == "prop_ragdoll"

		if (IsValid(target) and target:IsPlayer() and target:GetCharacter()
		and !target:GetNetVar("tying") and !target:IsRestricted()) then
			itemTable.bBeingUsed = true

			client:SetAction("@tying", 5)

			client:DoStaredAction(entity, function()
				target:SetRestricted(true)
				target:SetNetVar("tying")
				target:NotifyLocalized("fTiedUp")

				if (target:IsCombine()) then
					Schema:AddCombineDisplayMessage("@cLosingContact", Color(255, 255, 255, 255))
					Schema:AddCombineDisplayMessage("@cLostContact", Color(255, 0, 0, 255))
				end

				itemTable:Remove()
			end, 5, function()
				client:SetAction()

				if (IsValid(target)) then
					target:SetAction()
					target:SetNetVar("tying")
				end

				itemTable.bBeingUsed = false
			end)

			target:SetNetVar("tying", true)
			target:SetAction("@fBeingTied", 5)
		elseif (bIsCorpse and !entity:GetNetVar("ixRestricted")) then
			itemTable.bBeingUsed = true

			client:SetAction("@tying", 5)

			client:DoStaredAction(entity, function()
				entity:SetNetVar("ixRestricted", true)

				if (IsValid(target) and target:IsPlayer()) then
					target:SetRestricted(true)
				end

				itemTable:Remove()
			end, 5, function()
				client:SetAction()
				itemTable.bBeingUsed = false
			end)
		else
			itemTable.player:NotifyLocalized("plyNotValid")
		end

		return false
	end,
	OnCanRun = function(itemTable)
		return !IsValid(itemTable.entity) or itemTable.bBeingUsed
	end
}

function ITEM:CanTransfer(inventory, newInventory)
	return !self.bBeingUsed
end

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end