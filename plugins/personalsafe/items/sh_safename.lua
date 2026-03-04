ITEM.name = "Safe Name"
ITEM.description = "itemSafeNameDesc"
ITEM.model = "models/props_lab/clipboard.mdl"
ITEM.category = "Utility"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 10

ITEM.functions.Use = {
	name = "Set Name",
	tip = "useTip",
	icon = "icon16/lock_add.png",
	OnRun = function(itemTable, self, entity)
		local client = itemTable.player
		local name = net.ReadString()
		local entity = net.ReadEntity()
		local tr = client:GetEyeTraceNoCursor()

		if (tr.Entity:GetClass() != "ix_container") then 
			client:NotifyLocalized("notPersonalSafe", recipient) 
			return false
		end

		if tr.Entity.name then 
			client:NotifyLocalized("safeAlreadyNamed", recipient)
		 	return false 
		end

		client:RequestString("@containerNameTitle", "@containerNameDesc", function(name)

			if (name:len() != 0) then
			tr.Entity.Sessions = {}
			tr.Entity:SetDisplayName(name)
			tr.Entity.name = name

			client:NotifyLocalized("containerName", name)
			
		end
		end, '')

	end
}