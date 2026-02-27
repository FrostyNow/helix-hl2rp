
ITEM.name = "Anti-Depressants"
ITEM.description = "itemAntiDepressantsDesc"
ITEM.category = "Medical"
ITEM.model = "models/hlvr/props/bottles/medicine_bottle_2.mdl"
ITEM.price = 15
ITEM.functions.Use = {
	text = "Swallow",
	OnRun = function(item)
		local client = item.player

		client:EmitSound("interface/items/inv_items_pills_2.ogg")
		client:SendLua([[surface.PlaySound("music/stingers/industrial_suspense1.wav")]])
		
		client:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 150), 1, 1)
		client:SetNetVar("noDepress", client:GetNetVar("noDepress", 0) + 1)
		client:SetNetVar("antidepressant", true)

		timer.Simple(60, function()
			if (IsValid(client)) then
				client:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 150), 1, 1)
				client:SetNetVar("antidepressant", false)
				client:SetNetVar("noDepress", client:GetNetVar("noDepress", 0) - 1)
			end
		end)
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