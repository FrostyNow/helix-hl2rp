local PLUGIN = PLUGIN

resource.AddWorkshop("2291046370") -- the content addon

-- Redundant constants and functions moved to sh_plugin.lua

function PLUGIN:PlayerMessageSend(speaker, chatType, text, anonymous, receivers, rawText)
	if (chatType == "breencast") then
		local voiceText = isstring(rawText) and rawText or text
		local sounds, message = Schema.voices.GetVoiceList("breencast", voiceText)

		if (sounds) then
			netstream.Start(nil, "voicePlay", sounds, 80, nil, false, "breencast")
			return message
		end

		return text
	end

	if (chatType == "ic" or chatType == "w" or chatType == "y" or chatType == "dispatch" or chatType == "radio" or chatType == "radio_yell" or chatType == "radio_whisper" or chatType == "radio_eavesdrop" or chatType == "radio_eavesdrop_yell" or chatType == "radio_eavesdrop_whisper" or chatType == "broadcast" or chatType == "request" or chatType == "request_eavesdrop") then
		local class = Schema.voices.GetClass(speaker)
		local mode = self:GetModeFromChatType(chatType)
		
		for _, definition in ipairs(class) do
			if (!self:IsClassAllowedForMode(speaker, definition, mode)) then
				continue
			end

			local voiceText = isstring(rawText) and rawText or text
			local sounds, message = Schema.voices.GetVoiceList(definition, voiceText)

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
				local isRadioTransmission = mode == self.MODE_RADIO
				local voiceClassName = string.lower(definition or "")
				local isEavesdrop = string.find(chatType, "eavesdrop")

				if (isGlobalVoice) then
					netstream.Start(nil, "voicePlay", sounds, volume, nil, isRadioTransmission, voiceClassName)
				else
					local threshold = PLUGIN.radioNoiseDistanceSqr
					local scanner = speaker:GetNetVar("ixScn")
					local speakerIndex = (IsValid(scanner) and !isRadioTransmission) and scanner:EntIndex() or speaker:EntIndex()

					if (!isEavesdrop) then
						netstream.Start(nil, "voicePlay", sounds, volume, speakerIndex, isRadioTransmission, voiceClassName)
					end
	
					if (isRadioTransmission and receivers) then
						local playedPositions = {speaker:GetPos()}

						for k, v in pairs(receivers) do
							if (v == speaker) then
								continue
							end

							local pos = v:GetPos()
							local alreadyAudible = false

							for _, p in ipairs(playedPositions) do
								if (pos:DistToSqr(p) <= threshold) then
									alreadyAudible = true
									break
								end
							end

							if (alreadyAudible) then
								continue
							end

							playedPositions[#playedPositions + 1] = pos
							netstream.Start(nil, "voicePlay", sounds, volume * 0.45, v:EntIndex(), isRadioTransmission, voiceClassName)
						end
					end
						
					if (Schema:CanPlayerSeeCombineOverlay(speaker)) then
						speaker.bTypingBeep = nil

						if (speaker:Team() == FACTION_MPF) then
							sounds[#sounds + 1] = "NPC_MetroPolice.Radio.Off"
						else
							sounds[#sounds + 1] = "Vocoder.Off"
						end
					end
				end
				
				if (Schema:CanPlayerSeeCombineOverlay(speaker)) then
					return Schema:WrapCombineChatText(message)
				else
					return message
				end
			end
		end

		if (Schema:CanPlayerSeeCombineOverlay(speaker) or chatType == "dispatch") then
			if (sounds) then
				return text
			end

			return Schema:WrapCombineChatText(text)
		end
	end
	
	if (chatType == "broadcast") then
		netstream.Start(nil, "PlaySound", "aurawatch/admin/announce.wav")
	end
end

netstream.Hook("PlayerChatTextChanged", function(client, key)
	if (client:GetMoveType() != MOVETYPE_NOCLIP and Schema:CanPlayerSeeCombineOverlay(client) and !client.bTypingBeep
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
	if (client:GetMoveType() != MOVETYPE_NOCLIP and Schema:CanPlayerSeeCombineOverlay(client) and client.bTypingBeep) then
		if (client:Team() == FACTION_MPF) then
			client:EmitSound("NPC_MetroPolice.Radio.Off")
		else
			client:EmitSound("Vocoder.Off")
		end

		client.bTypingBeep = nil
	end
end)
