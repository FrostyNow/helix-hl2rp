PLUGIN.name = "NPC Spawner"
PLUGIN.author = "Frosty"
PLUGIN.description = "Advanced NPC Spawner system."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.lang.AddTable("english", {
	npcSpawnerGlobalLimitDesc = "Maximum NPC spawn limit for the entire server.",
	optNpcSpawnerESP = "NPC Spawner ESP",
	optdNpcSpawnerESP = "Enable NPC Spawner ESP in Admin Observer mode.",
	cmdNPCSpawnerAddDesc = "Add a summon point at your aim position.",
	cmdNPCSpawnerRemoveDesc = "Remove a summon point near your aim position.",
	cmdNPCSpawnerEditDesc = "Open panel to edit the details of the specified summon point.",
	spawnerAlreadyExists = "A summon point with that ID already exists.",
	spawnerAdded = "Summon point '%s' has been added.",
	spawnerNotFound = "Could not find that summon point.",
	spawnerRemoved = "Summon point '%s' has been removed.",
	spawnerEditedMsg = "Summon point has been successfully edited.",
	spawnerTitle = "Edit Summon Point Settings",
	spawnerMaxSpawned = "Max Spawns per Point",
	spawnerMaxNearby = "Max Nearby NPCs",
	spawnerMinDistance = "Player No-Approach Dist",
	spawnerSpawnDelay = "Spawn Delay (sec)",
	spawnerActiveRadius = "Active Radius (units)",
	spawnerUseArea = "Use Area Instead of Radius",
	spawnerVisitCooldown = "Visit Cooldown (sec, 0 = off)",
	spawnerClassLabel = "NPC Classes & Spawn Weight",
	spawnerClassAdd = "Add Class",
	spawnerClassRemove = "Remove Selected Class",
	spawnerSave = "Save",
	spawnerClassPromptTitle = "Add Class",
	spawnerClassPromptDesc = "Enter NPC class name (e.g. npc_zombie)",
	spawnerWeightPromptTitle = "Set Weight",
	spawnerWeightPromptDesc = "Set spawn weight (num)",
	spawnerColumnClass = "Class",
	spawnerColumnWeight = "Weight",
	npcSpawnerESPPrefix = "NPC Spawner: %s",
	npcSpawnerESPInfo = "Delay: %ds | Max Spawned: %d | Max Nearby: %d",
	npcSpawnerESPClasses = "Classes",
	npcSpawnerESPNone = "None",
	cmdFlyByDesc = "Summons an aircraft from the map edge to your position. (gunship / helicopter)",
	flyByCalled = "%s inbound.",
	flyByNoRoute = "Could not find a valid flight route.",
	flyByInvalidType = "Invalid type. Use 'gunship' or 'helicopter'.",
})

ix.lang.AddTable("korean", {
	npcSpawnerGlobalLimitDesc = "서버 전체의 최대 NPC 소환 제한 수",
	optNpcSpawnerESP = "NPC 소환 지점 ESP",
	optdNpcSpawnerESP = "관리자 옵저버 모드에서 소환 지점 ESP 활성화 여부",
	cmdNPCSpawnerAddDesc = "조준하고 있는 위치에 소환 지점을 추가합니다.",
	cmdNPCSpawnerRemoveDesc = "조준하고 있는 위치 근처의 소환 지점을 삭제합니다.",
	cmdNPCSpawnerEditDesc = "해당 ID의 소환 지점 세부 설정을 패널을 통해 수정합니다.",
	spawnerAlreadyExists = "해당 ID를 가진 소환 지점이 이미 존재합니다.",
	spawnerAdded = "소환 지점 '%s' 이(가) 추가되었습니다.",
	spawnerNotFound = "해당 소환 지점을 찾을 수 없습니다.",
	spawnerRemoved = "소환 지점 '%s' 이(가) 삭제되었습니다.",
	spawnerEditedMsg = "소환 지점이 성공적으로 수정되었습니다.",
	spawnerTitle = "NPC 소환 지점 설정 수정",
	spawnerMaxSpawned = "소환 지점 최대 소환 수",
	spawnerMaxNearby = "주변 최대 NPC 수 제한",
	spawnerMinDistance = "플레이어 접근 금지 거리",
	spawnerSpawnDelay = "소환 지연 시간 (초)",
	spawnerActiveRadius = "활성화 반경 (유닛)",
	spawnerUseArea = "반경 대신 Area 사용",
	spawnerVisitCooldown = "방문 쿨다운 (초, 0 = 비활성)",
	spawnerClassLabel = "NPC 클래스 및 소환 가중치",
	spawnerClassAdd = "클래스 추가",
	spawnerClassRemove = "선택된 클래스 삭제",
	spawnerSave = "저장하기",
	spawnerClassPromptTitle = "클래스 추가",
	spawnerClassPromptDesc = "NPC 클래스 이름을 입력하세요 (예: npc_zombie)",
	spawnerWeightPromptTitle = "가중치 설정",
	spawnerWeightPromptDesc = "소환 가중치를 설정하세요 (숫자)",
	spawnerColumnClass = "클래스",
	spawnerColumnWeight = "가중치",
	npcSpawnerESPPrefix = "NPC 소환 지점: %s",
	npcSpawnerESPInfo = "지연 시간: %d초 | 최대 소환: %d | 주변 최대: %d",
	npcSpawnerESPClasses = "클래스",
	npcSpawnerESPNone = "없음",
	cmdFlyByDesc = "맵 가장자리에서 관리자 위치로 항공 유닛을 소환합니다. (gunship / helicopter)",
	flyByCalled = "%s 접근 중.",
	flyByNoRoute = "유효한 비행 경로를 찾을 수 없습니다.",
	flyByInvalidType = "올바르지 않은 유형입니다. 'gunship' 또는 'helicopter'를 입력하세요.",
})

ix.config.Add("npcSpawnerGlobalLimit", 50, "npcSpawnerGlobalLimitDesc", nil, {
	data = {min = 0, max = 500},
	category = "NPC Spawner"
})

ix.option.Add("npcSpawnerESP", ix.type.bool, true, {
	category = "observer",
	hidden = function()
		return not LocalPlayer():IsAdmin()
	end
})

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")

PLUGIN.spawners = PLUGIN.spawners or {}

ix.command.Add("NPCSpawnerAdd", {
	description = "@cmdNPCSpawnerAddDesc",
	privilege = "Manage Admin Commands",
	superAdminOnly = true,
	arguments = {
		ix.type.string
	},
	OnRun = function(self, client, id)
		local tr = client:GetEyeTrace()
		local pos = tr.HitPos
		local newId = id
		local template = ix.plugin.list["npcspawner"].spawners[id]

		if (template) then
			local suffix = 1
			while (ix.plugin.list["npcspawner"].spawners[id .. "_" .. suffix]) do
				suffix = suffix + 1
			end
			newId = id .. "_" .. suffix
		end

		ix.plugin.list["npcspawner"]:AddSpawner(newId, pos, template)
		
		return L("spawnerAdded", client, newId)
	end
})

ix.command.Add("NPCSpawnerRemove", {
	description = "@cmdNPCSpawnerRemoveDesc",
	privilege = "Manage Admin Commands",
	superAdminOnly = true,
	OnRun = function(self, client)
		local pos = client:GetEyeTrace().HitPos
		local closestDist = 150
		local closestId = nil

		for id, spawner in pairs(ix.plugin.list["npcspawner"].spawners) do
			local dist = spawner.pos:Distance(pos)
			if (dist < closestDist) then
				closestDist = dist
				closestId = id
			end
		end

		if (closestId) then
			ix.plugin.list["npcspawner"]:RemoveSpawner(closestId)
			return L("spawnerRemoved", client, closestId)
		else
			return "@spawnerNotFound"
		end
	end
})

ix.command.Add("NPCSpawnerEdit", {
	description = "@cmdNPCSpawnerEditDesc",
	privilege = "Manage Admin Commands",
	superAdminOnly = true,
	arguments = {
		ix.type.string
	},
	OnRun = function(self, client, id)
		if (not ix.plugin.list["npcspawner"].spawners[id]) then
			return "@spawnerNotFound"
		end

		local spawner = ix.plugin.list["npcspawner"].spawners[id]
		
		net.Start("ixNpcSpawnerEdit")
		net.WriteString(id)
		net.WriteTable(spawner)
		net.Send(client)
	end
})

local flyByTypes = {
	gunship = "npc_combinegunship",
	helicopter = "npc_helicopter",
}

local flyByNames = {
	gunship = "Gunship",
	helicopter = "Helicopter",
}

ix.command.Add("FlyBy", {
	description = "@cmdFlyByDesc",
	privilege = "Manage Admin Commands",
	superAdminOnly = true,
	arguments = {
		ix.type.string,
	},
	OnRun = function(self, client, typeArg)
		local class = flyByTypes[typeArg:lower()]
		if (not class) then
			return "@flyByInvalidType"
		end

		local success = ix.plugin.list["npcspawner"]:CallFlyBy(client:GetPos(), class)
		if (not success) then
			return "@flyByNoRoute"
		end
		return L("flyByCalled", client, flyByNames[typeArg:lower()])
	end
})