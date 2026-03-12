local PLUGIN = PLUGIN

PLUGIN.name = "Interactive Computers"
PLUGIN.author = "Frosty"
PLUGIN.description = "Adds interactive computer terminals with DOS-style journal storage."

PLUGIN.defaultModel = "models/props/cs_office/computer.mdl"
PLUGIN.allowedModels = {
	["models/props/cs_office/computer.mdl"] = true,
	["models/props_lab/monitor01a.mdl"] = true,
	["models/props_lab/monitor02.mdl"] = true,
	["models/props_combine/combine_smallmonitor001.mdl"] = true,
	["models/props_combine/combine_interface001.mdl"] = true,
	["models/props_combine/combine_interface002.mdl"] = true,
	["models/props_combine/combine_interface003.mdl"] = true,
	["models/props_combine/combine_intmonitor001.mdl"] = true,
	["models/props_combine/combine_intmonitor003.mdl"] = true,
	["models/props_combine/combine_monitorbay.mdl"] = true,
	["models/props_combine/breenconsole.mdl"] = true
}
PLUGIN.combineModels = {
	["models/props_combine/combine_smallmonitor001.mdl"] = true,
	["models/props_combine/combine_interface001.mdl"] = true,
	["models/props_combine/combine_interface002.mdl"] = true,
	["models/props_combine/combine_interface003.mdl"] = true,
	["models/props_combine/combine_intmonitor001.mdl"] = true,
	["models/props_combine/combine_intmonitor003.mdl"] = true,
	["models/props_combine/combine_monitorbay.mdl"] = true,
	["models/props_combine/breenconsole.mdl"] = true
}
PLUGIN.spawnCategory = "HL2 RP: Computers"
PLUGIN.assemblyMaxDistance = 140
PLUGIN.entityDefinitions = {
	{
		class = "ix_computer_office",
		name = "Office Computer",
		langKey = "interactiveComputerOffice",
		model = "models/props/cs_office/computer.mdl",
		skins = {off = 0, on = 0, error = 0},
		family = "general",
		role = "support",
		interactive = false
	},
	{
		class = "ix_computer_lab_monitor_a",
		name = "Lab Monitor A",
		langKey = "interactiveComputerLabMonitorA",
		model = "models/props_lab/monitor01a.mdl",
		skins = {off = 0, on = 1, error = 0},
		family = "general",
		role = "monitor",
		interactive = true
	},
	{
		class = "ix_computer_lab_monitor_b",
		name = "Lab Monitor B",
		langKey = "interactiveComputerLabMonitorB",
		model = "models/props_lab/monitor02.mdl",
		skins = {off = 0, on = 1, error = 0},
		family = "general",
		role = "monitor",
		interactive = true
	},
	{
		class = "ix_computer_combine_monitor",
		name = "Combine Monitor S",
		langKey = "interactiveComputerCombineMonitor",
		model = "models/props_combine/combine_smallmonitor001.mdl",
		skins = {off = 1, on = 0, error = 2},
		family = "combine",
		role = "support",
		interactive = false
	},
	{
		class = "ix_computer_combine_monitor",
		name = "Combine Monitor 2",
		langKey = "interactiveComputerCombineMonitor",
		model = "models/props_combine/combine_monitorbay.mdl",
		skins = {off = 1, on = 0, error = 2},
		family = "combine",
		role = "support",
		interactive = false
	},
	{
		class = "ix_computer_combine_monitor",
		name = "Combine Monitor",
		langKey = "interactiveComputerCombineMonitor",
		model = "models/props_combine/combine_intmonitor001.mdl",
		skins = {off = 1, on = 0, error = 2},
		family = "combine",
		role = "support",
		interactive = false
	},
	{
		class = "ix_computer_combine_monitor",
		name = "Combine Monitor 3",
		langKey = "interactiveComputerCombineMonitor",
		model = "models/props_combine/combine_intmonitor003.mdl",
		skins = {off = 1, on = 0, error = 2},
		family = "combine",
		role = "support",
		interactive = false
	},
	{
		class = "ix_computer_combine_interface",
		name = "Combine Interface",
		langKey = "interactiveComputerCombineInterface",
		model = "models/props_combine/combine_interface001.mdl",
		skins = {off = 1, on = 0, error = 2},
		family = "combine",
		role = "interface",
		interactive = true
	},
	{
		class = "ix_computer_civic_interface",
		name = "Civic Interface",
		langKey = "interactiveComputerCivicInterface",
		model = "models/props_combine/breenconsole.mdl",
		skins = {off = 1, on = 0, error = 2},
		family = "combine",
		role = "civic",
		interactive = true,
		standalone = true,
		access = "cid_or_combine"
	}
}

PLUGIN.maxCategories = 12
PLUGIN.maxEntriesPerCategory = 24
PLUGIN.maxCategoryNameLength = 32
PLUGIN.maxEntryTitleLength = 48
PLUGIN.maxEntryBodyLength = 4096
PLUGIN.maxPasswordLength = 32
PLUGIN.maxAuthorLength = 64

ix.lang.AddTable("english", {
	interactiveComputer = "Interactive Computer",
	interactiveComputerOffice = "Civil Public Terminal",
	interactiveComputerLabMonitorA = "Workstation Monitor A",
	interactiveComputerLabMonitorB = "Workstation Monitor B",
	interactiveComputerCombineMonitor = "Combine Monitor",
	interactiveComputerCombineInterface = "Combine Interface",
	interactiveComputerCivicInterface = "Public Information Interface",
	interactiveComputerDesc = "A terminal that stores categorized journal entries.",
	interactiveComputerUse = "Use to boot the terminal.",
	interactiveComputerPlaced = "Interactive computer placed.",
	interactiveComputerRemoved = "Interactive computer removed.",
	interactiveComputerLookAt = "Look at an interactive computer.",
	interactiveComputerBadModel = "That model is not allowed. Using the default computer model instead.",
	interactiveComputerTooFar = "You are too far away from the computer.",
	interactiveComputerInvalid = "That computer is no longer available.",
	interactiveComputerSaved = "Computer data saved.",
	interactiveComputerBusy = "Someone else is already using this terminal.",
	interactiveComputerCombineDenied = "You need Combine authorization or a keycard to access this terminal.",
	interactiveComputerDisconnected = "The terminal assembly is disconnected. Move the paired hardware closer together.",
	interactiveComputerMonitorUse = "Use the monitor to boot the terminal.",
	interactiveComputerInterfaceUse = "Use the interface to access the terminal.",
	interactiveComputerSupportDesc = "Supporting hardware for a nearby terminal.",
	interactiveComputerRequiresSupport = "This monitor needs nearby computer hardware to power on.",
	interactiveComputerCivicDenied = "You need valid identification to access this terminal.",
	interactiveComputerCivicTitle = "CIVIC INFORMATION TERMINAL",
	interactiveComputerAnnouncement = "NOTICE",
	interactiveComputerPropaganda = "PROPAGANDA",
	interactiveComputerQuestions = "QUESTIONS",
	interactiveComputerAskQuestion = "ASK QUESTION",
	interactiveComputerAnswerQuestion = "ANSWER QUESTION",
	interactiveComputerSaveCivic = "SAVE PANEL",
	interactiveComputerPublicPanel = "PUBLIC PANEL",
	interactiveComputerNoQuestions = "NO QUESTIONS",
	interactiveComputerCombineTitle = "COMBINE MAINFRAME ACCESS COMMAND MODULE",
	interactiveComputerObjectives = "OBJECTIVES",
	interactiveComputerCivilData = "CIVIL DATA",
	interactiveComputerSaveObjectives = "COMMIT OBJECTIVES",
	interactiveComputerSaveData = "COMMIT DATA",
	interactiveComputerPersonalLog = "PERSONAL LOG",
	interactiveComputerSavePersonalLog = "SAVE PERSONAL LOG",
	interactiveComputerBack = "BACK",
	interactiveComputerNoRoster = "NO VALID BIOSIGNALS",
	interactiveComputerSecurityBypassed = "Terminal security has been bypassed temporarily.",
	interactiveComputerSecurityAlreadyBypassed = "Terminal security is already bypassed.",
	interactiveComputerInvalidEmpTarget = "You must aim at a Combine terminal.",
	interactiveComputerNoCategories = "NO CATEGORIES",
	interactiveComputerNoEntries = "NO ENTRIES",
	interactiveComputerPowerOff = "SYSTEM OFFLINE",
	interactiveComputerBooting = "BOOTING...",
	interactiveComputerLocked = "ACCESS LOCKED",
	interactiveComputerGuest = "GUEST ACCESS",
	interactiveComputerFullAccess = "FULL ACCESS",
	interactiveComputerUnlock = "UNLOCK",
	interactiveComputerEntryUnlock = "UNLOCK ENTRY",
	interactiveComputerSecurity = "SYSTEM SECURITY",
	interactiveComputerEntrySecurity = "ENTRY SECURITY",
	interactiveComputerSecurityNone = "NO PASSWORD",
	interactiveComputerSecurityLocked = "LOCKED",
	interactiveComputerSecurityGuest = "GUEST LOGIN",
	interactiveComputerSecurityPrivate = "PRIVATE",
	interactiveComputerSecurityReadOnly = "READ ONLY",
	interactiveComputerAuthor = "AUTHOR",
	interactiveComputerGuestPrompt = "Guest mode active. Contents are visible, editing is disabled.",
	interactiveComputerLockedPrompt = "This terminal is locked. Enter the system password.",
	interactiveComputerEntryLockedPrompt = "This entry is private. Enter the entry password.",
	interactiveComputerEntryReadPrompt = "This entry is read-only until unlocked.",
	interactiveComputerInvalidPassword = "Invalid password.",
	interactiveComputerPasswordUpdated = "Security settings updated.",
	interactiveComputerLockedEntry = "[LOCKED ENTRY]",
})

ix.lang.AddTable("korean", {
	interactiveComputer = "인터랙티브 컴퓨터",
	interactiveComputerOffice = "시민 공용 단말기",
	interactiveComputerLabMonitorA = "작업용 모니터 A",
	interactiveComputerLabMonitorB = "작업용 모니터 B",
	interactiveComputerCombineMonitor = "콤바인 모니터",
	interactiveComputerCombineInterface = "콤바인 인터페이스",
	interactiveComputerCivicInterface = "공공 정보 인터페이스",
	interactiveComputerDesc = "항목별 기록을 저장할 수 있는 터미널입니다.",
	interactiveComputerUse = "상호작용 키를 눌러 터미널을 켭니다.",
	interactiveComputerPlaced = "인터랙티브 컴퓨터를 배치했습니다.",
	interactiveComputerRemoved = "인터랙티브 컴퓨터를 제거했습니다.",
	interactiveComputerLookAt = "인터랙티브 컴퓨터를 조준하세요.",
	interactiveComputerBadModel = "허용되지 않은 모델입니다. 기본 컴퓨터 모델을 사용합니다.",
	interactiveComputerTooFar = "컴퓨터에서 너무 멉니다.",
	interactiveComputerInvalid = "더 이상 사용할 수 없는 컴퓨터입니다.",
	interactiveComputerSaved = "컴퓨터 데이터를 저장했습니다.",
	interactiveComputerBusy = "다른 사람이 이미 이 터미널을 사용 중입니다.",
	interactiveComputerCombineDenied = "콤바인 권한 또는 보안 카드가 있어야 이 터미널에 접근할 수 있습니다.",
	interactiveComputerDisconnected = "터미널 장비 세트가 분리되어 있습니다. 짝이 되는 장비를 더 가깝게 옮기세요.",
	interactiveComputerMonitorUse = "모니터를 상호작용 키를 눌러 터미널을 켭니다.",
	interactiveComputerInterfaceUse = "인터페이스를 상호작용 키를 눌러 터미널에 접근합니다.",
	interactiveComputerSupportDesc = "주변 단말기를 작동시키는 보조 장비입니다.",
	interactiveComputerRequiresSupport = "이 모니터는 근처에 컴퓨터 장비가 있어야 켜집니다.",
	interactiveComputerCivicDenied = "이 터미널에 접근하려면 유효한 신분증이 필요합니다.",
	interactiveComputerCivicTitle = "공공 정보 터미널",
	interactiveComputerAnnouncement = "공지",
	interactiveComputerPropaganda = "선전",
	interactiveComputerQuestions = "질문",
	interactiveComputerAskQuestion = "질문 등록",
	interactiveComputerAnswerQuestion = "답변 등록",
	interactiveComputerSaveCivic = "패널 저장",
	interactiveComputerPublicPanel = "공공 패널",
	interactiveComputerNoQuestions = "질문 없음",
	interactiveComputerCombineTitle = "콤바인 메인프레임 접근 지시 모듈",
	interactiveComputerObjectives = "작전 목표",
	interactiveComputerCivilData = "시민 데이터",
	interactiveComputerSaveObjectives = "목표 저장",
	interactiveComputerSaveData = "데이터 저장",
	interactiveComputerPersonalLog = "개인 기록",
	interactiveComputerSavePersonalLog = "개인 기록 저장",
	interactiveComputerBack = "뒤로",
	interactiveComputerNoRoster = "유효한 생체 신호 없음",
	interactiveComputerSecurityBypassed = "터미널 보안이 잠시 무력화되었습니다.",
	interactiveComputerSecurityAlreadyBypassed = "터미널 보안이 이미 무력화된 상태입니다.",
	interactiveComputerInvalidEmpTarget = "콤바인 단말기를 조준해야 합니다.",
	interactiveComputerNoCategories = "항목 없음",
	interactiveComputerNoEntries = "기록 없음",
	interactiveComputerPowerOff = "시스템 오프라인",
	interactiveComputerBooting = "부팅 중...",
	interactiveComputerLocked = "접근 잠김",
	interactiveComputerGuest = "게스트 접근",
	interactiveComputerFullAccess = "전체 권한",
	interactiveComputerUnlock = "잠금 해제",
	interactiveComputerEntryUnlock = "항목 잠금 해제",
	interactiveComputerSecurity = "시스템 보안",
	interactiveComputerEntrySecurity = "항목 보안",
	interactiveComputerSecurityNone = "암호 없음",
	interactiveComputerSecurityLocked = "잠금",
	interactiveComputerSecurityGuest = "게스트 로그인",
	interactiveComputerSecurityPrivate = "비공개",
	interactiveComputerSecurityReadOnly = "열람 전용",
	interactiveComputerAuthor = "작성자",
	interactiveComputerGuestPrompt = "게스트 모드입니다. 내용은 볼 수 있지만 수정은 할 수 없습니다.",
	interactiveComputerLockedPrompt = "이 터미널은 잠겨 있습니다. 시스템 암호를 입력하세요.",
	interactiveComputerEntryLockedPrompt = "이 항목은 비공개입니다. 항목 암호를 입력하세요.",
	interactiveComputerEntryReadPrompt = "이 항목은 잠금 해제 전까지 열람 전용입니다.",
	interactiveComputerInvalidPassword = "암호가 올바르지 않습니다.",
	interactiveComputerPasswordUpdated = "보안 설정을 변경했습니다.",
	interactiveComputerLockedEntry = "[잠긴 항목]",
})

function PLUGIN:IsValidComputerModel(model)
	return self.allowedModels[string.lower(model or "")] == true
end

function PLUGIN:IsCombineModel(model)
	return self.combineModels[string.lower(model or "")] == true
end

function PLUGIN:GetComputerDefinition(identifier)
	identifier = string.lower(identifier or "")

	for _, definition in ipairs(self.entityDefinitions) do
		if (definition.class == identifier or definition.model == identifier) then
			return definition
		end
	end
end

function PLUGIN:GetDisplayName(identifier)
	local definition = self:GetComputerDefinition(identifier)

	if (definition and definition.langKey) then
		return L(definition.langKey)
	end

	return L("interactiveComputer")
end

function PLUGIN:GetAssemblyDefinition(entity)
	entity = self:ResolveComputerEntity(entity) or entity

	return IsValid(entity) and self:GetComputerDefinition(entity:GetClass()) or nil
end

function PLUGIN:SetEntitySkinForState(entity, skins, state)
	if (!IsValid(entity) or !istable(skins)) then
		return
	end

	local skin = skins[state]
	if (!isnumber(skin)) then
		return
	end

	entity:SetSkin(math.max(0, skin))
end

function PLUGIN:IsComputerEntity(entity)
	if (!IsValid(entity)) then
		return false
	end

	return entity:GetClass() == "ix_interactive_computer" or self:GetComputerDefinition(entity:GetClass()) ~= nil
end

function PLUGIN:IsComputerCompanionEntity(entity)
	return IsValid(entity) and entity:GetClass() == "ix_interactive_computer_companion"
end

function PLUGIN:IsPrimaryComputerEntity(entity)
	return self:IsComputerEntity(entity) and !self:IsComputerCompanionEntity(entity)
end

function PLUGIN:ResolveComputerEntity(entity)
	if (self:IsPrimaryComputerEntity(entity)) then
		return entity
	end
end

function PLUGIN:FindNearestSupportComputer(entity)
	if (!self:IsPrimaryComputerEntity(entity)) then
		return
	end

	local definition = self:GetComputerDefinition(entity:GetClass())
	if (!definition or !definition.family) then
		return
	end

	local bestCandidate
	local bestDistance = math.huge
	local maxDistanceSqr = self.assemblyMaxDistance * self.assemblyMaxDistance

	for _, candidate in ipairs(ents.GetAll()) do
		if (!self:IsSupportComputer(candidate)) then
			continue
		end

		local candidateDefinition = self:GetComputerDefinition(candidate:GetClass())
		if (!candidateDefinition or candidateDefinition.family != definition.family) then
			continue
		end

		local distance = entity:GetPos():DistToSqr(candidate:GetPos())
		if (distance > maxDistanceSqr) then
			continue
		end

		if (!IsValid(bestCandidate) or distance < bestDistance or (distance == bestDistance and candidate:EntIndex() < bestCandidate:EntIndex())) then
			bestCandidate = candidate
			bestDistance = distance
		end
	end

	return bestCandidate
end

function PLUGIN:ResolveStorageEntity(entity)
	if (!self:IsPrimaryComputerEntity(entity)) then
		return
	end

	local definition = self:GetComputerDefinition(entity:GetClass())
	if (!definition) then
		return entity
	end

	if (definition.family == "general" and definition.interactive == true) then
		return self:FindNearestSupportComputer(entity) or entity
	end

	return entity
end

function PLUGIN:IsInteractiveComputer(entity)
	local definition = IsValid(entity) and self:GetComputerDefinition(entity:GetClass())

	return definition and definition.interactive == true
end

function PLUGIN:IsSupportComputer(entity)
	local definition = IsValid(entity) and self:GetComputerDefinition(entity:GetClass())

	return definition and definition.interactive ~= true
end

function PLUGIN:IsCivicComputer(entity)
	local definition = IsValid(entity) and self:GetComputerDefinition(entity:GetClass())

	return definition and definition.role == "civic"
end

function PLUGIN:HasCombineTerminalAccess(client)
	if (!IsValid(client)) then
		return false
	end

	if (client:IsCombine()) then
		return true
	end

	local character = client:GetCharacter()
	local inventory = character and character:GetInventory()

	if (!inventory) then
		return false
	end

	return inventory:HasItem("comkey")
end

function PLUGIN:HasCivicTerminalAccess(client)
	if (!IsValid(client)) then
		return false
	end

	if (client:IsCombine() or client:IsAdmin()) then
		return true
	end

	local character = client:GetCharacter()
	local inventory = character and character:GetInventory()

	return inventory and inventory:HasItem("cid") == true
end

function PLUGIN:SanitizeText(text, maxLength)
	text = tostring(text or "")
	text = string.gsub(text, "\r", "")

	if (maxLength and #text > maxLength) then
		text = string.sub(text, 1, maxLength)
	end

	return text
end

function PLUGIN:NormalizeSecurity(security, allowedModes, defaultMode)
	local normalized = {}
	local lookup = {}

	for _, mode in ipairs(allowedModes or {"none"}) do
		lookup[mode] = true
	end

	defaultMode = lookup[defaultMode] and defaultMode or allowedModes[1] or "none"
	normalized.mode = lookup[security and security.mode] and security.mode or defaultMode
	normalized.password = self:SanitizeText(security and security.password or "", self.maxPasswordLength)

	if (normalized.password == "") then
		normalized.mode = "none"
	end

	return normalized
end

function PLUGIN:CreateDefaultData()
	return {
		security = {
			mode = "none",
			password = ""
		},
		categories = {
			{
				name = "GENERAL",
				entries = {
					{
						title = "BOOT LOG",
						body = "SYSTEM READY.\nLOG STORAGE ONLINE.",
						updatedAt = os.time(),
						author = "",
						security = {
							mode = "none",
							password = ""
						}
					}
				}
			}
		}
	}
end

function PLUGIN:NormalizeData(data)
	local normalized = {
		security = self:NormalizeSecurity(istable(data) and data.security or nil, {"none", "locked", "guest"}, "none"),
		categories = {}
	}
	local sourceCategories = istable(data) and istable(data.categories) and data.categories or {}

	for _, category in ipairs(sourceCategories) do
		if (#normalized.categories >= self.maxCategories) then
			break
		end

		local categoryName = string.Trim(self:SanitizeText(category.name, self.maxCategoryNameLength))
		if (categoryName == "") then
			categoryName = "CATEGORY " .. (#normalized.categories + 1)
		end

		local newCategory = {
			name = string.upper(categoryName),
			entries = {}
		}

		local sourceEntries = istable(category.entries) and category.entries or {}
		for _, entry in ipairs(sourceEntries) do
			if (#newCategory.entries >= self.maxEntriesPerCategory) then
				break
			end

			local title = string.Trim(self:SanitizeText(entry.title, self.maxEntryTitleLength))
			local body = self:SanitizeText(entry.body, self.maxEntryBodyLength)
			local author = string.Trim(self:SanitizeText(entry.author, self.maxAuthorLength))

			if (title == "") then
				title = "ENTRY " .. (#newCategory.entries + 1)
			end

			newCategory.entries[#newCategory.entries + 1] = {
				title = title,
				body = body,
				updatedAt = tonumber(entry.updatedAt) or os.time(),
				author = author,
				security = self:NormalizeSecurity(entry.security, {"none", "private", "readonly"}, "none"),
				locked = entry.locked == true,
				unlocked = entry.unlocked == true,
				canEdit = entry.canEdit != false
			}
		end

		if (#newCategory.entries == 0) then
			newCategory.entries[1] = {
				title = "ENTRY 1",
				body = "",
				updatedAt = os.time(),
				author = "",
				security = {
					mode = "none",
					password = ""
				},
				locked = false,
				unlocked = false,
				canEdit = true
			}
		end

		normalized.categories[#normalized.categories + 1] = newCategory
	end

	if (#normalized.categories == 0) then
		return self:CreateDefaultData()
	end

	return normalized
end

function PLUGIN:FindComputerByID(computerID)
	computerID = tonumber(computerID)

	for _, entity in ipairs(ents.GetAll()) do
		if (self:IsPrimaryComputerEntity(entity) and entity:GetComputerID() == computerID) then
			return entity
		end
	end
end

function PLUGIN:RegisterSpawnableEntities()
	if (self.computersRegistered) then
		return
	end

	for _, definition in ipairs(self.entityDefinitions) do
		scripted_ents.Register({
			Type = "anim",
			Base = "ix_interactive_computer",
			PrintName = definition.name,
			Author = "Frosty",
			Category = self.spawnCategory,
			Spawnable = true,
			AdminOnly = true,
			SpawnModel = definition.model
		}, definition.class)

		list.Set("SpawnableEntities", definition.class, {
			PrintName = definition.name,
			ClassName = definition.class,
			Category = self.spawnCategory,
			AdminOnly = true
		})
	end

	self.computersRegistered = true
end

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")

PLUGIN:RegisterSpawnableEntities()
