local PLUGIN = PLUGIN

resource.AddWorkshop("2291046370") -- the content addon

local MODE_NORMAL = "normal"
local MODE_RADIO = "radio"
local MODE_BROADCAST = "broadcast"
local MODE_DISPATCH = "dispatch"

local function GetModeFromChatType(chatType)
	if (chatType == "broadcast") then
		return MODE_BROADCAST
	end

	if (chatType == "dispatch") then
		return MODE_DISPATCH
	end

	if (chatType == "radio" or chatType == "radio_yell" or chatType == "radio_whisper"
	or chatType == "radio_eavesdrop" or chatType == "radio_eavesdrop_yell"
	or chatType == "radio_eavesdrop_whisper" or chatType == "request"
	or chatType == "request_eavesdrop") then
		return MODE_RADIO
	end

	if (chatType == "ic" or chatType == "w" or chatType == "y") then
		return MODE_NORMAL
	end
end

local function IsClassAllowedForMode(className, mode)
	local lowered = string.lower(className or "")

	if (lowered == "breencast") then
		return mode == MODE_BROADCAST
	end

	if (lowered == "dispatch") then
		return mode == MODE_DISPATCH
	end

	if (lowered == "overwatch") then
		return mode == MODE_RADIO
	end

	return mode == MODE_NORMAL or mode == MODE_RADIO
end

function Schema:PlayerMessageSend(speaker, chatType, text, anonymous, receivers, rawText)
	if (chatType == "ic" or chatType == "w" or chatType == "y" or chatType == "dispatch" or chatType == "radio" or chatType == "radio_yell" or chatType == "radio_whisper" or chatType == "radio_eavesdrop" or chatType == "radio_eavesdrop_yell" or chatType == "radio_eavesdrop_whisper" or chatType == "broadcast" or chatType == "request" or chatType == "request_eavesdrop") then
		local class = self.voices.GetClass(speaker)
		local mode = GetModeFromChatType(chatType)
		
		for _, definition in ipairs(class) do
			if (!IsClassAllowedForMode(definition, mode)) then
				continue
			end

			local sounds, message = self.voices.GetVoiceList(definition, rawText)

			if (sounds) then
				local volume = 80
	
				if (chatType == "w" or chatType == "radio_whisper" or chatType == "radio_eavesdrop_whisper") then
					volume = 60
				elseif (chatType == "y" or chatType == "radio_yell" or chatType == "radio_eavesdrop_yell") then
					volume = 150
				end
				
				if (definition.onModify) then
					if (definition.onModify(speaker, sounds, chatType, text) == false) then
						continue
					end
				end
	
				local isGlobalVoice = definition.global
					or chatType == "dispatch"
					or chatType == "broadcast"
				local isRadioTransmission = mode == MODE_RADIO
				local voiceClassName = string.lower(definition or "")

				if (isGlobalVoice) then
					netstream.Start(nil, "voicePlay", sounds, volume, nil, isRadioTransmission, voiceClassName)
				else
					netstream.Start(nil, "voicePlay", sounds, volume, speaker:EntIndex(), isRadioTransmission, voiceClassName)
	
					if ((chatType == "radio" or chatType == "radio_yell" or chatType == "radio_whisper" or chatType == "radio_eavesdrop" or chatType == "radio_eavesdrop_yell" or chatType == "radio_eavesdrop_whisper" or chatType == "request" or chatType == "request_eavesdrop") and receivers) then
						for k, v in pairs(receivers) do
							if (v == speaker) then
								continue
							end
	
							netstream.Start(nil, "voicePlay", sounds, volume * 0.9, v:EntIndex(), isRadioTransmission, voiceClassName)
						end
					end
						
					if (speaker:IsCombine()) then
						speaker.bTypingBeep = nil

						if (speaker:Team() == FACTION_MPF) then
							sounds[#sounds + 1] = "NPC_MetroPolice.Radio.Off"
						else
							sounds[#sounds + 1] = "Vocoder.Off"
						end
					end
				end
				
				if (speaker:IsCombine()) then
					return string.format("<:: %s ::>", message)
				else
					return message
				end
			end
		end

		if (speaker:IsCombine()) then
			return string.format("<:: %s ::>", text)
		end
	end
	
	if (chatType == "broadcast") then
		netstream.Start(nil, "PlaySound", "aurawatch/admin/announce.wav")
	end
end

netstream.Hook("PlayerChatTextChanged", function(client, key)
	if (client:GetMoveType() != MOVETYPE_NOCLIP and client:IsCombine() and !client.bTypingBeep
	and (key == "y" or key == "w" or key == "r" or key == "t")) then
		if (client:Team() == FACTION_MPF) then
			client:EmitSound("NPC_MetroPolice.Radio.On")
		else
			client:EmitSound("Vocoder.On")
		end

		client.bTypingBeep = true
	end
end)

netstream.Hook("PlayerFinishChat", function(client)
	if (client:GetMoveType() != MOVETYPE_NOCLIP and client:IsCombine() and client.bTypingBeep) then
		if (client:Team() == FACTION_MPF) then
			client:EmitSound("NPC_MetroPolice.Radio.Off")
		else
			client:EmitSound("Vocoder.Off")
		end

		client.bTypingBeep = nil
	end
end)
