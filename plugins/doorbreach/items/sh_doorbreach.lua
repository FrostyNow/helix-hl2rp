
ITEM.name = "Shaped Charge Breaching Device"
ITEM.description = "itemDoorBreachDesc"
ITEM.model = Model("models/weapons/w_slam.mdl")
ITEM.width = 1
ITEM.height = 1
ITEM.price = 475

ITEM.functions.Place = {
	OnRun = function(itemTable)
		local client = itemTable.player
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 96
			data.filter = client

		local breach = scripted_ents.Get("ix_doorbreach"):SpawnFunction(client, util.TraceLine(data))

		if (IsValid(breach)) then
			client:EmitSound("physics/metal/weapon_impact_soft2.wav", 75, 80)
		else
			return false
		end
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
