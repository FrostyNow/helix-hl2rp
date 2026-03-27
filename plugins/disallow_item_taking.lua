PLUGIN.name = "Disallow item taking"
PLUGIN.author = "github.com/John1344 | Modified by Frosty"
PLUGIN.description = "Adds /disallowitemtaking command"

ix.lang.AddTable("english", {
	itemTakingDisallowed = "The item is now not took-able.",
	itemTakingAllowed = "The item is now took-able.",
	cannotTakeItem = "You cannot take this item. It is disallowed by admin."
})

ix.lang.AddTable("korean", {
	itemTakingDisallowed = "이제 이 아이템은 가져갈 수 없습니다.",
	itemTakingAllowed = "이제 이 아이템은 가져갈 수 있습니다.",
	cannotTakeItem = "당신은 이 아이템을 가져갈 수 없습니다. 관리자에 의해 비허용되었습니다."
})

ix.command.Add("DisallowItemTaking", {
	adminOnly = true,
	OnRun = function(self, client)
		local eyeTrace = client:GetEyeTrace().Entity

		if (eyeTrace:GetClass() == "ix_item") then
			local item = ix.item.instances[eyeTrace.ixItemID]

			if (item) then
				item:SetData("cannotTake", true)

				client:NotifyLocalized("itemTakingDisallowed")
				return
			end
		end

		client:NotifyLocalized("unknownError")
	end
})

ix.command.Add("AllowItemTaking", {
	adminOnly = true,
	OnRun = function (self, client)
		local eyeTrace = client:GetEyeTrace().Entity

		if (eyeTrace:GetClass() == "ix_item") then
			local item = ix.item.instances[eyeTrace.ixItemID]

			if (item) then
				item:SetData("cannotTake", nil)

				client:NotifyLocalized("itemTakingAllowed")
				return
			end
		end

		client:NotifyLocalized("unknownError")
	end
})

ix.command.Add("ToggleItemTaking", {
	adminOnly = true,
	OnRun = function(self, client)
		local eyeTrace = client:GetEyeTrace().Entity

		if (eyeTrace:GetClass() == "ix_item") then
			local item = ix.item.instances[eyeTrace.ixItemID]

			if (item) then
				local bIsRestricted = !item:GetData("cannotTake")
				item:SetData("cannotTake", bIsRestricted or nil)

				client:NotifyLocalized(bIsRestricted and "itemTakingDisallowed" or "itemTakingAllowed")
				return
			end
		end

		client:NotifyLocalized("unknownError")
	end
})

function PLUGIN:CanPlayerTakeItem(client, item)
	local itemTable = isentity(item) and item:GetItemTable() or item

	if (itemTable and itemTable:GetData("cannotTake") == true) then
		client:NotifyLocalized("cannotTakeItem")
		return false
	end
end

properties.Add("disallow_taking", {
	MenuLabel = "Disallow Item Taking",
	Order = 1001,
	MenuIcon = "icon16/lock.png",
	Filter = function(self, entity, client)
		if (!IsValid(entity) or entity:GetClass() != "ix_item") then return false end
		if (!client:IsAdmin()) then return false end

		local item = entity:GetItemTable()
		return item and !item:GetData("cannotTake")
	end,
	Action = function(self, entity)
		self:MsgStart()
			net.WriteEntity(entity)
		self:MsgEnd()
	end,
	Receive = function(self, length, client)
		local entity = net.ReadEntity()

		if (!self:Filter(entity, client)) then return end

		local item = entity:GetItemTable()
		if (item) then
			item:SetData("cannotTake", true)
			client:NotifyLocalized("itemTakingDisallowed")
		end
	end
})

properties.Add("allow_taking", {
	MenuLabel = "Allow Item Taking",
	Order = 1002,
	MenuIcon = "icon16/lock_open.png",
	Filter = function(self, entity, client)
		if (!IsValid(entity) or entity:GetClass() != "ix_item") then return false end
		if (!client:IsAdmin()) then return false end

		local item = entity:GetItemTable()
		return item and item:GetData("cannotTake")
	end,
	Action = function(self, entity)
		self:MsgStart()
			net.WriteEntity(entity)
		self:MsgEnd()
	end,
	Receive = function(self, length, client)
		local entity = net.ReadEntity()

		if (!self:Filter(entity, client)) then return end

		local item = entity:GetItemTable()
		if (item) then
			item:SetData("cannotTake", nil)
			client:NotifyLocalized("itemTakingAllowed")
		end
	end
})
