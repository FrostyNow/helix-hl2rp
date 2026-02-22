ITEM.name = "Water Drug"
ITEM.model = "models/props_lab/jar01b.mdl"
ITEM.description = "itemWaterDrugDesc"
ITEM.price = 1

ITEM.functions.Use = {
	text = "Swallow",
	OnRun = function(item)
		if (CLIENT) then
			item.player:EmitSound("music/stingers/industrial_suspense1.wav", 60)
		else
			local client = item.player

			client:SetNetVar("noDepress", client:GetNetVar("noDepress", 0) - 0.5)
			client:SetNetVar("blur", 0.95)

			timer.Simple(8, function()
				if (IsValid(client)) then
					client:SetNetVar("blur", 0)
					client:SetNetVar("noDepress", client:GetNetVar("noDepress", 0) + 1)
				end
			end)

			timer.Simple(128, function()
				if (IsValid(client)) then
					client:SetNetVar("noDepress", client:GetNetVar("noDepress", 0.5) - 0.5)
				end
			end)
		end
	end
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end