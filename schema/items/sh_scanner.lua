
ITEM.name = "Combine Scanner"
ITEM.description = "ScannerDesc"
ITEM.model = Model("models/Combine_Scanner.mdl")
ITEM.width = 2
ITEM.height = 2
ITEM.price = 100

ITEM.functions.Use = {
	name = "Place It",
	icon = "icon16/cursor.png",
	OnRun = function(item, player, client)
		item.player:EmitSound( "npc/turret_floor/deploy.wav", 75, 200 )
			
		local ent = ents.Create("npc_cscanner")

		for k, v in pairs(ents.GetAll()) do
			if(v:IsPlayer()) then
				if(v:IsCombine() or v:Team() == FACTION_ADMIN or v:Team() == FACTION_CONSCRIPT) then
					ent:AddEntityRelationship(v, 3)
				else
					ent:AddEntityRelationship(v, 1)
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

		return !IsValid(item.entity) and IsValid(client) and item.invID == client:GetCharacter():GetInventory():GetID() and (client:IsCombine() or client:Team() == FACTION_ADMIN or client:Team() == FACTION_CONSCRIPT)
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