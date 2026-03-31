local PLUGIN = PLUGIN

local function getLineTimerID()
	return "ixBreencast.SetLine"
end

local function getCycleTimerID()
	return "ixBreencast.SetCycle"
end

function PLUGIN:IsVoicePluginAvailable()
	return ix.plugin.Get("ixvoice") != nil and netstream != nil
end

function PLUGIN:GetRelayEntities()
	return ents.FindByClass("ix_breencast")
end

function PLUGIN:HasRelayEntities()
	return #self:GetRelayEntities() > 0
end

function PLUGIN:GetState()
	self.state = self.state or {
		activeSetID = nil,
		pendingSetID = nil,
		stopAfterSet = false,
		isPlayingSet = false,
		currentIndex = 0,
		currentLineEnd = 0
	}

	return self.state
end

function PLUGIN:ClearTimers()
	timer.Remove(getLineTimerID())
	timer.Remove(getCycleTimerID())
end

function PLUGIN:UpdateRelayScheduleState()
	local state = self:GetState()
	local isScheduled = state.activeSetID != nil and !state.stopAfterSet
	local isPlayingSet = state.isPlayingSet

	for _, entity in ipairs(self:GetRelayEntities()) do
		entity:SetPlaying(isScheduled)
		entity:SetLooping(true)

		if (!isPlayingSet) then
			entity:FinishBroadcast(true)
		end
	end
end

function PLUGIN:RelayBroadcastToEntities(text, duration, source)
	for _, entity in ipairs(self:GetRelayEntities()) do
		entity:StartRelay(text, duration, source or self.broadcastSourceName, false)
	end
end

function PLUGIN:BroadcastBreencastLine(entry)
	if (!entry or !self:IsVoicePluginAvailable() or !self:HasRelayEntities()) then
		return false
	end

	local sounds, resolvedText = Schema.voices.GetVoiceList("breencast", entry.key)

	if (!sounds) then
		return false
	end

	local duration = self:GetQueuedSoundDuration(sounds)
	ix.chat.Send(NULL, "breencast", entry.key, false, player.GetAll())

	self:RelayBroadcastToEntities(resolvedText or entry.text or entry.key, duration, self.broadcastSourceName)

	return true, duration
end

function PLUGIN:ResetSchedule(stopRelays)
	local state = self:GetState()

	self:ClearTimers()

	state.activeSetID = nil
	state.pendingSetID = nil
	state.stopAfterSet = false
	state.isPlayingSet = false
	state.currentIndex = 0
	state.currentLineEnd = 0

	if (stopRelays) then
		for _, entity in ipairs(self:GetRelayEntities()) do
			if (entity:IsRelayActive()) then
				entity:FinishBroadcast(true)
			end

			entity:SetPlaying(false)
		end
	end
end

function PLUGIN:StopBecauseUnavailable()
	self:ResetSchedule(true)
end

function PLUGIN:ScheduleNextCycle()
	local state = self:GetState()

	if (!state.activeSetID or state.stopAfterSet or !self:HasRelayEntities()) then
		self:ResetSchedule(true)
		return
	end

	state.isPlayingSet = false
	state.currentIndex = 0
	state.currentLineEnd = 0
	self:UpdateRelayScheduleState()

	timer.Create(getCycleTimerID(), self.repeatDelay, 1, function()
		if (!self:IsVoicePluginAvailable() or !self:HasRelayEntities()) then
			self:StopBecauseUnavailable()
			return
		end

		self:StartCurrentSet()
	end)
end

function PLUGIN:AdvanceSet()
	local state = self:GetState()

	if (!self:IsVoicePluginAvailable() or !self:HasRelayEntities()) then
		self:StopBecauseUnavailable()
		return
	end

	if (state.pendingSetID) then
		state.activeSetID = state.pendingSetID
		state.pendingSetID = nil
		state.currentIndex = 0
		state.stopAfterSet = false
	end

	local entries = self:GetSetEntries(state.activeSetID)

	if (!entries or #entries <= 0) then
		self:ResetSchedule(true)
		return
	end

	state.currentIndex = state.currentIndex + 1
	local entry = entries[state.currentIndex]

	if (!entry) then
		if (state.stopAfterSet) then
			self:ResetSchedule(true)
			return
		end

		self:ScheduleNextCycle()
		return
	end

	local ok, duration = self:BroadcastBreencastLine(entry)

	if (!ok) then
		self:ResetSchedule(true)
		return
	end

	state.isPlayingSet = true
	state.currentLineEnd = CurTime() + duration
	self:UpdateRelayScheduleState()

	timer.Create(getLineTimerID(), duration + self.setLineDelay, 1, function()
		self:AdvanceSet()
	end)
end

function PLUGIN:StartCurrentSet()
	local state = self:GetState()

	if (!state.activeSetID or !self:IsVoicePluginAvailable() or !self:HasRelayEntities()) then
		self:StopBecauseUnavailable()
		return
	end

	state.isPlayingSet = true
	state.currentIndex = 0
	state.currentLineEnd = 0

	for _, entity in ipairs(self:GetRelayEntities()) do
		entity:StartSetScene(state.activeSetID)
	end

	self:UpdateRelayScheduleState()
	self:AdvanceSet()
end

function PLUGIN:StartSet(setID)
	local state = self:GetState()

	if (!state.activeSetID or !state.isPlayingSet) then
		self:ClearTimers()
		state.activeSetID = setID
		state.pendingSetID = nil
		state.stopAfterSet = false
		state.currentIndex = 0
		state.currentLineEnd = 0
		self:StartCurrentSet()
		return "started"
	end

	state.pendingSetID = setID
	state.stopAfterSet = false
	self:UpdateRelayScheduleState()

	return "queued"
end

function PLUGIN:RequestStop()
	local state = self:GetState()

	if (!state.activeSetID) then
		return "idle"
	end

	if (!state.isPlayingSet) then
		self:ResetSchedule(true)
		return "stopped"
	end

	state.pendingSetID = nil
	state.stopAfterSet = true
	self:UpdateRelayScheduleState()

	return "pending"
end

function PLUGIN:SaveData()
	local data = {
		entities = {}
	}

	for _, entity in ipairs(self:GetRelayEntities()) do
		data.entities[#data.entities + 1] = {
			pos = entity:GetPos(),
			ang = entity:GetAngles(),
			volume = entity:GetVolume()
		}
	end

	self:SetData(data)
end

function PLUGIN:LoadData()
	local data = self:GetData() or {}

	for _, savedData in ipairs(data.entities or {}) do
		local entity = ents.Create("ix_breencast")

		entity:SetPos(savedData.pos)
		entity:SetAngles(savedData.ang)
		entity:Spawn()
		entity:SetVolume(savedData.volume or self.defaultVolume)
	end

	self:ResetSchedule(true)
end

function PLUGIN:InitializedPlugins()
	self.voiceDependencyMissing = !self:IsVoicePluginAvailable()

	if (self.voiceDependencyMissing) then
		ErrorNoHalt("[Breencast] ixvoice plugin is required for Breencast scheduling.\n")
	end
end

function PLUGIN:OnEntityRemoved(entity)
	if (entity:GetClass() == "ix_breencast") then
		timer.Simple(0, function()
			if (!self:HasRelayEntities()) then
				self:StopBecauseUnavailable()
			end
		end)
	end
end
