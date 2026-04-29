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
	cmdDropshipDesc = "Summons a Combine dropship that deploys soldiers near your position. Usage: Dropship [1-6] or Dropship apc",
	dropshipCalled = "Dropship inbound with %d soldier(s).",
	dropshipAPCCalled = "Dropship inbound with an APC.",
	dropshipNoRoute = "Could not find a valid dropship route or landing zone.",
	cmdFlyOutDesc = "Orders all nearby gunships and helicopters to fly out and leave the area.",
	flyOutDone = "Ordered %d aircraft to fly out.",
	flyOutNone = "No aircraft found nearby.",
	cmdNPCSpawnerForceDesc = "Immediately spawns all NPCs from the specified spawner ID.",
	spawnerForced = "Spawned %d NPC(s) from spawner '%s'.",
	spawnerForceEmpty = "Spawner '%s' is already at max capacity or has no classes set.",
	cmdNPCChargeDesc = "Orders all NPCs within 3000 units to charge at you.",
	npcChargeOrdered = "Ordered %d NPC(s) to charge.",
	npcChargeNone = "No NPCs found within range.",
	cmdNPCForceRemoveDesc = "Removes all NPCs not in combat, not visible, and not near any player. Excludes cameras and turrets.",
	npcForceRemoved = "Removed %d NPC(s).",
	npcForceRemoveNone = "No eligible NPCs found.",
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
	cmdDropshipDesc = "관리자 위치 근처에 병사를 내리는 콤바인 드랍십을 소환합니다. 사용법: Dropship [1-6] 또는 Dropship apc",
	dropshipCalled = "드랍쉽 %d명 병력 접근 중.",
	dropshipAPCCalled = "드랍쉽 APC 운반 중.",
	dropshipNoRoute = "유효한 비행 경로 또는 착지 지점을 찾을 수 없습니다.",
	cmdFlyOutDesc = "근처의 모든 건쉽 및 헬리콥터를 맵 밖으로 내보냅니다.",
	flyOutDone = "%d대의 항공기를 철수시켰습니다.",
	flyOutNone = "근처에 항공기가 없습니다.",
	cmdNPCSpawnerForceDesc = "지정한 소환 지점 ID에서 NPC를 즉시 일제히 소환합니다.",
	spawnerForced = "소환 지점 '%s'에서 NPC %d마리를 소환했습니다.",
	spawnerForceEmpty = "소환 지점 '%s'이(가) 이미 최대 소환 수이거나 클래스가 설정되지 않았습니다.",
	cmdNPCChargeDesc = "3000 유닛 내의 모든 NPC를 내 위치로 진격시킵니다.",
	npcChargeOrdered = "NPC %d마리를 진격시켰습니다.",
	npcChargeNone = "범위 내에 NPC가 없습니다.",
	cmdNPCForceRemoveDesc = "전투 중이 아니고, 플레이어 시야 및 인근이 아닌 NPC를 전부 삭제합니다. 카메라·터렛 제외.",
	npcForceRemoved = "NPC %d마리를 삭제했습니다.",
	npcForceRemoveNone = "삭제 가능한 NPC가 없습니다.",
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
			parentId = id
		end

		ix.plugin.list["npcspawner"]:AddSpawner(newId, pos, template, parentId)

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
		local spawners = ix.plugin.list["npcspawner"].spawners
		if (not spawners[id]) then
			return "@spawnerNotFound"
		end

		-- If this spawner is a child, redirect to its parent
		local targetId = spawners[id].parent or id
		local spawner = spawners[targetId]
		if (not spawner) then
			return "@spawnerNotFound"
		end

		net.Start("ixNpcSpawnerEdit")
		net.WriteString(targetId)
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

ix.command.Add("FlyOut", {
	description = "@cmdFlyOutDesc",
	privilege = "Manage Admin Commands",
	superAdminOnly = true,
	OnRun = function(self, client)
		local count = ix.plugin.list["npcspawner"]:FlyOut(client:GetPos())
		if (count == 0) then
			return "@flyOutNone"
		end
		return L("flyOutDone", client, count)
	end
})

ix.command.Add("NPCCharge", {
	description = "@cmdNPCChargeDesc",
	privilege = "Manage Admin Commands",
	superAdminOnly = true,
	OnRun = function(self, client)
		local count = ix.plugin.list["npcspawner"]:ChargeNPCsAtPlayer(client)
		if (count == 0) then
			return "@npcChargeNone"
		end
		return L("npcChargeOrdered", client, count)
	end
})

ix.command.Add("NPCForceRemove", {
	description = "@cmdNPCForceRemoveDesc",
	privilege = "Manage Admin Commands",
	superAdminOnly = true,
	OnRun = function(self, client)
		local count = ix.plugin.list["npcspawner"]:ForceRemoveIdleNPCs()
		if (count == 0) then
			return "@npcForceRemoveNone"
		end
		return L("npcForceRemoved", client, count)
	end
})

ix.command.Add("NPCSpawnerForce", {
	description = "@cmdNPCSpawnerForceDesc",
	privilege = "Manage Admin Commands",
	superAdminOnly = true,
	arguments = {
		ix.type.string
	},
	OnRun = function(self, client, id)
		if (not ix.plugin.list["npcspawner"].spawners[id]) then
			return "@spawnerNotFound"
		end

		local count = ix.plugin.list["npcspawner"]:ForceSpawnFromSpawner(id)
		if (count == 0) then
			return L("spawnerForceEmpty", client, id)
		end
		return L("spawnerForced", client, count, id)
	end
})

ix.command.Add("Dropship", {
	description = "@cmdDropshipDesc",
	privilege = "Manage Admin Commands",
	superAdminOnly = true,
	arguments = {
		bit.bor(ix.type.string, ix.type.optional),
	},
	OnRun = function(self, client, arg)
		if (arg == "apc") then
			local success = ix.plugin.list["npcspawner"]:CallDropshipAPC(client:GetPos())
			if (not success) then
				return "@dropshipNoRoute"
			end
			return "@dropshipAPCCalled"
		end

		local count = math.Clamp(math.floor(tonumber(arg) or 4), 1, 6)
		local success = ix.plugin.list["npcspawner"]:CallDropship(client:GetPos(), count)
		if (not success) then
			return "@dropshipNoRoute"
		end
		return L("dropshipCalled", client, count)
	end
})