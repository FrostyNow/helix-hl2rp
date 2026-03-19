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

	COMMAND.alias = "B"
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
		if (ix.plugin.Get("interactive_computers")) then
			return "@useComputerTerminal"
		end

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
		if (ix.plugin.Get("interactive_computers")) then
			return "@useComputerTerminal"
		end

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

ix.command.Add("Promote", {
	description = "@cmdPromote",
	arguments = ix.type.character,
	OnRun = function(self, client, target)
		if (!Schema:CanPromote(client)) then
			return "@notAllowed"
		end

		local success, newRank = Schema:Promote(target, client)

		if (success) then
			local targetPlayer = target:GetPlayer()
			if (IsValid(targetPlayer)) then
				targetPlayer:NotifyLocalized("promotedTo", newRank)
			end
			client:NotifyLocalized("promotedTarget", target:GetName(), newRank)
		else
			return "@cantPromoteFurther"
		end
	end
})

ix.command.Add("Demote", {
	description = "@cmdDemote",
	arguments = ix.type.character,
	OnRun = function(self, client, target)
		if (!Schema:CanPromote(client)) then
			return "@notAllowed"
		end

		local success, newRank = Schema:Demote(target, client)

		if (success) then
			local targetPlayer = target:GetPlayer()
			if (IsValid(targetPlayer)) then
				targetPlayer:NotifyLocalized("demotedTo", newRank)
			end
			client:NotifyLocalized("demotedTarget", target:GetName(), newRank)
		else
			return "@cantDemoteFurther"
		end
	end
})

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

				if (target.ixDeathAmmo) then
					for ammoID, amount in pairs(target.ixDeathAmmo) do
						target:SetAmmo(amount, ammoID)
					end
					target.ixDeathAmmo = nil
				end

				if (target.ixDeathWeapons) then
					for _, v in ipairs(target:GetWeapons()) do
						local data = target.ixDeathWeapons[v:GetClass()]
						
						if (data) then
							v:SetClip1(data.clip1 or -1)
							v:SetClip2(data.clip2 or -1)
						end
					end
					target.ixDeathWeapons = nil
				end

				if (target.ixDeathHunger) then
					target:SetHunger(target.ixDeathHunger)
					target.ixDeathHunger = nil
				end

				if (target.ixDeathThirst) then
					target:SetThirst(target.ixDeathThirst)
					target.ixDeathThirst = nil
				end
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

ix.command.Add("Promote", {
	description = "@cmdPromote",
	arguments = ix.type.character,
	OnRun = function(self, client, target)
		if (!Schema:CanPromote(client)) then
			return "@notAllowed"
		end

		local success, newRank = Schema:Promote(target, client)

		if (success) then
			local targetPlayer = target:GetPlayer()
			if (IsValid(targetPlayer)) then
				targetPlayer:NotifyLocalized("promotedTo", newRank)
			end
			client:NotifyLocalized("promotedTarget", target:GetName(), newRank)
		else
			return "@cantPromoteFurther"
		end
	end
})

ix.command.Add("Demote", {
	description = "@cmdDemote",
	arguments = ix.type.character,
	OnRun = function(self, client, target)
		if (!Schema:CanPromote(client)) then
			return "@notAllowed"
		end

		local success, newRank = Schema:Demote(target, client)

		if (success) then
			local targetPlayer = target:GetPlayer()
			if (IsValid(targetPlayer)) then
				targetPlayer:NotifyLocalized("demotedTo", newRank)
			end
			client:NotifyLocalized("demotedTarget", target:GetName(), newRank)
		else
			return "@cantDemoteFurther"
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
			return client:RequestString("@cmdCharSetNameTitle", "@cmdCharSetName", function(text)
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

ix.command.Add("GiveCID", {
	description = "@cmdGiveCID",
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
		
		for _, v in pairs(inventory:GetItems()) do
			if (v.uniqueID == "cid") then
				v:SetData("name", character:GetName())
				v:SetData("id", id)
				if character:GetClass() == CLASS_CWU then
					v:SetData("class", "Civil Worker's Union")
				elseif character:GetClass() == CLASS_ELITE_CITIZEN then
					v:SetData("class", "First Class Citizen")
				else
					v:SetData("class", "Second Class Citizen")
				end
			end
		end
		
		character:SetData("cid", id)
		Schema:SyncCitizenID(target, character)
		client:NotifyLocalized("givenCID", target:GetName(), id)
		target:NotifyLocalized("givenCIDTarget", client:GetName(), id)
	end
})

ix.command.Add("Heal", {
	description = "@cmdHeal",
	adminOnly = true,
	arguments = {
		ix.type.player
	},
	OnRun = function(self, client, target)
		if (target:IsPlayer() and target:GetCharacter() and target:Alive()) then
			target:SetHealth(target:GetMaxHealth() or 100)

			if (ix.plugin.list["hunger"]) then
				target:SetHunger(100)
				target:SetThirst(100)
			end

			if (ix.plugin.list["badair"]) then
				target:SetLocalVar("toxicity", 0)
			end

			client:NotifyLocalized("targetHealed", target:GetName())
		else
			client:NotifyLocalized("unknownError")
		end
	end
})

ix.command.Add("ItemRemove", {
	description = "@cmdItemRemove",
	adminOnly = true,
	arguments = {
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, range)
		range = range or 20

		local trace = client:GetEyeTraceNoCursor()
		local pos = trace.HitPos
		local count = 0

		for _, v in ipairs(ents.FindInSphere(pos, range)) do
			if (v:GetClass() == "ix_item") then
				v:Remove()
				count = count + 1
			end
		end

		if (count > 0) then
			client:NotifyLocalized("itemsRemoved", count)
		else
			client:NotifyLocalized("noItemsInRange")
		end
	end
})

ix.command.Add("ServerCfg", {
	alias = {"ServerCfg", "Cfg", "Hostname", "Password", "Pw"},
	description = "@cmdServerCfg",
	superAdminOnly = true,
	arguments = {
		ix.type.string,
		bit.bor(ix.type.text, ix.type.optional)
	},
	syntax = "<string hostname> [string password]",
	OnRun = function(self, client, hostname, password)
		if (hostname and hostname != "") then
			RunConsoleCommand("hostname", hostname)
		end

		if (password) then
			RunConsoleCommand("sv_password", password)
		end

		return "@serverCfgChanged"
	end
})

concommand.Add("ix_dev_ammo", function()
	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) then
		local ammoTypeID = wep:GetPrimaryAmmoType()
		local ammo = game.GetAmmoName(ammoTypeID)
		print(ammo) -- Prints the ID to console
	end
end)

ix.command.Add("HUDReset", {
	description = "@cmdHUDReset",
	OnCanRun = function(self, client)
		return Schema:CanPlayerSeeCombineOverlay(client)
	end,
	OnRun = function(self, client)
		netstream.Start(client, "ixHUDReset")
		return "@hudResetMessage"
	end
})