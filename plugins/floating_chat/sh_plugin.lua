local PLUGIN = PLUGIN

PLUGIN.name = "Floating Chat"
PLUGIN.author = "Frosty"
PLUGIN.description = "Displays chat messages above players' heads."

ix.lang.AddTable("english", {
	cmdTestChat = "Sends a message to yourself to test floating chat.",
	optSeeOwnFloatingChat = "See own floating chat bubbles",
	optdSeeOwnFloatingChat = "Whether or not you should see your own floating chat bubbles.",
})
ix.lang.AddTable("korean", {
	["Floating Chat"] = "말풍선",
	cmdTestChat = "말풍선 테스트를 위해 자신에게 메시지를 보냅니다.",
	optSeeOwnFloatingChat = "자신의 말풍선 보기",
	optdSeeOwnFloatingChat = "자신의 머리 위에 표시되는 말풍선을 볼지 설정합니다.",
})

-- Configs
ix.config.Add("floatingChatEnabled", true, "Whether or not floating chat is enabled.", nil, {
	category = "Floating Chat"
})

ix.config.Add("floatingChatDuration", 10, "How long floating chat messages stay visible.", nil, {
	data = {min = 1, max = 20},
	category = "Floating Chat"
})

ix.config.Add("floatingChatFadeTime", 5, "How long it takes for floating chat messages to fade out.", nil, {
	data = {min = 0.1, max = 5},
	category = "Floating Chat"
})

-- Shared Table for Chat Types
local CHAT_TYPES = {
	["ic"] = true,
	["y"] = true,
	["w"] = true,
	["radio_eavesdrop"] = true,
	["radio_eavesdrop_yell"] = true,
	["radio_eavesdrop_whisper"] = true,
	["radio_whisper"] = true,
	["radio_yell"] = true,
	["request_eavesdrop"] = true,
	["vortigese"] = true
}

ix.command.Add("TestBotChat", {
	description = "@cmdTestChat",
	adminOnly = true,
	arguments = ix.type.text,
	adminOnly = true,
	OnRun = function(self, ply, message)
		local bot = player.GetBots()[1]
		message = message or "Default message."

		if (!IsValid(bot)) then
			RunConsoleCommand("bot")
			timer.Simple(0.5, function()
				bot = player.GetBots()[1]
				if (IsValid(bot)) then
					ix.chat.Send(bot, "ic", message)
				end
			end)
		else
			ix.chat.Send(bot, "ic", message)
		end
	end
})

-- Client Side Logic
if (CLIENT) then
	ix.option.Add("seeOwnFloatingChat", ix.type.bool, false, {
		category = "Floating Chat"
	})

	local headOffset = Vector(0, 0, 80)
	local boneOffset = Vector(0, 1, 0)

	function PLUGIN:LoadFonts(font, genericFont)
		surface.CreateFont("ixFloatingChatFont", {
			font = genericFont,
			size = 44,
			extended = true,
			weight = 500
		})
		surface.CreateFont("ixFloatingChatFontLarge", {
			font = genericFont,
			size = 56,
			extended = true,
			weight = 800
		})
		surface.CreateFont("ixFloatingChatFontSmall", {
			font = genericFont,
			size = 36,
			extended = true,
			weight = 500
		})
	end

	function PLUGIN:MessageReceived(client, info)
		if (!ix.config.Get("floatingChatEnabled", true)) then return end
		if (!IsValid(client) or !client:IsPlayer()) then return end
		if (client:GetMoveType() == MOVETYPE_NOCLIP) then return end
		if (!CHAT_TYPES[info.chatType]) then return end

		client.ixFloatingChatData = client.ixFloatingChatData or {}

		local chatClass = ix.chat.classes[info.chatType]
		local color = color_white

		if (chatClass) then
			if (chatClass.GetColor) then
				color = chatClass:GetColor(client, info.text)
			elseif (chatClass.color) then
				color = chatClass.color
			else
				color = ix.config.Get("chatColor", Color(255, 255, 255))
			end
		end

		local font = "ixFloatingChatFont"

		if (info.chatType == "y" or info.chatType == "radio_eavesdrop_yell") then
			font = "ixFloatingChatFontLarge"
		elseif (info.chatType == "w" or info.chatType == "radio_eavesdrop_whisper" or info.chatType == "radio_whisper") then
			font = "ixFloatingChatFontSmall"
		end

		local text = info.text
		local lpCharacter = LocalPlayer():GetCharacter()

		if (info.chatType == "vortigese" and lpCharacter and !lpCharacter:IsVortigaunt()) then
			text = L("vortUnintelligible")
		end

		text = string.format("\"%s\"", text)

		surface.SetFont(font)
		local wrappedLines = self:WrapText(text, font, 800)

		if (#wrappedLines > 5) then
			local newLines = {}
			for i = 1, 4 do newLines[i] = wrappedLines[i] end
			newLines[5] = "..."
			wrappedLines = newLines
		end

		table.insert(client.ixFloatingChatData, {
			lines = wrappedLines,
			color = color,
			font = font,
			startTime = CurTime(),
			dieTime = CurTime() + ix.config.Get("floatingChatDuration", 5),
			range = math.max(chatClass and chatClass.range or 0, math.pow(ix.config.Get("chatRange", 280), 2))
		})

		if (#client.ixFloatingChatData > 3) then
			table.remove(client.ixFloatingChatData, 1)
		end
	end

	function PLUGIN:GetHeadPosition(client)
		local head = client:LookupBone("ValveBiped.Bip01_Head1")
		local position, angles

		if (head) then
			position, angles = client:GetBonePosition(head)
		else
			position = client:GetPos() + headOffset
			angles = client:GetAngles()
		end

		-- Position it physically forward (towards where the character is looking)
		local forward = angles:Forward()
		return position + boneOffset + (forward * 10)
	end

	function PLUGIN:PostDrawTranslucentRenderables()
		if (!ix.config.Get("floatingChatEnabled", true)) then return end

		local curTime = CurTime()
		local localPlayer = LocalPlayer()
		local eyePos = EyePos()
		local fadeTime = ix.config.Get("floatingChatFadeTime", 1)

		for _, client in player.Iterator() do
			if (!client.ixFloatingChatData or #client.ixFloatingChatData == 0) then continue end
			if (!client:Alive() and !client:IsBot()) then continue end
			if (client:GetMoveType() == MOVETYPE_NOCLIP) then continue end

			local distance = client:GetPos():DistToSqr(eyePos)
			if (client == localPlayer and !ix.option.Get("seeOwnFloatingChat", false)) then continue end

			local pos = self:GetHeadPosition(client)
			
			-- Use a fixed angle for billboarding that matches EyeAngles
			local angle = EyeAngles()
			angle:RotateAroundAxis(angle:Up(), -90)
			angle:RotateAroundAxis(angle:Forward(), 90)

			local realDist = math.sqrt(distance)
			local scale = math.Clamp(realDist * 0.001, 0.05, 0.5) * 0.5

			local offset = 0
			for i = #client.ixFloatingChatData, 1, -1 do
				local data = client.ixFloatingChatData[i]
				
				if (curTime > data.dieTime) then
					table.remove(client.ixFloatingChatData, i)
					continue
				end

				if (distance > data.range) then continue end

				local alpha = 255
				local timeRemaining = data.dieTime - curTime
				
				if (timeRemaining < fadeTime) then
					alpha = (timeRemaining / fadeTime) * 255
				end

				-- Stronger and earlier fade based on distance, maintaining at least 20% opacity
				local fraction = distance / data.range
				local distAlpha = (1 - math.Clamp((fraction - 0.2) / 0.4, 0, 0.8)) * 255
				alpha = math.min(alpha, distAlpha)

				cam.Start3D2D(pos + Vector(0, 0, offset), angle, scale)
					surface.SetFont(data.font)
					local th = 0
					for k, line in ipairs(data.lines) do
						local _, h = surface.GetTextSize(line)
						draw.SimpleTextOutlined(line, data.font, 0, -(#data.lines - k) * h, ColorAlpha(data.color, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, ColorAlpha(color_black, alpha))
						th = th + h
					end
				cam.End3D2D()

				offset = offset + (th * scale) + (20 * scale) -- Scaled spacing between messages
			end
		end
	end

	function PLUGIN:WrapText(text, font, maxWidth)
		surface.SetFont(font)
		local words = string.Explode(" ", text)
		local lines = {}
		local currentLine = ""

		for _, word in ipairs(words) do
			local w, _ = surface.GetTextSize(word)
			if (w > maxWidth) then
				if (currentLine != "") then table.insert(lines, currentLine) currentLine = "" end
				local tempLine = ""
				for i = 1, string.len(word) do
					local char = string.sub(word, i, i)
					local tw, _ = surface.GetTextSize(tempLine .. char)
					if (tw > maxWidth) then table.insert(lines, tempLine) tempLine = char
					else tempLine = tempLine .. char end
				end
				currentLine = tempLine
			else
				local testLine = currentLine == "" and word or currentLine .. " " .. word
				local tw, _ = surface.GetTextSize(testLine)
				if (tw > maxWidth) then table.insert(lines, currentLine) currentLine = word
				else currentLine = testLine end
			end
		end
		if (currentLine != "") then table.insert(lines, currentLine) end
		return lines
	end
end