ITEM.name = "Overwatch Standard Issue\n(Pulse-Rifle)"
ITEM.description = "ar2Desc"
ITEM.model = "models/weapons/w_irifle.mdl"
ITEM.class = "arc9_hla_irifle"
ITEM.weaponCategory = "primary"
ITEM.classes = {CLASS_EOW, CLASS_OWS, CLASS_EMP}
ITEM.width = 4
ITEM.price = 1450
ITEM.height = 2
ITEM.iconCam = {
	ang	= Angle(-0.70499622821808, 268.25439453125, 0),
	fov	= 12.085652091515,
	pos	= Vector(0, 200, 0)
}

ITEM.lock = 1

ITEM.functions.Equip = {
	name = "Equip",
	tip = "equipTip",
	icon = "icon16/tick.png",
	OnRun = function(item)
		local client = item.player

		if (!client:IsCombine() and item:GetData("locked", true)) then
			client:NotifyLocalized("needComkey")
			return false
		else
			item:Equip(client)
			return false
		end
	end,
	OnCanRun = function(item)
		local client = item.player

		return !IsValid(item.entity) and IsValid(client) and item:GetData("equip") != true and
			hook.Run("CanPlayerEquipItem", client, item) != false
	end
}

ITEM.functions.Unlock = {
	icon = "icon16/key_go.png",
	OnRun = function(item)
		local client = item.player
		local character = client:GetCharacter()
		local inventory = character:GetInventory()
		local hasItem = inventory:HasItem("comkey")

		if (item:GetData("locked", true)) then
			if (client:IsCombine() or hasItem) then
				item:SetData("locked", false)
				client:EmitSound("weapons/ar2/ar2_reload_push.wav")
				return false
			else
				client:NotifyLocalized("needComkey")
				return false
			end
		else
			client:NotifyLocalized("unknownError")
			return false
		end
	end,
	OnCanRun = function(item)
		local client = item.player

		return !IsValid(item.entity) and IsValid(client) and item:GetData("equip") != true and item:GetData("locked", true) == true
	end
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(85, 127, 242))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()

		if (!LocalPlayer():IsCombine() and self:GetData("locked", true)) then
			local lockedData = tooltip:AddRow("lockedData")
			lockedData:SetBackgroundColor(Color(49, 62, 71))
			lockedData:SetText(L("itemLockedTooltip"))
			lockedData:SetExpensiveShadow(0.5)
			lockedData:SizeToContents()
		end
	end
end