
ITEM.name = "Combine Scanner"
ITEM.description = "itemScannerDesc"
ITEM.model = Model("models/Combine_Scanner.mdl")
ITEM.category = "Utility"
ITEM.width = 2
ITEM.height = 2
ITEM.price = 100
ITEM.classes = {CLASS_MPU, CLASS_EMP}

ITEM.functions.Use = {
	name = "Place It",
	icon = "icon16/cursor.png",
	OnRun = function(item, player)
		local ply = IsValid(player) and player or item.player
		if (!IsValid(ply)) then return false end

		ply:EmitSound( "npc/turret_floor/deploy.wav", 75, 200 )

		if ix.plugin.Get("scanner") then

			if IsValid(ply.ixScn) then
				ply:NotifyLocalized("scannerAlreadyOperating")
				return false
			end

			ply:EmitSound("npc/turret_floor/deploy.wav", 75, 200)

			local spawnPos = ply:EyePos() + ply:GetAimVector() * 80

			local entity = ents.Create("ix_scanner")
			if not IsValid(entity) then return false end

			entity:SetPos(spawnPos)
			entity:SetAngles(ply:GetAngles())
			entity:Spawn()
			entity:Activate()
			entity:SetNetVar("ixPlayer", player or ply)

			local name = ix.plugin.Get("scanner"):GenerateUniqueScannerName(false)
			entity:SetNetVar("ixScannerName", name)
			
			if (IsValid(player or ply)) then
				(player or ply):Notify("SPAWNED: ix_scanner (" .. name .. ")")
			end
		else
			-- if (IsValid(player or ply)) then
			-- 	(player or ply):Notify("SPAWNED: npc_cscanner (PLUGIN NOT FOUND)")
			-- end
			-- ply:Notify("Spawning npc_cscanner instead of ix_scanner!") -- Debug
			local ent = ents.Create("npc_cscanner")

			ent:SetPos(ply:EyePos() + ( ply:GetAimVector() * 100))
			ent:SetAngles(ply:GetAngles())
			ent:Spawn()
			ent:Activate()

			for _, v in ipairs(player.GetAll()) do
				if v:IsCombine() then
					ent:AddEntityRelationship(v, D_LI, 99)
				else
					ent:AddEntityRelationship(v, D_HT, 99)
				end
			end
		end

		return true
	end,
	OnCanRun = function(item)
		local client = item.player
		if not IsValid(client) then return false end
		if IsValid(item.entity) then return false end
		if item.invID ~= client:GetCharacter():GetInventory():GetID() then return false end

		return client:IsCombine() or client:GetCharacter():GetInventory():HasItem("comkey")
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