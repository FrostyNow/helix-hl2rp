ITEM.name = "Safe Password"
ITEM.description = "itemSafePasswordDesc"
ITEM.model = "models/props_wasteland/prison_padlock001a.mdl"
ITEM.category = "Utility"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 10

ITEM.functions.Use = {
	name = "Set Password",
	tip = "useTip",
	icon = "icon16/lock_add.png",
	OnRun = function(itemTable, self, entity)
		local client = itemTable.player
		local password = net.ReadString()
		local entity = net.ReadEntity()
		local tr = client:GetEyeTraceNoCursor()

		if (tr.Entity:GetClass() != "ix_container") then 
			client:NotifyLocalized("notPersonalSafe", recipient) 
			return false
		end

		if tr.Entity.password then 
			client:NotifyLocalized("safeAlreadySecured", recipient)
		 	return false 
		end

		client:RequestString("@containerPasswordTitle", "@containerPasswordDesc", function(password)

			if (password:len() != 0) then
			tr.Entity.Sessions = {}
			tr.Entity:SetLocked(true)
			tr.Entity.password = password

			client:NotifyLocalized("containerPassword", password)
			
		end
		end, '')

	end
}