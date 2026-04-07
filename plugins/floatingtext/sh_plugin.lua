local PLUGIN = PLUGIN

PLUGIN.name = "Floating Text"
PLUGIN.author = "Frosty"
PLUGIN.description = "Can place persistent floating texts."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

PLUGIN.texts = PLUGIN.texts or {}

ix.lang.AddTable("english", {
	cmdFloatingTextAdd = "Add a persistent floating text at your looking position.",
	cmdFloatingTextRemove = "Remove the nearest floating text.",
	cmdFloatingTextClear = "Clear all floating texts in the map.",
	floatingTextAdded = "Added floating text: '%s'",
	floatingTextRemoved = "Removed floating text: '%s'",
	floatingTextNotFound = "No floating text found nearby.",
	floatingTextCleared = "Cleared all floating texts."
})

ix.lang.AddTable("korean", {
	cmdFloatingTextAdd = "바라보는 위치에 영구적인 떠 있는 텍스트를 추가합니다.",
	cmdFloatingTextRemove = "가장 가까운 떠 있는 텍스트를 제거합니다.",
	cmdFloatingTextClear = "맵의 모든 떠 있는 텍스트를 제거합니다.",
	floatingTextAdded = "떠 있는 텍스트가 추가되었습니다: '%s'",
	floatingTextRemoved = "떠 있는 텍스트가 제거되었습니다: '%s'",
	floatingTextNotFound = "근처에 떠 있는 텍스트가 없습니다.",
	floatingTextCleared = "모든 떠 있는 텍스트가 제거되었습니다."
})

ix.config.Add("floatingTextRange", 300, "Maximum distance at which floating text is visible.", nil, {
	data = {min = 100, max = 2000},
	category = "Floating Text"
})


ix.command.Add("FloatingTextAdd", {
	description = "@cmdFloatingTextAdd",
	privilege = "Manage Floating Text",
	superAdminOnly = true,
	arguments = {
		ix.type.string
	},
	OnRun = function(self, client, text)
		local trace = client:GetEyeTraceNoCursor()
		local pos = trace.HitPos + trace.HitNormal * 2

		table.insert(PLUGIN.texts, {
			pos = pos,
			text = text,
			id = os.time() + math.random(1, 1000)
		})

		PLUGIN:SaveData()
		PLUGIN:SyncTexts()

		return L("floatingTextAdded", client, text)
	end
})

ix.command.Add("FloatingTextRemove", {
	description = "@cmdFloatingTextRemove",
	privilege = "Manage Floating Text",
	superAdminOnly = true,
	OnRun = function(self, client)
		local pos = client:GetEyeTraceNoCursor().HitPos
		local nearestIndex = nil
		local nearestDist = 128

		for k, v in ipairs(PLUGIN.texts) do
			local dist = v.pos:Distance(pos)
			if (dist < nearestDist) then
				nearestDist = dist
				nearestIndex = k
			end
		end

		if (nearestIndex) then
			local text = PLUGIN.texts[nearestIndex].text
			table.remove(PLUGIN.texts, nearestIndex)
			PLUGIN:SaveData()
			PLUGIN:SyncTexts()
			return L("floatingTextRemoved", client, text)
		end

		return L("floatingTextNotFound", client)
	end
})

ix.command.Add("FloatingTextClear", {
	description = "@cmdFloatingTextClear",
	privilege = "Manage Floating Text",
	superAdminOnly = true,
	OnRun = function(self, client)
		PLUGIN.texts = {}
		PLUGIN:SaveData()
		PLUGIN:SyncTexts()
		return L("floatingTextCleared", client)
	end
})

if (SERVER) then
	util.AddNetworkString("ixFloatingTextSync")

	function PLUGIN:SaveData()
		self:SetData(self.texts)
	end

	function PLUGIN:LoadData()
		self.texts = self:GetData() or {}
	end

	function PLUGIN:SyncTexts(receiver)
		net.Start("ixFloatingTextSync")
			net.WriteTable(self.texts)
		if (receiver) then
			net.Send(receiver)
		else
			net.Broadcast()
		end
	end

	function PLUGIN:PlayerLoadedCharacter(client, character, prevChar)
		self:SyncTexts(client)
	end
else
	net.Receive("ixFloatingTextSync", function()
		PLUGIN.texts = net.ReadTable()
	end)

	function PLUGIN:LoadFonts(font, genericFont)
		surface.CreateFont("ixFloatingTextFont", {
			font = genericFont,
			size = 32,
			weight = 500,
			extended = true,
			antialias = true
		})
	end

	function PLUGIN:PostDrawTranslucentRenderables(bDrawingDepth, bDrawingSkybox)
		if (bDrawingDepth or bDrawingSkybox) then
			return
		end

		local client = LocalPlayer()
		if (not IsValid(client)) then return end

		local eyePos = EyePos()
		local maxRange = ix.config.Get("floatingTextRange", 300)
		local maxRangeSqr = maxRange * maxRange

		for _, v in ipairs(self.texts) do
			local distSqr = v.pos:DistToSqr(eyePos)
			if (distSqr > maxRangeSqr) then continue end

			local dist = math.sqrt(distSqr)
			local alpha = 255
			
			if (dist > maxRange * 0.7) then
				alpha = math.Remap(dist, maxRange * 0.7, maxRange, 255, 0)
			end

			local angle = EyeAngles()
			angle:RotateAroundAxis(angle:Up(), -90)
			angle:RotateAroundAxis(angle:Forward(), 90)

			cam.Start3D2D(v.pos, angle, 0.1)
				draw.SimpleTextOutlined(
					v.text,
					"ixFloatingTextFont",
					0, 0,
					ColorAlpha(color_white, alpha),
					TEXT_ALIGN_CENTER,
					TEXT_ALIGN_CENTER,
					1,
					ColorAlpha(color_black, alpha)
				)
			cam.End3D2D()
		end
	end
end

