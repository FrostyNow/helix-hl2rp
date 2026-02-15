do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text

	function COMMAND:OnRun(client, message)
		if (!client:IsRestricted()) then
			ix.chat.Send(client, "dispatch", message)
		else
			return "@notNow"
		end
	end

	ix.command.Add("Dispatch", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text

	function COMMAND:OnRun(client, message)
		local character = client:GetCharacter()
		local radios = character:GetInventory():GetItemsByUniqueID("handheld_radio", true)
		local item

		for k, v in ipairs(radios) do
			if (v:GetData("enabled", false)) then
				item = v
				break
			end
		end

		if (item) then
			if (!client:IsRestricted()) then
				ix.chat.Send(client, "radio", message)
				ix.chat.Send(client, "radio_eavesdrop", message)
			else
				return "@notNow"
			end
		elseif (#radios > 0) then
			return "@radioNotOn"
		else
			return "@radioRequired"
		end
	end

	ix.command.Add("Radio", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.number

	function COMMAND:OnRun(client, frequency)
		local character = client:GetCharacter()
		local inventory = character:GetInventory()
		local itemTable = inventory:HasItem("handheld_radio")

		if (itemTable) then
			if (string.find(frequency, "^%d%d%d%.%d$")) then
				character:SetData("frequency", frequency)
				itemTable:SetData("frequency", frequency)

				client:Notify(string.format("You have set your radio frequency to %s.", frequency))
			end
		end
	end

	ix.command.Add("SetFreq", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text

	function COMMAND:OnRun(client, message)
		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		if (inventory:HasItem("request_device") or client:IsCombine() or client:Team() == FACTION_ADMIN) then
			if (!client:IsRestricted()) then
				Schema:AddCombineDisplayMessage("@cRequest")

				ix.chat.Send(client, "request", message)
				ix.chat.Send(client, "request_eavesdrop", message)

				client:EmitSound("buttons/combine_button7.wav")
			else
				return "@notNow"
			end
		else
			return "@needRequestDevice"
		end
	end

	ix.command.Add("Request", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.text

	function COMMAND:OnRun(client, message)
		if (!client:IsRestricted()) then
			ix.chat.Send(client, "broadcast", message)
		else
			return "@notNow"
		end
	end

	ix.command.Add("Broadcast", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.adminOnly = true
	COMMAND.arguments = {
		ix.type.character,
		ix.type.text
	}

	function COMMAND:OnRun(client, target, permit)
		local itemTable = ix.item.Get("permit_" .. permit:lower())

		if (itemTable) then
			target:GetInventory():Add(itemTable.uniqueID)
		end
	end

	ix.command.Add("PermitGive", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.adminOnly = true
	COMMAND.arguments = {
		ix.type.character,
		ix.type.text
	}
	COMMAND.syntax = "<string name> <string permit>"

	function COMMAND:OnRun(client, target, permit)
		local inventory = target:GetInventory()
		local itemTable = inventory:HasItem("permit_" .. permit:lower())

		if (itemTable) then
			inventory:Remove(itemTable.id)
		end
	end

	ix.command.Add("PermitTake", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = ix.type.character

	function COMMAND:OnRun(client, target)
		local targetClient = target:GetPlayer()

		if (!hook.Run("CanPlayerViewData", client, targetClient)) then
			return "@cantViewData"
		end

		netstream.Start(client, "ViewData", targetClient, target:GetData("cid") or false, target:GetData("combineData"))
	end

	ix.command.Add("ViewData", COMMAND)
end

do
	local COMMAND = {}

	function COMMAND:OnRun(client, arguments)
		if (!hook.Run("CanPlayerViewObjectives", client)) then
			return "@noPerm"
		end

		netstream.Start(client, "ViewObjectives", Schema.CombineObjectives)
	end

	ix.command.Add("ViewObjectives", COMMAND)
end

do
	local COMMAND = {}

	function COMMAND:OnRun(client, arguments)
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 96
			data.filter = client
		local target = util.TraceLine(data).Entity

		if (IsValid(target) and target:IsPlayer() and target:IsRestricted()) then
			if (!client:IsRestricted()) then
				Schema:SearchPlayer(client, target)
			else
				return "@notNow"
			end
		end
	end

	ix.command.Add("CharSearch", COMMAND)
end

ix.command.Add("CharSpawn", {
	description = "@cmdCharSpawn",
	adminOnly = true,
	arguments = {
		ix.type.player
	},
	OnRun = function(self, client, target)
		target:Spawn()
		
		if client == target then
			client:NotifyLocalized("charSpawn01")
		else
			client:NotifyLocalized("charSpawn02", target:GetName())
			target:NotifyLocalized("charSpawn03", client:GetName())
		end
	end
})

ix.command.Add("Revive", {
	description = "@cmdRevive",
	adminOnly = true,
	arguments = {
		ix.type.player
	},
	OnRun = function(self, client, target)
		local ragdoll = target:GetRagdollEntity()

		if (!IsValid(ragdoll)) then
			for _, v in ipairs(ents.FindByClass("prop_ragdoll")) do
				if (v:GetNetVar("player") == target) then
					ragdoll = v
					break
				end
			end
		end

		local pos = IsValid(ragdoll) and ragdoll:GetPos() or target:GetPos()
		local angles = IsValid(ragdoll) and ragdoll:GetAngles() or target:GetAngles()

		target:Spawn()

		timer.Simple(0, function()
			if (IsValid(target)) then
				target:SetPos(pos)
				target:SetEyeAngles(Angle(0, angles.y, 0))
			end
		end)

		if (IsValid(ragdoll)) then
			ragdoll:Remove()
		end
		
		if client == target then
			client:NotifyLocalized("revive01")
		else
			client:NotifyLocalized("revive02", target:GetName())
			target:NotifyLocalized("revive03", client:GetName())
		end
	end
})

ix.command.Add("CharSetName", {
	description = "@cmdCharSetName",
	adminOnly = true,
	arguments = {
		ix.type.character,
		bit.bor(ix.type.text, ix.type.optional)
	},
	OnRun = function(self, client, target, name)
		-- display string request panel if no name was specified
		if (!isstring(name) or !name:find("%S")) then
			return client:RequestString("@cmdCharSetNameTitle", "@cmdCharSetNameDescription", function(text)
				ix.command.Run(client, "CharSetName", {target:GetName(), text})
			end, target:GetName())
		end

		name = string.Trim(name)

		if (name == "") then
			return "@invalidArg", 2
		end

		-- intentionally skip character var length validation for admin-set values
		target:SetName(name)
	end
})

ix.command.Add("CharSetDesc", {
	description = "@cmdCharDesc",
	adminOnly = true,
	arguments = {
		ix.type.character,
		bit.bor(ix.type.text, ix.type.optional)
	},
	OnRun = function(self, client, target, description)
		-- display string request panel if no name was specified
		if (!isstring(description) or !description:find("%S")) then
			return client:RequestString("@cmdCharDescTitle", "@cmdCharDescDescription", function(text)
				ix.command.Run(client, "CharSetDesc", {target:GetName(), text})
			end, target:GetDescription())
		end

		description = string.Trim(description)

		if (description == "") then
			return "@invalidArg", 2
		end

		-- intentionally skip character var length validation for admin-set values
		target:SetDescription(description)
	end
})

ix.command.Add("CharSetId", {
	description = "@cmdCharSetId",
	adminOnly = true,
	arguments = {
		ix.type.player,
	},
	OnRun = function(self, client, target)
		local id = Schema:ZeroNumber(math.random(1, 99999), 5)
		local character = target:GetCharacter()
		local inventory = character:GetInventory()

		if character:GetData("cid", id) then
			id = character:GetData("cid", id)
		end

		if !inventory:HasItem("cid") then
			inventory:Add("cid", 1, {
				name = character:GetName(),
				id = id
			})
		end
		
		character:SetData("cid", id)
		client:NotifyLocalized(id)
	end
})
