local PLUGIN = PLUGIN

PLUGIN.name = "Spawn Notifications"
PLUGIN.description = "A notification which tells the player their status on loading the character."
PLUGIN.author = "Riggs Mackay"
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright 2022 Riggs Mackay

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

-- Feel free to change any of these messages.
local wakeupMessages = {
	-- "wakes up from a long nap and recover from your sleep.",
	-- "stands up and sniffing the fresh air from the world.",
	-- "starts to stand up and recover from your sleep.",
	-- "are sweating from all the scare you have been getting from your dream and you wake up.",
	-- "were dreaming of someone and you heard their voice, you started to wake up.",
	-- "hears a small whisper in your ear, after that you hear loud footsteps fading away, you wake up being scared.",
	-- "hears a loud helicopter overhead of yourself and you instantly wake up.",
	-- "heard a growling and you started to wake up but scared.",
	-- "heard a loud siren and you are scared of the noise.",
	"서늘한 바람을 느끼며 정신을 차립니다.",
	"길을 걷다가 문득 무언가 떠올린 듯한 표정을 짓더니 멈춰섭니다.",
	"하품을 크게 하고 주변을 두리번거립니다.",
	"눈을 크게 끔뻑이고는 발길을 재촉합니다.",
	"순간 인기척을 느끼고 뒤를 돌아봅니다",
}

PLUGIN.lastWakeupByPlayer = PLUGIN.lastWakeupByPlayer or {}
PLUGIN.lastWakeupAtByCharacter = PLUGIN.lastWakeupAtByCharacter or {}

function PLUGIN:PlayerLoadedCharacter(client, character)
	if (CLIENT) then
		return
	end

	if (!IsValid(client) or !character) then
		return
	end

	-- Only fire for the character that has just been loaded.
	if (client:GetCharacter() != character) then
		return
	end

	-- Exclude Combine from this behavior.
	if (client:IsCombine()) then
		return
	end

	local steamID64 = client:SteamID64() or tostring(client:EntIndex())
	local charID = character:GetID()
	local timerID = "ixWakeupMessage_" .. steamID64

	-- Prevent duplicate pending callbacks for the same player.
	if (timer.Exists(timerID)) then
		timer.Remove(timerID)
	end

	-- Small delay so name/faction visuals are fully updated clientside.
	timer.Create(timerID, 0.1, 1, function()
		if (!IsValid(client)) then
			return
		end

		local currentCharacter = client:GetCharacter()

		if (!currentCharacter or currentCharacter:GetID() != charID or client:IsCombine()) then
			return
		end

		-- Same character was already processed recently; skip duplicate fire.
		if (PLUGIN.lastWakeupByPlayer[steamID64] == charID) then
			return
		end

		local dedupeKey = steamID64 .. ":" .. tostring(charID)
		local lastWakeupAt = PLUGIN.lastWakeupAtByCharacter[dedupeKey]

		-- Hard guard against duplicate hook fires in the same load cycle.
		if (lastWakeupAt and (CurTime() - lastWakeupAt) < 5) then
			return
		end

		PLUGIN.lastWakeupByPlayer[steamID64] = charID
		PLUGIN.lastWakeupAtByCharacter[dedupeKey] = CurTime()

		client:ConCommand("play music/stingers/hl1_stinger_song16.mp3")
		client:ScreenFade(SCREENFADE.IN, color_black, 3, 2)

		local msg = table.Random(wakeupMessages)
		ix.chat.Send(client, "me", msg)
	end)
end

function PLUGIN:OnCharacterDisconnect(client, character)
	if (CLIENT) then
		return
	end

	if (!IsValid(client)) then
		return
	end

	local steamID64 = client:SteamID64() or tostring(client:EntIndex())
	PLUGIN.lastWakeupByPlayer[steamID64] = nil
end
