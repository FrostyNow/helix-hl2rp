ITEM.name = "Water Drug"
ITEM.model = "models/willardnetworks/skills/pills1.mdl"
ITEM.description = "itemWaterDrugDesc"
ITEM.price = 1

ITEM.functions.Use = {
	text = "Swallow",
	OnRun = function(item)
		local client = item.player

		client:EmitSound("interface/items/inv_items_pills_2.ogg")
		client:SendLua([[surface.PlaySound("music/stingers/industrial_suspense1.wav")]])
		
		client:SetNetVar("noDepress", client:GetNetVar("noDepress", 0) + 1)
		client:SetNetVar("poisoned", true)

		timer.Simple(60, function()
			if (IsValid(client)) then
				client:SetNetVar("poisoned", false)
				client:SetNetVar("noDepress", client:GetNetVar("noDepress", 0) - 1)
			end
		end)
	end
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end