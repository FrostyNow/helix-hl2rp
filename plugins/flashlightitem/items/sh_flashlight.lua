
ITEM.name = "Flashlight"
ITEM.model = Model("models/hls/alyxports/flashlight.mdl")
ITEM.width = 1
ITEM.height = 1
ITEM.description = "itemFlashlightDesc"
ITEM.category = "Utility"

local function turnOffIfLast(item)
	local client = item:GetOwner()

	if (IsValid(client) and client:GetCharacter()) then
		local inventory = client:GetCharacter():GetInventory()

		if (inventory and inventory:GetItemCount(item.uniqueID) <= 0) then
			if (client.GetNetVar and client:GetNetVar("flashlight") != nil) then
				client:SetNetVar("flashlight", false)
			end

			client:Flashlight(false)
		end
	end
end

function ITEM:OnTransferred(curInv, nextInv)
	if (curInv.owner and (!nextInv or nextInv.owner != curInv.owner)) then
		turnOffIfLast(self)
	end
end

function ITEM:OnRemoved()
	turnOffIfLast(self)
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
