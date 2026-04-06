local PLUGIN = PLUGIN

PLUGIN.storedComputers = PLUGIN.storedComputers or {}
PLUGIN.nextComputerID = PLUGIN.nextComputerID or 1
PLUGIN.entities = PLUGIN.entities or {}

local MAX_USE_DISTANCE_SQR = 160 * 160
local SECURITY_BYPASS_DURATION = 300

local function NormalizeCivicPostList(plugin, entries, legacyText, fallbackTitle)
	local normalized = {}

	if (istable(entries)) then
		for _, entry in ipairs(entries) do
			local title = string.Trim(plugin:SanitizeText(entry.title or "", 80))
			local body = string.Trim(plugin:SanitizeText(entry.body or entry.text or "", 4000))
			local author = string.Trim(plugin:SanitizeText(entry.author or "", plugin.maxAuthorLength))

			if (title != "" or body != "") then
				normalized[#normalized + 1] = {
					title = title != "" and title or fallbackTitle,
					body = body,
					author = author,
					updatedAt = tonumber(entry.updatedAt) or os.time()
				}
			end
		end
	end

	local fallbackBody = string.Trim(plugin:SanitizeText(legacyText or "", 4000))
	if (#normalized == 0 and fallbackBody != "") then
		normalized[1] = {
			title = fallbackTitle,
			body = fallbackBody,
			author = "",
			updatedAt = os.time()
		}
	end

	return normalized
end

local function NormalizeCivicQuestionList(plugin, questions)
	local normalized = {}

	if (!istable(questions)) then
		return normalized
	end

	for _, entry in ipairs(questions) do
		local title = string.Trim(plugin:SanitizeText(entry.title or entry.question or "", 96))
		local body = string.Trim(plugin:SanitizeText(entry.body or "", 1500))
		local answer = string.Trim(plugin:SanitizeText(entry.answer or "", 1500))

		if (title != "" or body != "") then
			normalized[#normalized + 1] = {
				title = title != "" and title or "QUESTION",
				body = body,
				asker = string.Trim(plugin:SanitizeText(entry.asker or "", plugin.maxAuthorLength)),
				answer = answer,
				answeredBy = string.Trim(plugin:SanitizeText(entry.answeredBy or "", plugin.maxAuthorLength)),
				createdAt = tonumber(entry.createdAt) or tonumber(entry.updatedAt) or os.time(),
				updatedAt = tonumber(entry.updatedAt) or tonumber(entry.createdAt) or os.time()
			}
		end
	end

	return normalized
end

local function NormalizeCivicPanelData(plugin, data)
	data = istable(data) and table.Copy(data) or {}
	data.announcements = NormalizeCivicPostList(plugin, data.announcements, data.announcement, "NOTICE")
	data.agendas = NormalizeCivicPostList(plugin, data.agendas, data.propaganda, "AGENDA")
	data.questions = NormalizeCivicQuestionList(plugin, data.questions)
	data.announcement = nil
	data.propaganda = nil

	return data
end

local function GetSessionID(client)
	local character = IsValid(client) and client:GetCharacter()

	return character and character:GetID() or client:SteamID64()
end

local function IsComputerAccessible(client, entity)
	if (!IsValid(client) or !client:GetCharacter()) then
		return false, "@noPerm"
	end

	entity = PLUGIN:ResolveComputerEntity(entity)

	if (!IsValid(entity)) then
		return false, "interactiveComputerInvalid"
	end

	if (client:GetPos():DistToSqr(entity:GetPos()) > MAX_USE_DISTANCE_SQR) then
		return false, "interactiveComputerTooFar"
	end

	return true
end

local function GetExcludedFactions()
	local excluded = {}
	for _, v in pairs(ix.faction.indices) do
		if (v.isCombine or v.name == "Administrator" or v.name == "Metropolice Force" or v.name == "Overwatch Transhuman Arm") then
			excluded[v.index] = true
			excluded[v.uniqueID] = true
			excluded[v.name] = true
		end
	end
	return excluded
end

PLUGIN.lastRosterUpdate = 0
PLUGIN.rosterCache = {}

function PLUGIN:BuildCombinePayload(client, callback)
	local scannerPlugin = ix.plugin.Get("scanner")
	local photoHistory = {}
	if (scannerPlugin and scannerPlugin.photoHistory) then
		for _, v in ipairs(scannerPlugin.photoHistory) do
			photoHistory[#photoHistory + 1] = {
				isSurveillance = v.isSurveillance,
				time = v.time,
				pos = v.pos,
				ang = v.ang,
				id = v.id,
				trg = v.trg,
				zone = v.zone
			}
		end
	end

	local payload = {
		combineTerminal = true,
		civicData = self:GetCivicPanelData(),
		canAccessCombine = true,
		canEditObjectives = hook.Run("CanPlayerEditObjectives", client) == true,
		canEditData = client:IsCombine() or client:IsAdmin(),
		objectives = Schema and Schema.CombineObjectives or {},
		journalData = self:GetCombineJournalData(client),
		roster = {},
		photoLogs = photoHistory,
		cameras = {}
	}

	for _, v in ipairs(ents.FindByClass("npc_combine_camera")) do
		payload.cameras[#payload.cameras + 1] = {
			ent = v,
			id = v:EntIndex(),
			name = "C-i" .. v:EntIndex()
		}
	end

	for _, v in ipairs(ents.FindByClass("ix_scanner")) do
		local pilot = v:GetPilot()
		if (IsValid(pilot)) then
			payload.cameras[#payload.cameras + 1] = {
				ent = v,
				id = v:EntIndex(),
				name = v:GetNetVar("ixScannerName", "SCN-" .. v:EntIndex())
			}
		end
	end

	-- Return cached roster if it's fresh enough (60 seconds)
	if (self.lastRosterUpdate > CurTime()) then
		payload.roster = self.rosterCache

		if (callback) then
			callback(payload)
		end
		return
	end

	local excluded = GetExcludedFactions()

	-- Database query to include offline characters
	local query = mysql:Select("ix_characters")
	query:Select("id")
	query:Select("name")
	query:Select("data")
	query:Select("faction")
	query:Where("schema", Schema.folder)
	
	query:Callback(function(result)
		if (!callback) then return end
		
		if (istable(result)) then
			local onlineCharacters = {}
			for _, v in ipairs(player.GetAll()) do
				local char = v:GetCharacter()
				if (char) then
					onlineCharacters[char:GetID()] = v
				end
			end

			local roster = {}

			for _, row in ipairs(result) do
				local faction = row.faction
				if (excluded[faction]) then
					continue
				end

				local charData = util.JSONToTable(row.data or "{}")
				-- Skip banned characters (Helix offline bans plugin standard)
				if (charData.banned) then
					continue
				end

				local charID = tonumber(row.id)
				local onlinePlayer = onlineCharacters[charID]
				local combineData = (IsValid(onlinePlayer) and onlinePlayer:GetCharacter():GetData("combineData")) or (charData.combineData or {})

				roster[#roster + 1] = {
					target = onlinePlayer,
					id = charID,
					name = row.name,
					cid = charData.cid or "00000",
					data = combineData,
					isOnline = IsValid(onlinePlayer),
					hasContent = (combineData.text and string.Trim(combineData.text or "") != "") == true
				}
			end

			table.sort(roster, function(a, b)
				if (a.isOnline != b.isOnline) then
					return a.isOnline
				end

				if (a.hasContent != b.hasContent) then
					return a.hasContent
				end

				return (a.name or "") < (b.name or "")
			end)

			self.rosterCache = roster
			self.lastRosterUpdate = CurTime() + 60
			payload.roster = roster
		end

		callback(payload)
	end)
	query:Execute()
end


function PLUGIN:GetCivicPanelData()
	return NormalizeCivicPanelData(self, ix.data.Get("interactiveComputerCivicPanel", {}, false, true))
end

function PLUGIN:SetCivicPanelData(data)
	ix.data.Set("interactiveComputerCivicPanel", NormalizeCivicPanelData(self, data), false, true)
end

function PLUGIN:BuildCivicPayload(client, returnContext)
	local payload = {
		civicPanel = true,
		canEdit = client:IsCombine() or client:IsAdmin(),
		canAsk = self:HasCivicTerminalAccess(client),
		data = self:GetCivicPanelData()
	}

	if (returnContext) then
		payload.fromCombine = true
		payload.returnContext = returnContext
	end

	return payload
end

function PLUGIN:UpdateComputerVisualState(entity, state)
	entity = self:ResolveComputerEntity(entity)
	if (!IsValid(entity)) then
		return
	end

	local definition = self:GetAssemblyDefinition(entity)

	self:SetEntitySkinForState(entity, definition and definition.skins, state)
	
	for _, candidate in pairs(self.entities) do
		if (!IsValid(candidate) or !self:IsSupportComputer(candidate)) then
			continue
		end

		local candidateDefinition = self:GetComputerDefinition(candidate:GetClass())
		if (candidateDefinition and definition and candidateDefinition.family == definition.family) then
			local maxDistance = self:GetSupportMaxDistance(entity, nil, candidateDefinition.role)
			if (entity:GetPos():DistToSqr(candidate:GetPos()) <= (maxDistance * maxDistance)) then
				self:SetEntitySkinForState(candidate, candidateDefinition.skins, state)
			end
		end
	end
end

function PLUGIN:RefreshInteractiveComputerVisualStates()
	for _, entity in pairs(self.entities) do
		if (!IsValid(entity) or !self:IsInteractiveComputer(entity)) then
			continue
		end

		local isAssemblyValid = self:IsComputerAssemblyValid(entity)
		local state

		if (entity:GetPowered()) then
			entity:SetNetVar("assemblyError", !isAssemblyValid)
			state = isAssemblyValid and "on" or "error"
		else
			entity:SetNetVar("assemblyError", !isAssemblyValid)
			state = isAssemblyValid and "off" or "error"
		end

		self:UpdateComputerVisualState(entity, state)
	end
end

function PLUGIN:IsComputerAssemblyValid(entity)
	entity = self:ResolveComputerEntity(entity)
	if (!IsValid(entity)) then
		return false
	end

	local definition = self:GetComputerDefinition(entity:GetClass())
	if (!definition or definition.interactive ~= true) then
		return true
	end

	if (definition.standalone == true) then
		return true
	end

	local requiredRoles = self:GetRequiredSupportRoles(entity)
	if (#requiredRoles == 0) then
		return true
	end

	for _, role in ipairs(requiredRoles) do
		if (!IsValid(self:FindNearestSupportComputer(entity, role))) then
			return false
		end
	end

	return true
end

local function EmitCombineLockedSound(entity)
	entity = PLUGIN:ResolveComputerEntity(entity)
	local definition = IsValid(entity) and PLUGIN:GetComputerDefinition(entity:GetClass())
	if (!IsValid(entity) or !definition or definition.family != "combine") then
		return
	end

	entity:EmitSound("buttons/combine_button_locked.wav", 60, 100, 0.7)
end

function PLUGIN:GetCombineJournalData(client)
	local character = IsValid(client) and client:GetCharacter()
	local stored = character and character:GetData("interactiveCombineJournal")

	return self:NormalizeData(stored)
end

function PLUGIN:SetCombineJournalData(client, data)
	local character = IsValid(client) and client:GetCharacter()
	if (!character) then
		return
	end

	character:SetData("interactiveCombineJournal", self:NormalizeData(data))
end

function PLUGIN:GetResolvedJournalAuthor(client)
	local character = IsValid(client) and client:GetCharacter()
	local identification = character and Schema.GetIdentificationData and Schema:GetIdentificationData(character)

	if (!character) then
		return ""
	end

	if (client:IsCombine()) then
		return character:GetName()
	end

	if (client:IsAdmin()) then
		if (identification) then
			local cidName = string.Trim(tostring(identification.name or ""))
			local cidID = string.Trim(tostring(identification.id or ""))

			if (cidName != "") then
				return cidID != "" and string.format("%s #%s", cidName, cidID) or cidName
			end
		end

		return ""
	end

	if (identification) then
		return string.Trim(tostring(identification.name or ""))
	end

	return ""
end

function PLUGIN:ApplyEntryAuthors(previousData, newData, client, automatic)
	for categoryIndex, category in ipairs(newData.categories or {}) do
		local previousCategory = previousData and previousData.categories and previousData.categories[categoryIndex]

		for entryIndex, entry in ipairs(category.entries or {}) do
			local previousEntry = previousCategory and previousCategory.entries and previousCategory.entries[entryIndex]
			local changed = !previousEntry or previousEntry.title != entry.title or previousEntry.body != entry.body

			if (automatic) then
				if (changed or string.Trim(tostring(entry.author or "")) == "") then
					entry.author = self:GetResolvedJournalAuthor(client)
				else
					entry.author = previousEntry.author or ""
				end
			else
				entry.author = string.Trim(self:SanitizeText(entry.author, self.maxAuthorLength))
			end
		end
	end

	return newData
end

function PLUGIN:BuildOpenContext(client, entity, callback)
	if (entity:IsCombineTerminal()) then
		self:BuildCombinePayload(client, callback)
		return
	end

	if (callback) then
		callback({
			combineTerminal = false
		})
	end
end

function PLUGIN:GetSessionStorageEntity(entity)
	entity = self:ResolveComputerEntity(entity)
	if (!IsValid(entity)) then
		return
	end

	if (IsValid(entity.ixSessionStorageEntity)) then
		return entity.ixSessionStorageEntity
	end

	return self:ResolveStorageEntity(entity) or entity
end

function PLUGIN:GetActiveComputerUser(entity)
	entity = self:ResolveComputerEntity(entity)
	if (!IsValid(entity)) then
		return
	end

	if (IsValid(entity.ixActiveUser)) then
		return entity.ixActiveUser
	end

	local storageEntity = self:GetSessionStorageEntity(entity)
	if (IsValid(storageEntity) and IsValid(storageEntity.ixActiveUser)) then
		return storageEntity.ixActiveUser
	end
end

function PLUGIN:HandleGeneralAssemblyFailure(entity)
	entity = self:ResolveComputerEntity(entity)
	if (!IsValid(entity) or entity:IsCombineTerminal()) then
		return
	end

	local storageEntity = self:GetSessionStorageEntity(entity) or entity
	local activeUser = self:GetActiveComputerUser(entity)

	entity:SetNetVar("assemblyError", true)

	if (entity:GetPowered()) then
		entity:SetPowered(false)
	end

	if (IsValid(activeUser)) then
		local filtered, context = self:BuildGeneralPayload(activeUser, storageEntity)
		netstream.Start(activeUser, "ixInteractiveComputerSync", entity, filtered, entity:GetPowered(), context)
	end

	self:ReleaseComputerUser(entity, activeUser)
end

function PLUGIN:GetAccessSession(entity, client)
	entity.ixAccessSessions = entity.ixAccessSessions or {}

	local sessionID = GetSessionID(client)
	if (!sessionID) then
		return nil
	end

	entity.ixAccessSessions[sessionID] = entity.ixAccessSessions[sessionID] or {
		full = false,
		entries = {}
	}

	return entity.ixAccessSessions[sessionID]
end

function PLUGIN:ClearAccessSession(entity, client)
	entity = self:ResolveComputerEntity(entity)
	if (!IsValid(entity) or !entity.ixAccessSessions) then
		return
	end

	if (!client) then
		entity.ixAccessSessions = {}
		return
	end

	local sessionID = GetSessionID(client)
	if (sessionID) then
		entity.ixAccessSessions[sessionID] = nil
	end
end

function PLUGIN:ReleaseAccessSession(entity, client)
	return self:ClearAccessSession(entity, client)
end

function PLUGIN:IsGeneralComputerLocked(data, session)
	return false
end

function PLUGIN:GetEntryKey(categoryIndex, entryIndex)
	return string.format("%d:%d", tonumber(categoryIndex) or 0, tonumber(entryIndex) or 0)
end

function PLUGIN:BuildGeneralPayload(client, entity)
	entity = self:ResolveStorageEntity(entity) or entity

	local data = entity:GetComputerData()
	local session = self:GetAccessSession(entity, client) or {full = false, entries = {}}
	local filtered = {
		security = {
			mode = data.security.mode,
			password = session.full and data.security.password or ""
		},
		categories = {}
	}
	local isLocked = self:IsGeneralComputerLocked(data, session)
	local isGuest = data.security.password ~= "" and !session.full

	if (isLocked) then
		filtered.categories[1] = {
			name = L("interactiveComputerLocked"),
			entries = {
				{
					title = L("interactiveComputerLocked"),
					body = L("interactiveComputerLockedPrompt"),
					updatedAt = os.time(),
					security = {
						mode = "none",
						password = ""
					},
					locked = true
				}
			}
		}
	else
		for categoryIndex, category in ipairs(data.categories or {}) do
			local newCategory = {
				name = category.name,
				entries = {}
			}

			for entryIndex, entry in ipairs(category.entries or {}) do
				local entrySecurity = self:NormalizeSecurity(entry.security, {"none", "private", "readonly"}, "none")
				local unlocked = session.full or session.entries[self:GetEntryKey(categoryIndex, entryIndex)] == true
				local canSee = entrySecurity.mode != "private" or entrySecurity.password == "" or unlocked
				local canEdit = session.full or unlocked

				newCategory.entries[#newCategory.entries + 1] = {
					title = canSee and entry.title or L("interactiveComputerLockedEntry"),
					body = canSee and entry.body or L("interactiveComputerEntryLockedPrompt"),
					updatedAt = entry.updatedAt,
					author = canSee and (entry.author or "") or "",
					security = {
						mode = entrySecurity.mode,
						password = session.full and entrySecurity.password or ""
					},
					locked = !canSee,
					unlocked = unlocked,
					canEdit = canEdit
				}
			end

			filtered.categories[#filtered.categories + 1] = newCategory
		end
	end

	return filtered, {
		canEdit = !isGuest and session.full != false or (data.security.password == ""),
		locked = isLocked,
		guest = isGuest,
		computerMode = data.security.mode,
		hasComputerPassword = data.security.password ~= "",
		fullAccess = session.full == true or data.security.password == "",
		entryLocks = true
	}
end

function PLUGIN:GenerateComputerID()
	local computerID = self.nextComputerID
	self.nextComputerID = self.nextComputerID + 1

	return computerID
end

function PLUGIN:CreateComputer(position, angles, model, data, powered, forcedID, bDropToFloor)
	local definition = self:GetComputerDefinition(model or "")
	local className = definition and definition.class or "ix_interactive_computer"
	model = string.lower((definition and definition.model) or model or self.defaultModel)

	if (!self:IsValidComputerModel(model)) then
		model = self.defaultModel
	end

	local entity = ents.Create(className)
	if (!IsValid(entity)) then
		return
	end

	entity.ixModelOverride = model
	entity:SetComputerModel(model) -- Ensure the model is applied after setting ixModelOverride
	entity:SetPos(position)
	entity:SetAngles(angles)
	entity:Spawn()
	entity:Activate()

	if (bDropToFloor) then
		entity:DropToFloor()
	end

	local computerID = tonumber(forcedID) or self:GenerateComputerID()

	entity:SetComputerID(computerID)
	entity:SetComputerData(data or self:CreateDefaultData())
	entity:SetPowered(powered == true, true)

	self:UpdateComputerVisualState(entity, powered == true and "on" or "off")

	self.storedComputers[computerID] = entity:GetComputerData()
	self.nextComputerID = math.max(self.nextComputerID, computerID + 1)

	return entity
end

function PLUGIN:OpenComputer(client, entity)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	if (entity:IsCombineTerminal() and !self:HasCombineTerminalAccess(client) and !entity:IsSecurityBypassed()) then
		if (self:IsCivicComputer(entity)) then
			if (!self:HasCivicTerminalAccess(client)) then
				EmitCombineLockedSound(entity)
				client:NotifyLocalized("interactiveComputerCivicDenied")
				return
			end
		else
			EmitCombineLockedSound(entity)
			return
		end
	end

	entity = self:ResolveComputerEntity(entity)
	local storageEntity = self:ResolveStorageEntity(entity) or entity

	if (IsValid(storageEntity.ixActiveUser) and storageEntity.ixActiveUser != client) then
		EmitCombineLockedSound(entity)
		client:NotifyLocalized("interactiveComputerBusy")
		return
	end

	if (!self:IsComputerAssemblyValid(entity)) then
		EmitCombineLockedSound(entity)
		entity:SetPowered(false, true)
		client:NotifyLocalized("interactiveComputerRequiresSupport")
		return
	end

	storageEntity.ixActiveUser = client
	entity.ixActiveUser = client
	entity.ixSessionStorageEntity = storageEntity
	client:SetNetVar("ixUsingTerminal", entity)

	if (self:IsCivicComputer(entity)) then
		netstream.Start(client, "ixInteractiveComputerOpen", entity, entity:GetComputerData(), entity:GetPowered(), self:BuildCivicPayload(client))
		return
	end

	if (!entity:IsCombineTerminal()) then
		local filtered, context = self:BuildGeneralPayload(client, entity)
		netstream.Start(client, "ixInteractiveComputerOpen", entity, filtered, entity:GetPowered(), context)
		return
	end

	self:BuildOpenContext(client, entity, function(payload)
		if (IsValid(client) and IsValid(entity)) then
			netstream.Start(client, "ixInteractiveComputerOpen", entity, entity:GetComputerData(), entity:GetPowered(), payload)
		end
	end)
end

function PLUGIN:ReleaseComputerUser(entity, client)
	local primaryEntity = self:ResolveComputerEntity(entity)
	local storageEntity = self:GetSessionStorageEntity(primaryEntity) or primaryEntity
	if (!IsValid(primaryEntity) and !IsValid(storageEntity)) then
		return
	end

	local canRelease = !client
		or (IsValid(primaryEntity) and primaryEntity.ixActiveUser == client)
		or (IsValid(storageEntity) and storageEntity.ixActiveUser == client)

	if (!canRelease) then
		return
	end

	if (IsValid(primaryEntity)) then
		if (IsValid(primaryEntity.ixActiveUser)) then
			primaryEntity.ixActiveUser:SetNetVar("ixUsingTerminal", nil)
		end

		primaryEntity.ixActiveUser = nil
		primaryEntity.ixSessionStorageEntity = nil
	end

	if (IsValid(storageEntity)) then
		if (IsValid(storageEntity.ixActiveUser)) then
			storageEntity.ixActiveUser:SetNetVar("ixUsingTerminal", nil)
		end

		storageEntity.ixActiveUser = nil
		self:ClearAccessSession(storageEntity, client)
	end
end

function PLUGIN:SaveData()
	local data = {}

	for _, entity in pairs(self.entities) do
		if (!IsValid(entity) or !PLUGIN:IsPrimaryComputerEntity(entity)) then
			continue
		end

		local computerID = entity:GetComputerID()

		local physicsObject = entity:GetPhysicsObject()
		local bMovable = nil

		if (IsValid(physicsObject)) then
			bMovable = physicsObject:IsMoveable()
		end

		data[#data + 1] = {
			class = entity:GetClass(),
			computerID = computerID,
			pos = entity:GetPos(),
			angles = entity:GetAngles(),
			model = entity:GetModel(),
			powered = entity:GetPowered(),
			data = entity:GetComputerData(),
			movable = bMovable
		}

		self.storedComputers[computerID] = entity:GetComputerData()
	end

	self:SetData(data)
end

function PLUGIN:LoadData()
	local savedData = self:GetData() or {}
	local maxID = 0

	self.storedComputers = {}

	for _, computerData in ipairs(savedData) do
		local entity = self:CreateComputer(
			computerData.pos,
			computerData.angles,
			computerData.class or computerData.model,
			self:NormalizeData(computerData.data),
			computerData.powered,
			computerData.computerID,
			false -- Do NOT drop to floor when loading, to keep z-pos (especially on containers)
		)

		if (IsValid(entity)) then
			maxID = math.max(maxID, entity:GetComputerID())

			local phys = entity:GetPhysicsObject()
			if (IsValid(phys)) then
				phys:EnableMotion(computerData.movable or false)
				phys:Sleep()
			end
		end
	end

	self.nextComputerID = maxID + 1
	self:RefreshInteractiveComputerVisualStates()
end

function PLUGIN:TryBypassSecurity(client, entity)
	entity = self:ResolveComputerEntity(entity)
	if (!IsValid(entity) or !entity:IsCombineTerminal()) then
		return
	end

	entity:SetSecurityBypass(SECURITY_BYPASS_DURATION)

	client:EmitSound("buttons/combine_button1.wav")
	client:NotifyLocalized("empOverloadTerminalSucceed")

	self:OpenComputer(client, entity)
end

function PLUGIN:EntityRemoved(entity)
	if (PLUGIN:IsComputerEntity(entity)) then
		self.entities[entity:EntIndex()] = nil
	end
end

function PLUGIN:PlayerDisconnected(client)
	for _, entity in pairs(self.entities) do
		if (IsValid(entity) and self:IsPrimaryComputerEntity(entity) and entity.ixActiveUser == client) then
			entity.ixActiveUser = nil
			self:ClearAccessSession(entity, client)
		end
	end
end

function PLUGIN:OnEntityCreated(entity)
	if (self:IsComputerEntity(entity)) then
		self.entities[entity:EntIndex()] = entity
	end
end

function PLUGIN:InitPostEntity()
	for _, entity in ents.Iterator() do
		if (self:IsComputerEntity(entity)) then
			self.entities[entity:EntIndex()] = entity
		end
	end
end

netstream.Hook("ixInteractiveComputerSave", function(client, entity, data)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	local normalized = PLUGIN:NormalizeData(data)
	local storageEntity = PLUGIN:ResolveStorageEntity(entity) or entity
	local currentData = storageEntity:GetComputerData()
	local _, context = PLUGIN:BuildGeneralPayload(client, storageEntity)
	if (context.locked or !context.canEdit) then
		client:NotifyLocalized("noPerm")
		return
	end

	normalized = PLUGIN:ApplyEntryAuthors(currentData, normalized, client, false)
	storageEntity:SetComputerData(normalized)
	PLUGIN.storedComputers[storageEntity:GetComputerID()] = normalized
	PLUGIN:SaveData()

	local filtered, newContext = PLUGIN:BuildGeneralPayload(client, storageEntity)
	netstream.Start(client, "ixInteractiveComputerSync", entity, filtered, entity:GetPowered(), newContext)
end)

netstream.Hook("ixInteractiveComputerEndUse", function(client, entity)
	PLUGIN:ReleaseComputerUser(entity, client)
end)

netstream.Hook("ixInteractiveComputerPower", function(client, entity, state, screenMode)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	entity = PLUGIN:ResolveComputerEntity(entity)

	if (state == true and !PLUGIN:IsComputerAssemblyValid(entity)) then
		entity:SetPowered(false, true)
		client:NotifyLocalized("interactiveComputerRequiresSupport")
		return
	end

	entity:SetPowered(state == true)
	PLUGIN:SaveData()

	if (screenMode == "combineJournal") then
		PLUGIN:BuildOpenContext(client, entity, function(payload)
			if (IsValid(client) and IsValid(entity)) then
				netstream.Start(client, "ixInteractiveComputerSyncCombineJournal", entity, PLUGIN:GetCombineJournalData(client), payload)
			end
		end)
		return
	end

	if (screenMode == "civic") then
		local isRequestingCombine = !PLUGIN:IsCivicComputer(entity) and entity:IsCombineTerminal()
		
		if (isRequestingCombine) then
			PLUGIN:BuildOpenContext(client, entity, function(payload)
				if (IsValid(client) and IsValid(entity)) then
					netstream.Start(client, "ixInteractiveComputerSync", entity, entity:GetComputerData(), entity:GetPowered(), PLUGIN:BuildCivicPayload(client, payload))
				end
			end)
		else
			netstream.Start(client, "ixInteractiveComputerSync", entity, entity:GetComputerData(), entity:GetPowered(), PLUGIN:BuildCivicPayload(client))
		end
		return
	end

	if (PLUGIN:IsCivicComputer(entity)) then
		netstream.Start(client, "ixInteractiveComputerSync", entity, entity:GetComputerData(), entity:GetPowered(), PLUGIN:BuildCivicPayload(client))
		return
	end

	if (!entity:IsCombineTerminal()) then
		local filtered, context = PLUGIN:BuildGeneralPayload(client, entity)
		netstream.Start(client, "ixInteractiveComputerSync", entity, filtered, entity:GetPowered(), context)
		return
	end

	PLUGIN:BuildOpenContext(client, entity, function(payload)
		if (IsValid(client) and IsValid(entity)) then
			netstream.Start(client, "ixInteractiveComputerSync", entity, entity:GetComputerData(), entity:GetPowered(), payload)
		end
	end)
end)

netstream.Hook("ixInteractiveComputerUnlock", function(client, entity, password)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	entity = PLUGIN:ResolveComputerEntity(entity)
	if (!IsValid(entity) or entity:IsCombineTerminal() or PLUGIN:IsCivicComputer(entity)) then
		return
	end

	local storageEntity = PLUGIN:ResolveStorageEntity(entity) or entity
	local data = storageEntity:GetComputerData()
	if (data.security.password == "") then
		return
	end

	if (data.security.password != tostring(password or "")) then
		client:NotifyLocalized("interactiveComputerInvalidPassword")
		return
	end

	local session = PLUGIN:GetAccessSession(storageEntity, client)
	if (session) then
		session.full = true
	end

	local filtered, context = PLUGIN:BuildGeneralPayload(client, storageEntity)
	netstream.Start(client, "ixInteractiveComputerSync", entity, filtered, entity:GetPowered(), context)
end)

netstream.Hook("ixInteractiveComputerLogoff", function(client, entity)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	local storageEntity = PLUGIN:ResolveStorageEntity(entity) or entity
	PLUGIN:ReleaseAccessSession(storageEntity, client)

	local filtered, context = PLUGIN:BuildGeneralPayload(client, storageEntity)
	netstream.Start(client, "ixInteractiveComputerSync", entity, filtered, entity:GetPowered(), context)
end)

netstream.Hook("ixInteractiveComputerUnlockEntry", function(client, entity, categoryIndex, entryIndex, password)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	entity = PLUGIN:ResolveComputerEntity(entity)
	if (!IsValid(entity) or entity:IsCombineTerminal() or PLUGIN:IsCivicComputer(entity)) then
		return
	end

	local storageEntity = PLUGIN:ResolveStorageEntity(entity) or entity
	local data = storageEntity:GetComputerData()
	local category = data.categories[tonumber(categoryIndex) or 0]
	local entry = category and category.entries[tonumber(entryIndex) or 0]
	if (!entry or !entry.security or entry.security.password == "") then
		return
	end

	if (entry.security.password != tostring(password or "")) then
		client:NotifyLocalized("interactiveComputerInvalidPassword")
		return
	end

	local session = PLUGIN:GetAccessSession(storageEntity, client)
	if (session) then
		session.entries[PLUGIN:GetEntryKey(categoryIndex, entryIndex)] = true
	end

	local filtered, context = PLUGIN:BuildGeneralPayload(client, storageEntity)
	netstream.Start(client, "ixInteractiveComputerSync", entity, filtered, entity:GetPowered(), context)
end)

netstream.Hook("ixInteractiveComputerSetSecurity", function(client, entity, mode, password)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	entity = PLUGIN:ResolveComputerEntity(entity)
	if (!IsValid(entity) or entity:IsCombineTerminal() or PLUGIN:IsCivicComputer(entity)) then
		return
	end

	local storageEntity = PLUGIN:ResolveStorageEntity(entity) or entity
	local _, context = PLUGIN:BuildGeneralPayload(client, storageEntity)
	if (!context.canEdit) then
		client:NotifyLocalized("noPerm")
		return
	end

	local data = storageEntity:GetComputerData()
	data.security = PLUGIN:NormalizeSecurity({
		mode = tostring(mode or "none"),
		password = tostring(password or "")
	}, {"none", "locked"}, "none")
	storageEntity:SetComputerData(data)
	PLUGIN.storedComputers[storageEntity:GetComputerID()] = data
	PLUGIN:SaveData()
	client:NotifyLocalized("interactiveComputerPasswordUpdated")

	local filtered, newContext = PLUGIN:BuildGeneralPayload(client, storageEntity)
	netstream.Start(client, "ixInteractiveComputerSync", entity, filtered, entity:GetPowered(), newContext)
end)

netstream.Hook("ixInteractiveComputerSetEntrySecurity", function(client, entity, categoryIndex, entryIndex, mode, password)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	entity = PLUGIN:ResolveComputerEntity(entity)
	if (!IsValid(entity) or entity:IsCombineTerminal() or PLUGIN:IsCivicComputer(entity)) then
		return
	end

	local storageEntity = PLUGIN:ResolveStorageEntity(entity) or entity
	local _, context = PLUGIN:BuildGeneralPayload(client, storageEntity)
	if (!context.canEdit) then
		client:NotifyLocalized("noPerm")
		return
	end

	local data = storageEntity:GetComputerData()
	local category = data.categories[tonumber(categoryIndex) or 0]
	local entry = category and category.entries[tonumber(entryIndex) or 0]
	if (!entry) then
		return
	end

	entry.security = PLUGIN:NormalizeSecurity({
		mode = tostring(mode or "none"),
		password = tostring(password or "")
	}, {"none", "private", "readonly"}, "none")
	storageEntity:SetComputerData(data)
	PLUGIN.storedComputers[storageEntity:GetComputerID()] = data
	PLUGIN:SaveData()
	client:NotifyLocalized("interactiveComputerPasswordUpdated")

	local filtered, newContext = PLUGIN:BuildGeneralPayload(client, storageEntity)
	netstream.Start(client, "ixInteractiveComputerSync", entity, filtered, entity:GetPowered(), newContext)
end)

netstream.Hook("ixInteractiveComputerUpdateObjectives", function(client, entity, text)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	if (!entity:IsCombineTerminal() or (!PLUGIN:HasCombineTerminalAccess(client) and !entity:IsSecurityBypassed())) then
		return
	end

	if (!hook.Run("CanPlayerEditObjectives", client)) then
		client:NotifyLocalized("noPerm")
		return
	end

	local date = ix.date.Get()
	local data = {
		text = string.sub(tostring(text or ""), 1, 2000),
		lastEditPlayer = client:GetCharacter() and client:GetCharacter():GetName() or client:Name(),
		lastEditDate = ix.date.GetSerialized(date)
	}

	ix.data.Set("combineObjectives", data, false, true)
	Schema.CombineObjectives = data
	Schema:AddCombineDisplayMessage("@cViewObjectivesFiller", nil, client, date:spanseconds())

	PLUGIN.lastRosterUpdate = 0
	PLUGIN:BuildOpenContext(client, entity, function(payload)
		if (IsValid(client) and IsValid(entity)) then
			netstream.Start(client, "ixInteractiveComputerSync", entity, entity:GetComputerData(), entity:GetPowered(), payload)
		end
	end)
end)

netstream.Hook("ixInteractiveComputerSaveCivicPanel", function(client, entity, payload, legacyPropaganda)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	entity = PLUGIN:ResolveComputerEntity(entity)

	if (!(client:IsCombine() or client:IsAdmin())) then
		client:NotifyLocalized("noPerm")
		return
	end

	local data = PLUGIN:GetCivicPanelData()

	if (istable(payload)) then
		data.announcements = payload.announcements or data.announcements
		data.agendas = payload.agendas or data.agendas
	else
		data.announcements = NormalizeCivicPostList(PLUGIN, nil, payload, "NOTICE")
		data.agendas = NormalizeCivicPostList(PLUGIN, nil, legacyPropaganda, "AGENDA")
	end

	PLUGIN:SetCivicPanelData(data)

	local context

	if (PLUGIN:IsCivicComputer(entity)) then
		context = PLUGIN:BuildCivicPayload(client)
	else
		context = PLUGIN:BuildCivicPayload(client, PLUGIN:BuildOpenContext(client, entity))
	end

	netstream.Start(client, "ixInteractiveComputerSync", entity, entity:GetComputerData(), entity:GetPowered(), context)
end)

netstream.Hook("ixInteractiveComputerAskQuestion", function(client, entity, title, body)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	entity = PLUGIN:ResolveComputerEntity(entity)

	if (!PLUGIN:HasCivicTerminalAccess(client)) then
		client:NotifyLocalized("interactiveComputerCivicDenied")
		return
	end

	local questionTitle = string.Trim(PLUGIN:SanitizeText(title or "", 96))
	local questionBody = string.Trim(PLUGIN:SanitizeText(body or "", 1500))
	if (questionTitle == "" and questionBody == "") then
		return
	end

	local data = PLUGIN:GetCivicPanelData()
	data.questions[#data.questions + 1] = {
		title = questionTitle != "" and questionTitle or string.sub(questionBody, 1, 96),
		body = questionBody,
		asker = client:Name(),
		answer = "",
		answeredBy = "",
		createdAt = os.time(),
		updatedAt = os.time()
	}

	PLUGIN:SetCivicPanelData(data)
	local context

	if (PLUGIN:IsCivicComputer(entity)) then
		context = PLUGIN:BuildCivicPayload(client)
	else
		context = PLUGIN:BuildCivicPayload(client, PLUGIN:BuildOpenContext(client, entity))
	end

	netstream.Start(client, "ixInteractiveComputerSync", entity, entity:GetComputerData(), entity:GetPowered(), context)
end)

netstream.Hook("ixInteractiveComputerAnswerQuestion", function(client, entity, index, text)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	entity = PLUGIN:ResolveComputerEntity(entity)

	if (!(client:IsCombine() or client:IsAdmin())) then
		client:NotifyLocalized("noPerm")
		return
	end

	local data = PLUGIN:GetCivicPanelData()
	local question = data.questions[tonumber(index) or 0]
	if (!question) then
		return
	end

	question.answer = string.Trim(string.sub(tostring(text or ""), 1, 1500))
	question.answeredBy = client:Name()
	question.updatedAt = os.time()

	PLUGIN:SetCivicPanelData(data)
	local context

	if (PLUGIN:IsCivicComputer(entity)) then
		context = PLUGIN:BuildCivicPayload(client)
	else
		context = PLUGIN:BuildCivicPayload(client, PLUGIN:BuildOpenContext(client, entity))
	end

	netstream.Start(client, "ixInteractiveComputerSync", entity, entity:GetComputerData(), entity:GetPowered(), context)
end)

netstream.Hook("ixInteractiveComputerDeleteQuestion", function(client, entity, index)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	entity = PLUGIN:ResolveComputerEntity(entity)

	if (!(client:IsCombine() or client:IsAdmin())) then
		client:NotifyLocalized("noPerm")
		return
	end

	local data = PLUGIN:GetCivicPanelData()
	local questionIndex = tonumber(index) or 0
	if (!data.questions[questionIndex]) then
		return
	end

	table.remove(data.questions, questionIndex)
	PLUGIN:SetCivicPanelData(data)

	local context

	if (PLUGIN:IsCivicComputer(entity)) then
		context = PLUGIN:BuildCivicPayload(client)
	else
		context = PLUGIN:BuildCivicPayload(client, PLUGIN:BuildOpenContext(client, entity))
	end

	netstream.Start(client, "ixInteractiveComputerSync", entity, entity:GetComputerData(), entity:GetPowered(), context)
end)

netstream.Hook("ixInteractiveComputerUpdateData", function(client, entity, target, text)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	if (!entity:IsCombineTerminal() or (!PLUGIN:HasCombineTerminalAccess(client) and !entity:IsSecurityBypassed())) then
		return
	end

	local charID = tonumber(target) or (IsValid(target) and target:GetCharacter() and target:GetCharacter():GetID())
	if (!charID) then
		return
	end

	if (!client:IsAdmin()) then
		local targetChar = ix.char.loaded[charID]
		local targetPlayer = targetChar and targetChar:GetPlayer()

		if (IsValid(targetPlayer)) then
			if (!hook.Run("CanPlayerEditData", client, targetPlayer)) then
				client:NotifyLocalized("noPerm")
				return
			end
		elseif (!client:IsCombine()) then
			client:NotifyLocalized("noPerm")
			return
		end
	end

	local data = {
		text = string.Trim(string.sub(tostring(text or ""), 1, 1000)),
		editor = client:GetCharacter() and client:GetCharacter():GetName() or client:Name()
	}

	local function Sync()
		if (IsValid(client) and IsValid(entity)) then
			PLUGIN.lastRosterUpdate = 0
			PLUGIN:BuildOpenContext(client, entity, function(payload)
				if (IsValid(client) and IsValid(entity)) then
					netstream.Start(client, "ixInteractiveComputerSync", entity, entity:GetComputerData(), entity:GetPowered(), payload)
				end
			end)
		end
	end



	local loadedCharacter = ix.char.loaded[charID]
	if (loadedCharacter) then
		loadedCharacter:SetData("combineData", data)
		Schema:AddCombineDisplayMessage("@cViewDataFiller", nil, client)
		Sync()
	else
		-- Async update for offline character
		local selectQuery = mysql:Select("ix_characters")
		selectQuery:Select("data")
		selectQuery:Where("id", charID)
		selectQuery:Callback(function(result)
			if (istable(result) and #result > 0) then
				local charData = util.JSONToTable(result[1].data or "{}") -- Use {} for empty data
				charData.combineData = data
				
				local updateQuery = mysql:Update("ix_characters")
				updateQuery:Update("data", util.TableToJSON(charData))
				updateQuery:Where("id", charID)
				updateQuery:Callback(function()
					Schema:AddCombineDisplayMessage("@cViewDataFiller", nil, client)
					Sync()
				end)
				updateQuery:Execute()
			else
				-- Character not found or no data, still sync to update client state
				Sync()
			end
		end)
		selectQuery:Execute()
	end
end)

netstream.Hook("ixInteractiveComputerSaveCombineJournal", function(client, entity, data)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then
		client:NotifyLocalized(failMessage)
		return
	end

	if (!entity:IsCombineTerminal() or (!PLUGIN:HasCombineTerminalAccess(client) and !entity:IsSecurityBypassed())) then
		return
	end

	local normalized = PLUGIN:NormalizeData(data)
	local previousData = PLUGIN:GetCombineJournalData(client)
	normalized = PLUGIN:ApplyEntryAuthors(previousData, normalized, client, true)
	PLUGIN:SetCombineJournalData(client, normalized)

	netstream.Start(client, "ixInteractiveComputerSyncCombineJournal", entity, normalized, PLUGIN:BuildOpenContext(client, entity))
end)


netstream.Hook("ixInteractiveComputerRequestPhoto", function(client, entity, timestamp)
	local canUse, failMessage = IsComputerAccessible(client, entity)
	if (!canUse) then return end

	local scannerPlugin = ix.plugin.Get("scanner")
	if (!scannerPlugin or !scannerPlugin.photoHistory) then return end

	-- Find by timestamp (rounding to nearest second for network tolerance)
	local searchTime = math.floor(timestamp)
	for _, v in ipairs(scannerPlugin.photoHistory) do
		if (math.floor(v.time) == searchTime) then
			netstream.Start(client, "ixInteractiveComputerSendPhoto", v)
			break
		end
	end
end)
