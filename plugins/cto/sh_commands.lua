
local PLUGIN = PLUGIN

do
	local COMMAND = {}
	COMMAND.description = "@cameraDisableDesc"
	COMMAND.arguments = {
		ix.type.number
	}

	function COMMAND:OnRun(client, ID)
		local camera = Entity(ID)

		if (!IsEntity(camera) or camera:GetClass() != "npc_combine_camera") then
			client:NotifyLocalized("cameraInvalid")

			return
		end

		if (camera:GetSequenceName(camera:GetSequence()) != "idlealert") then
			client:NotifyLocalized("cameraAlreadyDisabled")

			return
		end

		client:NotifyLocalized("cameraDisabled", camera:EntIndex())

		camera:Fire("Disable")
	end

	function COMMAND:OnCheckAccess(client)
		return client:IsCombine() and (client:IsAdmin() or Schema:IsCombineRank(client:Name(), "SCN") or Schema:IsCombineRank(client:Name(), "OfC") or Schema:IsCombineRank(client:Name(), "EpU") or Schema:IsCombineRank(client:Name(), "DvL") or Schema:IsCombineRank(client:Name(), "SeC") or client:Team() == FACTION_OTA)
	end

	ix.command.Add("CameraDisable", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.arguments = {
		ix.type.number
	}

	function COMMAND:OnRun(client, ID)
		local camera = Entity(ID)

		if (!IsEntity(camera) or camera:GetClass() != "npc_combine_camera") then
			client:NotifyLocalized("cameraInvalid")

			return
		end

		if (camera:GetSequenceName(camera:GetSequence()) != "idle") then
			client:NotifyLocalized("cameraAlreadyEnabled")

			return
		end

		client:NotifyLocalized("cameraEnabled", camera:EntIndex())

		camera:Fire("Enable")
	end

	function COMMAND:OnCheckAccess(client)
		return client:IsCombine() and (client:IsAdmin() or Schema:IsCombineRank(client:Name(), "SCN") or Schema:IsCombineRank(client:Name(), "OfC") or Schema:IsCombineRank(client:Name(), "EpU") or Schema:IsCombineRank(client:Name(), "DvL") or Schema:IsCombineRank(client:Name(), "SeC") or client:Team() == FACTION_OTA)
	end

	ix.command.Add("CameraEnable", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "@socioStatusDesc"
	COMMAND.arguments = {
		ix.type.string
	}
	COMMAND.argumentNames = {"Socio-Status (green | blue | yellow | red | black)"}
	COMMAND.alias = {"SocioStatus"}

	function COMMAND:OnRun(client, socioStatus)
		local tryingFor = string.upper(socioStatus)

		if (!PLUGIN.sociostatusColors[tryingFor]) then
			client:NotifyLocalized("socioInvalid")
		else
			local players = {}

			local pitches = {
				BLUE = 95,
				YELLOW = 90,
				RED = 85,
				BLACK = 80
			}

			local pitch = pitches[tryingFor] or 100
		
			for k, v in ipairs(player.GetAll()) do
				if (v:IsCombine() and !v:GetNetVar("IsBiosignalGone", false)) then
					players[#players + 1] = v

					timer.Simple(k / 4, function()
						if (IsValid(v)) then
							v:EmitSound("npc/roller/code2.wav", 75, pitch)
						end
					end)
				end
			end

			PLUGIN.socioStatus = tryingFor
			
			Schema:AddCombineDisplayMessage("@socioStatusUpdated", PLUGIN.sociostatusColors[tryingFor], L(tryingFor, client))
			
			net.Start("RecalculateHUDObjectives")
				net.WriteString(PLUGIN.socioStatus)
				net.WriteTable(Schema.CombineObjectives)
			net.Send(players)
		end
	end

	function COMMAND:OnCheckAccess(client)
		return client:IsCombine() and (client:IsAdmin() or Schema:IsCombineRank(client:Name(), "SCN") or Schema:IsCombineRank(client:Name(), "OfC") or Schema:IsCombineRank(client:Name(), "EpU") or Schema:IsCombineRank(client:Name(), "DvL") or Schema:IsCombineRank(client:Name(), "SeC") or client:Team() == FACTION_OTA)
	end

	ix.command.Add("SetSocioStatus", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "@bioDesc"
	COMMAND.arguments = {
		ix.type.bool
	}
	COMMAND.alias = {"Bio", "Biosignal"}

	function COMMAND:OnRun(client, bEnable)
		local result = PLUGIN:SetPlayerBiosignal(client, bEnable)

		if (result == PLUGIN.ERROR_ALREADY_ENABLED) then
			client:NotifyLocalized("bioAlreadyOn")
		elseif (result == PLUGIN.ERROR_ALREADY_DISABLED) then
			client:NotifyLocalized("bioAlreadyOff")
		end
	end

	function COMMAND:OnCheckAccess(client)
		return client:IsCombine() and ix.config.Get("useBiosignalSystem")
	end

	ix.command.Add("SetBiosignalStatus", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "@charSetBioDesc"
	COMMAND.adminOnly = true
	COMMAND.arguments = {
		ix.type.player,
		ix.type.bool
	}
	COMMAND.alias = {"CharSetBio", "CharSetBiosignal"}

	function COMMAND:OnRun(client, target, bEnable)
		local result = PLUGIN:SetPlayerBiosignal(target, bEnable)
	
		if (result == PLUGIN.ERROR_NOT_COMBINE) then
			client:NotifyLocalized("targetNotCombine", target:Name())
		elseif (result == PLUGIN.ERROR_ALREADY_ENABLED) then
			client:NotifyLocalized("targetBioAlreadyOn", target:Name())
		elseif (result == PLUGIN.ERROR_ALREADY_DISABLED) then
			client:NotifyLocalized("targetBioAlreadyOff", target:Name())
		else
			client:NotifyLocalized("bioSet", target:Name(), bEnable and L("enabled") or L("disabled"))
		end
	end

	function COMMAND:OnCheckAccess(client)
		return client:IsAdmin() and ix.config.Get("useBiosignalSystem")
	end

	ix.command.Add("CharSetBiosignalStatus", COMMAND)
end

-- do
-- 	local COMMAND = {}
-- 	COMMAND.description = "Set whether a Citizen has CID tags on their clothes."
-- 	COMMAND.arguments = {
-- 		ix.type.player,
-- 		ix.type.bool
-- 	}

-- 	function COMMAND:OnRun(client, target, hasTags)
-- 		if (hasTags and !target:GetCharacter():GetData("IsCIDTagGone")) then
-- 			client:Notify(target:Name() .. " already has CID tags!")
-- 		elseif (!hasTags and target:GetCharacter():GetData("IsCIDTagGone")) then
-- 			client:Notify(target:Name() .. " already has no CID tags!")
-- 		else
-- 			client:GetCharacter():SetData("IsCIDTagGone", !hasTags)

-- 			client:Notify("You have " .. (hasTags and "added" or "removed") .. " " .. target:Name() .. "'s CID tags.")
-- 		end
-- 	end

-- 	function COMMAND:OnCheckAccess(client)
-- 		return client:IsAdmin() and ix.config.Get("useTagSystem")
-- 	end

-- 	ix.command.Add("CharSetHasTags", COMMAND)
-- end

do
	local COMMAND = {}
	COMMAND.description = "@requestDesc"
	COMMAND.arguments = ix.type.text
	COMMAND.alias = {"req"}

	function COMMAND:OnRun(client, message)
		if (!client:IsAdmin()) then
			local lastRequest = client.ixLastRequest or 0
			local cooldown = 20

			if (lastRequest + cooldown > CurTime()) then
				return "@requestCooldown", math.ceil(lastRequest + cooldown - CurTime())
			end
		end

		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		if (inventory:HasItem("request_device") or client:IsCombine() or client:Team() == FACTION_ADMIN) then
			if (!client:IsRestricted()) then
				Schema:AddCombineDisplayMessage("@cRequest")

				PLUGIN:DispatchRequestSignal(client, message)

				ix.chat.Send(client, "request", message)
				ix.chat.Send(client, "request_eavesdrop", message)

				client:EmitSound("buttons/combine_button7.wav")

				client.ixLastRequest = CurTime()
			else
				return "@notNow"
			end
		else
			return "@needRequestDevice"
		end
	end

	ix.command.Add("Request", COMMAND)
end
