local RADIO_NOISE_DISTANCE = 1200
local RADIO_NOISE_DISTANCE_SQR = RADIO_NOISE_DISTANCE * RADIO_NOISE_DISTANCE
local FORCE_RADIO_NOISE_TEST = false
local RADIO_FILTER_DSP = 31
local RADIO_FILTER_MIN_PITCH = 95
local RADIO_FILTER_MAX_PITCH = 105
local RADIO_STATIC_SPACING_MIN = 0.9
local RADIO_STATIC_SPACING_MAX = 1.4
local RADIO_STATIC_VOLUME_SCALE = 0.35
local RADIO_STATIC_SOUNDS = {
	"ambient/levels/prison/radio_random1.wav",
	"ambient/levels/prison/radio_random2.wav",
	"ambient/levels/prison/radio_random6.wav"
}

local function playVoiceSequence(entity, sounds, volume)
	ix.util.EmitQueuedSounds(entity, sounds, nil, nil, volume)
end

local function playRadioFilteredVoice(entity, sounds, volume)
	local delay = 0
	local spacing = 0.1

	for _, soundInfo in ipairs(sounds) do
		local postSet, preSet = 0, 0
		local soundPath = soundInfo

		if (istable(soundInfo)) then
			postSet = soundInfo[2] or 0
			preSet = soundInfo[3] or 0
			soundPath = soundInfo[1]
		end

		local length = SoundDuration(soundPath)
		delay = delay + preSet

		timer.Simple(delay, function()
			if (IsValid(entity)) then
				local filterPitch = math.random(RADIO_FILTER_MIN_PITCH, RADIO_FILTER_MAX_PITCH)
				entity:EmitSound(soundPath, volume or 75, filterPitch, 1, CHAN_AUTO, 0, RADIO_FILTER_DSP)
			end
		end)

		delay = delay + length + postSet + spacing
	end

	local totalDuration = delay
	local staticDelay = 0
	local staticLevel = math.Clamp(math.floor((volume or 75) * RADIO_STATIC_VOLUME_SCALE), 35, 80)

	while (staticDelay < totalDuration) do
		staticDelay = staticDelay + math.Rand(RADIO_STATIC_SPACING_MIN, RADIO_STATIC_SPACING_MAX)

		if (staticDelay >= totalDuration) then
			break
		end

		timer.Simple(staticDelay, function()
			if (IsValid(entity)) then
				entity:EmitSound(table.Random(RADIO_STATIC_SOUNDS), staticLevel, math.random(90, 110), 0.8, CHAN_STATIC)
			end
		end)
	end
end

netstream.Hook("PlayQueuedSound", function(entity, sounds, delay, spacing, volume, pitch)
	entity = entity or LocalPlayer()

	ix.util.EmitQueuedSounds(entity, sounds, delay, spacing, volume, pitch)
end)

netstream.Hook("voicePlay", function(sounds, volume, index, isRadioTransmission, voiceClassName)
	if (index) then
		local client = Entity(index)

		if (IsValid(client)) then
			local loweredClass = string.lower(voiceClassName or "")
			local shouldUseRadioFilter = isRadioTransmission and (
				FORCE_RADIO_NOISE_TEST
				or (IsValid(LocalPlayer()) and LocalPlayer():GetPos():DistToSqr(client:GetPos()) > RADIO_NOISE_DISTANCE_SQR)
			) and loweredClass != "overwatch"

			if (shouldUseRadioFilter) then
				playRadioFilteredVoice(client, sounds, volume)
			else
				playVoiceSequence(client, sounds, volume)
			end
		end
	else
		playVoiceSequence(LocalPlayer(), sounds, volume)
	end
end)
