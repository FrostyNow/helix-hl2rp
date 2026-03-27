local PLUGIN = PLUGIN
PLUGIN.name = "Whitelist & Flag Checker"
PLUGIN.author = "Frosty"
PLUGIN.description = "Provides admin commands to view whitelists and flags."

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")

ix.lang.AddTable("english", {
	cmdPlyCheckWhitelists = "Check all whitelisted players and their characters for a faction.",
	wlCheckerTitle = "Whitelist Checker - %s",
	wlCheckerSearch = "Search by Steam Name or SteamID...",
	wlCheckerName = "Steam Name",
	wlCheckerID = "SteamID64",
	wlCheckerWhitelisted = "Whitelisted",
	wlCheckerChars = "Characters",
	wlCheckerNoFlag = "No (Flag Use?)",
	wlCheckerCopyID = "Copy SteamID64",
	wlCheckerIDCopied = "SteamID copied to clipboard.",
	wlCheckerRemove = "Remove Whitelist",
	wlCheckerRemoveConfirm = "Are you sure you want to remove the %s whitelist from %s?",
	wlCheckerRemoveTitle = "Confirm Removal",
	wlCheckerRemovedLocal = "Removed %s whitelist from %s.",

	cmdPlyCheckFlags = "Check player-level and character-level flags for all players.",
	flCheckerTitle = "Flag Checker",
	flCheckerPlayerFlags = "Player Flags",
	flCheckerCharFlags = "Characters (Flags)",
	flCheckerSetPlayerFlags = "Set Player Flags",
	flCheckerSetCharFlags = "Set Character Flags (%s)",
	flCheckerSetPlayerFlagsTitle = "Set Player Flags - %s",
	flCheckerSetCharFlagsTitle = "Set Character Flags - %s",
	flCheckerFlagsInput = "Enter flags to set:",
	flCheckerFlagsUpdated = "Flags have been updated successfully."
})

ix.lang.AddTable("korean", {
	cmdPlyCheckWhitelists = "특정 세력의 모든 허가된 플레이어와 그들의 캐릭터를 확인합니다.",
	wlCheckerTitle = "화이트리스트 확인 - %s",
	wlCheckerSearch = "스팀 이름 또는 SteamID로 검색...",
	wlCheckerName = "스팀 이름",
	wlCheckerID = "SteamID64",
	wlCheckerWhitelisted = "화이트리스트",
	wlCheckerChars = "캐릭터 목록",
	wlCheckerNoFlag = "아니오 (플래그 사용?)",
	wlCheckerCopyID = "SteamID64 복사",
	wlCheckerIDCopied = "SteamID가 클립보드에 복사되었습니다.",
	wlCheckerRemove = "화이트리스트 제거",
	wlCheckerRemoveConfirm = "정말로 %s의 %s 화이트리스트를 제거하시겠습니까?",
	wlCheckerRemoveTitle = "제거 확인",
	wlCheckerRemovedLocal = "%s의 %s 화이트리스트가 제거되었습니다.",

	cmdPlyCheckFlags = "특정 플레이어들의 유저 플래그와 캐릭터별 플래그를 확인합니다.",
	flCheckerTitle = "플래그 확인",
	flCheckerPlayerFlags = "유저 플래그",
	flCheckerCharFlags = "캐릭터 (플래그)",
	flCheckerSetPlayerFlags = "유저 플래그 설정",
	flCheckerSetCharFlags = "캐릭터 플래그 설정 (%s)",
	flCheckerSetPlayerFlagsTitle = "유저 플래그 설정 - %s",
	flCheckerSetCharFlagsTitle = "캐릭터 플래그 설정 - %s",
	flCheckerFlagsInput = "부여할 플래그를 입력하세요:",
	flCheckerFlagsUpdated = "플래그가 성공적으로 업데이트되었습니다."
})

ix.command.Add("PlyCheckWhitelists", {
	description = "@cmdPlyCheckWhitelists",
	privilege = "Manage Whitelist",
	adminOnly = true,
	arguments = ix.type.text,
	OnRun = function(self, client, factionName)
		local targetFaction = nil
		
		for _, v in pairs(ix.faction.indices) do
			if (ix.util.StringMatches(v.uniqueID, factionName) or (v.name and ix.util.StringMatches(L(v.name, client), factionName))) then
				targetFaction = v
				break
			end
		end

		if (!targetFaction) then
			return "@invalidFaction"
		end

		if (SERVER) then
			PLUGIN:FetchWhitelistData(client, targetFaction)
		end
	end
})

ix.command.Add("PlyCheckFlags", {
	description = "@cmdPlyCheckFlags",
	privilege = "Manage Flags",
	adminOnly = true,
	OnRun = function(self, client)
		if (SERVER) then
			PLUGIN:FetchFlagData(client)
		end
	end
})
