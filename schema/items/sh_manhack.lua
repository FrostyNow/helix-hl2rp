
ITEM.name = "Manhack"
ITEM.description = "manhackDesc"
ITEM.model = Model("models/manhack.mdl")
ITEM.category = "Utility"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 75

ITEM.functions.Use = {
	name = "Place It",
	icon = "icon16/cursor.png",
	OnRun = function(item, player, client)
		item.player:EmitSound( "npc/turret_floor/deploy.wav", 75, 200 )
			
		local ent = ents.Create("npc_manhack")

		for k, v in pairs(ents.GetAll()) do
			if(v:IsPlayer()) then
				if(v:IsCombine() or v:Team() == FACTION_ADMIN or v:Team() == FACTION_CONSCRIPT) then
					ent:AddEntityRelationship(v, D_LI, 99)
				else
					ent:AddEntityRelationship(v, D_HT, 99)
				end
			end
		end

		ent:SetPos(item.player:EyePos() + ( item.player:GetAimVector() * 100))
		ent:SetAngles(item.player:GetAngles())
		ent:Spawn()

		return true
	end,
	OnCanRun = function(item)
		local client = item.player

		return !IsValid(item.entity) and IsValid(client) and item.invID == client:GetCharacter():GetInventory():GetID() and (client:IsCombine() or client:Team() == FACTION_ADMIN or client:Team() == FACTION_CONSCRIPT or client:GetCharacter():GetInventory():HasItem("comkey"))
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