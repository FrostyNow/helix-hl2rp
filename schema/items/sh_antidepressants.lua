
ITEM.name = "Anti-Depressants"
ITEM.description = "itemAntiDepressantsDesc"
ITEM.category = "Medical"
ITEM.model = "models/hlvr/props/bottles/medicine_bottle_2.mdl"
ITEM.price = 15
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
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end