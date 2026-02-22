
ITEM.name = "Combine Turret"
ITEM.description = "turretDesc"
ITEM.model = Model("models/zekkirels/floor_turret_undeployed.mdl")
ITEM.width = 2
ITEM.height = 2
ITEM.price = 200

ITEM.functions.Use = {
	name = "Place It",
	icon = "icon16/cursor.png",
	OnRun = function(item, player, client)
		item.player:EmitSound( "npc/turret_floor/deploy.wav", 75, 200 )
			
		local ent = ents.Create("npc_turret_floor")

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

		return IsValid(client) and (client:IsCombine() or client:Team() == FACTION_ADMIN or client:Team() == FACTION_CONSCRIPT)
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