Schema.voices = {}
Schema.voices.stored = {}
Schema.voices.classes = {}

function Schema.voices.Add(class, key, text, sound, global, onModify)
	class = string.lower(class)
	key = string.lower(key)

	Schema.voices.stored[class] = Schema.voices.stored[class] or {}
	if !istable(text) then
		Schema.voices.stored[class][key] = {
			text = text,
			sound = sound,
			global = global,
			onModify = onModify
		}
	else
		Schema.voices.stored[class][key] = {
			table = text,
			global = sound,
			onModify = global
		}
	end
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

function Schema.voices.GetVoiceList(class, text, delay)
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