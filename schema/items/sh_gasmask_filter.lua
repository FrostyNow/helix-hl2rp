ITEM.name = "Gasmask Filter"
ITEM.description = "itemGasmaskFilterDesc"
ITEM.model = "models/willardnetworks/props/blackfilter.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Consumables"

ITEM.functions.Use = {
	name = "replaceFilter",
	tip = "useTip",
	icon = "icon16/wrench.png",
	OnRun = function(item)
		local client = item.player
		local inventory = client:GetCharacter():GetInventory()
		local targetMask

		for _, v in pairs(inventory:GetItems()) do
			if (v.uniqueID == "citizen_gasmask") then
				if (v:GetData("Durability", v.maxDurability) < v.maxDurability) then
					targetMask = v
					break
				end
			end
		end

		if (targetMask) then
			targetMask:SetData("Durability", targetMask.maxDurability)
			
			if (targetMask.UpdateResistance) then
				targetMask:UpdateResistance(client)
			end

			client:EmitSound("weapons/usp/usp_silencer_on.wav")
			client:NotifyLocalized("gasmaskFilterReplaced")
			
			return true
		else
			client:NotifyLocalized("gasmaskNoNeedRepair")
			return false
		end
	end
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end