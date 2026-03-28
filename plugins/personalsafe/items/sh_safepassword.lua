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
		local tr = client:GetEyeTraceNoCursor()

		if (tr.Entity:GetClass() != "ix_container") then 
			client:NotifyLocalized("notPersonalSafe", client) 
			return false
		end

		if tr.Entity.password then 
			client:NotifyLocalized("safeAlreadySecured", client)
		 	return false 
		end

		local target = tr.Entity

		client:RequestString("@containerPasswordTitle", "@containerPasswordDesc", function(password)
			if (IsValid(target) and password:len() != 0) then
				target.Sessions = {}
				target.PasswordAttempts = {}
				target:SetLocked(true)
				target.password = password

				client:NotifyLocalized("containerPassword", password)
			end
		end, "")

		return true
	end
}