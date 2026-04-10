Schema.voices = Schema.voices or {}
Schema.voices.stored = Schema.voices.stored or {}
Schema.voices.classes = Schema.voices.classes or {}

local langMapping = {
	en = "english",
	ko = "korean",
	kr = "korean"
}

local function getVoiceContentId(info)
	if (istable(info.table)) then
		local parts = {}

		for i = 1, #info.table do
			local v = info.table[i]
			parts[#parts + 1] = tostring(v[1]) .. ":" .. tostring(v[2])
		end

		table.sort(parts)
		return "T:" .. table.concat(parts, "|")
	end

	local soundStr = istable(info.sound) and table.concat(info.sound, "|") or tostring(info.sound)
	return "S:" .. tostring(info.text) .. "|" .. soundStr
end

function Schema.voices.Add(class, key, text, sound, global, onModify)
	class = string.lower(class)

	local keys = {}
	if (isstring(key)) then
		keys[1] = {key = key}
	elseif (istable(key)) then
		local i = 1
		for k, v in pairs(key) do
			if (isnumber(k)) then
				-- Sequential: 1=EN, 2=KO
				local lang = (k == 1) and "english" or (k == 2 and "korean" or nil)
				keys[#keys + 1] = {key = v, lang = lang}
			else
				-- Explicit: en="Alert", ko="경고"
				local lang = langMapping[k] or k
				keys[#keys + 1] = {key = v, lang = lang}
			end
		end
	end

	for _, data in ipairs(keys) do
		local k = string.lower(data.key)
		Schema.voices.stored[class] = Schema.voices.stored[class] or {}

		local info = {
			global = global,
			onModify = onModify,
			language = data.lang
		}

		if (!istable(text)) then
			info.text = text
			info.sound = sound
		else
			info.table = text
			info.global = sound
			info.onModify = global
		end

		Schema.voices.stored[class][k] = info
	end
end

function Schema.voices.GetDisplayable(class, client)
	local allVoices = Schema.voices.stored[string.lower(class)]
	if (!allVoices) then return {} end

	local clientLang = SERVER and ix.option.Get(client, "language", "english") or ix.option.Get("language", "english")
	clientLang = langMapping[clientLang] or clientLang

	local groups = {}
	for command, info in pairs(allVoices) do
		local id = getVoiceContentId(info)
		groups[id] = groups[id] or {}
		table.insert(groups[id], {command = command, info = info})
	end

	local results = {}
	for _, group in pairs(groups) do
		local bestEntry = nil
		local hasLanguageTags = false

		for _, entry in ipairs(group) do
			if (entry.info.language) then
				hasLanguageTags = true
				local voiceLang = langMapping[entry.info.language] or entry.info.language
				
				if (voiceLang == clientLang) then
					bestEntry = entry
					break
				end
			end
		end

		if (bestEntry) then
			results[bestEntry.command] = bestEntry.info
		elseif (hasLanguageTags) then
			-- If they have tags but none match client language, default to first (usually English)
			results[group[1].command] = group[1].info
		else
			-- Legacy or untagged entries, show all in group
			for _, entry in ipairs(group) do
				results[entry.command] = entry.info
			end
		end
	end

	return results
end

function Schema.voices.Get(class, key)
	class = string.lower(class)
	key = string.lower(key)

	if (Schema.voices.stored[class]) then
		return Schema.voices.stored[class][key]
	end
end

function Schema.voices.AddClass(class, condition)
	class = string.lower(class)

	Schema.voices.classes[class] = {
		condition = condition
	}
end

function Schema.voices.GetVoiceList(class, text, delay, client)
	text = string.Trim(tostring(text))
	local info = Schema.voices.stored[class]

	if !info then
		return
	end

	local output = {}
	local original = string.Explode(" ", text)
	local exploded = string.Explode(" ", text:lower())
	local phrase = ""
	local skip = 0
	local current = 0

	max = max or 5
	
	for k, v in ipairs(exploded) do
		if (k < skip) then
			continue
		end

		if (current < max) then
			local i = k
			local key = v

			local nextValue, nextKey

			while (true) do
				i = i + 1
				nextValue = exploded[i]

				if (!nextValue) then
					break
				end

				nextKey = key.." "..nextValue

				if (!info[nextKey]) then
					i = i + 1

					local nextValue2 = exploded[i]
					local nextKey2 = nextKey.." "..(nextValue2 or "")

					if (!nextValue2 or !info[nextKey2]) then
						i = i - 1

						break
					end

					nextKey = nextKey2
				end

				key = nextKey
			end

			if (info[key]) then

				local sound = ""
				local replacement = ""

				if (info[key].table) then
					local voiceTable = table.Random(info[key].table)

					replacement = voiceTable[1]
					sound = voiceTable[2]
				else
					replacement = info[key].text
					sound = info[key].sound
				end

				if (istable(sound)) then
					sound = table.Random(sound)
				end

				-- Apply localization if client is provided
				if (IsValid(client)) then
					replacement = L(replacement, client)
				end

				if (sound and sound != "") then
					output[#output + 1] = {sound, delay or 0.1}
					phrase = phrase..replacement.." "
					skip = i
					current = current + 1
				end
				
				continue
			else
				return nil
			end
		end

		phrase = phrase..original[k].." "
	end

	if (phrase:sub(#phrase, #phrase) == " ") then
		phrase = phrase:sub(1, -2)
	end

	return #output > 0 and output or nil, phrase
end

function Schema.voices.GetClass(client)
	local classes = {}

	if (!IsValid(client)) then
		return classes
	end

	for k, v in pairs(Schema.voices.classes) do
		if (v.condition(client)) then
			classes[#classes + 1] = k
		end
	end

	return classes
end