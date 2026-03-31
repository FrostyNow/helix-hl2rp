local PLUGIN = PLUGIN

PLUGIN.name = "Pager"
PLUGIN.author = "Frosty"
PLUGIN.description = "Adds a pager item that can be paired and used to signal others."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.lang.AddTable("english", {
	itemPagerDesc = "A communication device that sends and receives signals with another synchronized pager.",

	pagerSyncDesc = "Pair this pager with another person.",
	pagerSignalDesc = "Send a signal to the paired person.",
	pagerNoTarget = "You are not looking at anyone!",
	pagerSynced = "You have synchronized the pager with %s.",
	pagerNotSynced = "This pager is not synchronized with anyone.",
	pagerTargetOffline = "The paired person is no longer available.",
	pagerNoPager = "The target does not have a pager to synchronize with!",
	pagerSignalSent = "The signal has been sent.",
	pagerCooldown = "The pager is recharging! Please wait before sending another signal.",

	pagerButtonDesc = "A button that signals all paired pagers when pressed.",
	pagerButtonUsage = "Press <USE> to signal connected pagers.",
	
	pagerReceive1 = "The pager beeps softly.",
	pagerReceive2 = "A small device vibrates and emits a beep.",
	pagerReceive3 = "The pager makes a short notification sound.",
	pagerReceive4 = "A faint electronic beep comes from a pager.",

	novelizerPagerUse1 = "keys a signal into the pager.",
	novelizerPagerUse2 = "thumbs the button on the pager to send a signal.",
	novelizerPagerUse3 = "sends a quick pulse through the pager.",

	pagerButtonFail1 = "presses the button, but it makes a dry clicking sound with no further response.",
	pagerButtonFail2 = "keys the button fruitlessly as it fails to connect with any active receiver.",
	pagerButtonFail3 = "pushes the button, but only a faint electronic hum follows, indicating no signal was sent.",

	sentButtonSignals = "Pager signal sent to %s paired pagers.",
})

ix.lang.AddTable("korean", {
	["Pager"] = "호출기",
	itemPagerDesc = "동기화된 다른 호출기와 신호를 주고받는 통신 장치입니다.",
	["Pager Button"] = "호출 버튼",
	["Sync"] = "동기화",
	pagerSyncDesc = "이 호출기를 다른 사람과 동기화합니다.",
	["Send Signal"] = "신호 보내기",
	pagerSignalDesc = "동기화된 상대에게 신호를 보냅니다.",
	pagerNoTarget = "대상을 조준하고 있지 않습니다!",
	pagerSynced = "%s에 호출기를 동기화했습니다.",
	pagerNotSynced = "이 호출기는 아직 누구와도 동기화되지 않았습니다.",
	pagerTargetOffline = "동기화된 상대가 현재 접속 중이 아닙니다.",
	pagerNoPager = "상대방이 동기화할 호출기 아이템을 가지고 있지 않습니다!",
	pagerSignalSent = "신호를 전송했습니다.",
	pagerCooldown = "호출기가 재충전 중입니다! 잠시 후 다시 시도해 주세요.",

	pagerButtonDesc = "눌렀을 때 연결된 모든 호출기에 신호를 보냅니다.",
	pagerButtonUsage = "<사용>하여 연결된 호출기에 신호를 보냅니다.",

	pagerReceive1 = "호출기가 부드럽게 울립니다.",
	pagerReceive2 = "작은 기기가 진동하며 삐 소리를 냅니다.",
	pagerReceive3 = "호출기에서 짧은 신호음이 들립니다.",
	pagerReceive4 = "호출기에서 희미한 삐 소리가 들려옵니다.",

	novelizerPagerUse1 = "호출기로 신호를 보냅니다.",
	novelizerPagerUse2 = "호출기의 버튼을 눌러 신호를 발신합니다.",
	novelizerPagerUse3 = "호출기를 조작해 짧은 신호를 보냅니다.",

	pagerButtonFail1 = "버튼을 누르지만, 마른 클릭 소리만 날 뿐 아무런 반응이 없습니다.",
	pagerButtonFail2 = "버튼을 조작하지만 연결된 수신기가 없어 신호가 전송되지 않습니다.",
	pagerButtonFail3 = "버튼을 누르지만 희미한 전자음만 들릴 뿐 신호는 가지 않습니다.",

	sentButtonSignals = "호출기 %s개에 신호를 보냈습니다.",
})

-- Common function to send a localized chat message directly to players in range
local function SendLocalizedProximityChat(speaker, chatType, phraseKey)
	local class = ix.chat.classes[chatType]
	if (!class) then return end

	for _, v in player.Iterator() do
		-- Suppress IC messages for noclipping or dead players
		if (v:GetMoveType() == MOVETYPE_NOCLIP or !v:Alive()) then continue end
		
		if (v:GetCharacter() and class:CanHear(speaker, v)) then
			net.Start("ixChatMessage")
				net.WriteEntity(speaker)
				net.WriteString(chatType)
				net.WriteString(L(phraseKey, v))
				net.WriteBool(false)
				net.WriteTable({})
			net.Send(v)
		end
	end
end

function PLUGIN:SendPagerMe(client)
	-- Suppress signal action if sender is noclipping or dead
	if (client:GetMoveType() == MOVETYPE_NOCLIP or !client:Alive()) then
		return
	end

	local phrases = { "novelizerPagerUse1", "novelizerPagerUse2", "novelizerPagerUse3" }
	local phrase = table.Random(phrases)

	client:EmitSound("buttons/button18.wav", 60, 120)
	SendLocalizedProximityChat(client, "me", phrase)
end

function PLUGIN:SendPagerIt(target)
	-- If it's a player, check if they can physically produce/receive the sound (not noclip/dead)
	if (target:IsPlayer() and (target:GetMoveType() == MOVETYPE_NOCLIP or !target:Alive())) then
		return
	end

	local phrases = { "pagerReceive1", "pagerReceive2", "pagerReceive3", "pagerReceive4" }
	local phrase = table.Random(phrases)

	target:EmitSound("buttons/blip1.wav", 75, 110)
	SendLocalizedProximityChat(target, "it", phrase)
end

function PLUGIN:SendPagerButtonFail(client)
	if (client:GetMoveType() == MOVETYPE_NOCLIP or !client:Alive()) then
		return
	end

	local phrases = { "pagerButtonFail1", "pagerButtonFail2", "pagerButtonFail3" }
	local phrase = table.Random(phrases)

	client:EmitSound("buttons/combine_button_locked.wav", 60, 100)
	SendLocalizedProximityChat(client, "me", phrase)
end
