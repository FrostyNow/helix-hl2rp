ITEM.name = "EMP Tool"
ITEM.description = "itemEMPDesc"
ITEM.category = "Utility"
ITEM.model = "models/alyx_emptool_prop.mdl"
ITEM.skin = 0
ITEM.width = 1
ITEM.height = 1
ITEM.price = 160
ITEM.functions.OverloadDoor = {
	name = "Overload Door",
	icon = "icon16/key.png",
	OnRun = function(itemTable)
		local ply = itemTable.player
		local data = {}
			data.start = ply:GetShootPos()
			data.endpos = data.start + ply:GetAimVector() * 96
			data.filter = ply
		local target = util.TraceLine(data).Entity

		if IsValid(target) and target:IsDoor() then
			local randomChance = math.random(1,10)
			local lck = ply:GetCharacter():GetAttribute("lck", 0)
			local lckMlt = ix.config.Get("luckMultiplier", 1)
			local lckAmt = (lck * lckMlt) / 10

			if not (target:HasSpawnFlags(256) and target:HasSpawnFlags(1024)) then
				ply:Freeze(true)
				ply:EmitSound("ambient/machines/combine_terminal_idle2.wav")
				ply:SetAction("@empOverloading", 3, function()
					ply:Freeze(false)
					if (randomChance + lckAmt > 5) then
						target:Fire("unlock")
						target:Fire("open")
						ply:EmitSound("buttons/combine_button1.wav")
						ply:NotifyLocalized("empOverloadDoorSucceed")
					else
						ply:EmitSound("ambient/energy/zap1.wav")
						ply:NotifyLocalized("empFailed")

						randomChance = math.random(1,10)
						if (randomChance + lckAmt <= 2) then
							
							ply:NotifyLocalized("empBroken")
							return true
						end
					end
				end)
			end
		else
			ply:NotifyLocalized("empOverloadDoorFailed")
		end

		return false
	end
}
-- ITEM.functions.OverloadCamera = {
-- 	name = "Overload Camera",
-- 	icon = "icon16/eye.png",
-- 	OnRun = function(itemTable)
-- 		local ply = itemTable.player
-- 		local data = {}
-- 			data.start = ply:GetShootPos()
-- 			data.endpos = data.start + ply:GetAimVector() * 96
-- 			data.filter = ply
-- 		local target = util.TraceLine(data).Entity

-- 		if IsValid(target) and target:IsNPC() and target:GetClass() == "npc_combine_camera" and target:Classify(CLASS_MILITARY) and target:GetSequenceName(target:GetSequence()) != "idlealert" then
-- 			local randomChance = math.random(1,10)
-- 			local lck = ply:GetCharacter():GetAttribute("lck", 0)
-- 			local lckMlt = ix.config.Get("luckMultiplier", 1)
-- 			local lckAmt = (lck * lckMlt) / 10

-- 			ply:Freeze(true)
-- 			ply:SetAction("@empOverloading", 3, function()
-- 				ply:Freeze(false)
-- 				if (randomChance + lckAmt > 5) then
-- 					target:Fire("Disable")
-- 					ply:EmitSound("buttons/combine_button1.wav")
-- 					ply:NotifyLocalized("empOverloadCameraSucceed")
-- 				else
-- 					ply:EmitSound("ambient/energy/zap1.wav")
-- 					ply:NotifyLocalized("empFailed")
-- 				end
-- 			end)
-- 		else
-- 			ply:NotifyLocalized("empOverloadCameraFailed")
-- 		end

-- 		return false
-- 	end
-- }

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end