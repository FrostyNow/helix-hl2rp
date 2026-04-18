
local FADE_TIME = 1.5
local LETTERBOX_HEIGHT = 0.08

local afkView = {}
local afkSceneCache = nil
local afkSceneIndex = 1
local afkSceneStart = 0
local afkFadeAlpha = 0
local afkLetterboxAlpha = 0

local function BuildSceneList()
	local mapscenePlugin = ix.plugin.list["mapscene"]
	if (not mapscenePlugin or not mapscenePlugin.scenes) then return nil end

	local scenes = mapscenePlugin.scenes
	if (table.IsEmpty(scenes)) then return nil end

	local list = {}

	for k, v in pairs(scenes) do
		list[#list + 1] = {key = k, value = v}
	end

	return (#list > 0) and list or nil
end

function PLUGIN:CalcView(client, origin, angles, fov)
	if (not client:GetNetVar("IsAFK")) then
		afkSceneCache = nil
		afkSceneIndex = 1
		afkSceneStart = 0
		afkFadeAlpha = 0
		return
	end

	if (not ix.config.Get("afkMapScene")) then return end

	if (not afkSceneCache) then
		afkSceneCache = BuildSceneList()
		afkSceneStart = CurTime()
		afkSceneIndex = 1
	end

	if (not afkSceneCache) then return end

	local interval = ix.config.Get("afkMapSceneInterval")
	local curTime = CurTime()
	local elapsed = curTime - afkSceneStart

	if (elapsed >= interval) then
		afkSceneStart = curTime
		elapsed = 0
		afkSceneIndex = (afkSceneIndex % #afkSceneCache) + 1

		if (afkSceneIndex > #afkSceneCache) then
			afkSceneIndex = 1
		end
	end

	if (elapsed < FADE_TIME) then
		afkFadeAlpha = math.Clamp(1 - elapsed / FADE_TIME, 0, 1) * 255
	elseif (elapsed > interval - FADE_TIME) then
		afkFadeAlpha = math.Clamp((elapsed - (interval - FADE_TIME)) / FADE_TIME, 0, 1) * 255
	else
		afkFadeAlpha = 0
	end

	local scene = afkSceneCache[afkSceneIndex]
	if (not scene) then return end

	local k, v = scene.key, scene.value
	local realOrigin, realAngles
	local fraction = math.Clamp(elapsed / interval, 0, 1)

	if (isvector(k)) then
		realOrigin = LerpVector(fraction, k, v[1])
		realAngles = LerpAngle(fraction, v[2], v[3])
	elseif (v.origin) then
		realOrigin = LerpVector(fraction, v.origin, v[1])
		realAngles = LerpAngle(fraction, v[2], v[3])
	else
		realOrigin = v[1]
		realAngles = v[2]
	end

	if (realOrigin and realAngles) then
		afkView.origin = realOrigin
		afkView.angles = Angle(realAngles.p, realAngles.y, 0)
		return afkView
	end
end

function PLUGIN:ShouldDrawLocalPlayer(client)
	if (client:GetNetVar("IsAFK") and ix.config.Get("afkMapScene") and afkSceneCache ~= nil) then
		return false
	end
end


function PLUGIN:HUDPaint()
	local client = LocalPlayer()
	local isAFKScene = IsValid(client) and client:GetNetVar("IsAFK")
		and ix.config.Get("afkMapScene") and (afkSceneCache ~= nil)

	afkLetterboxAlpha = Lerp(FrameTime() * 3, afkLetterboxAlpha, isAFKScene and 255 or 0)

	if (isAFKScene and afkFadeAlpha > 0) then
		surface.SetDrawColor(0, 0, 0, afkFadeAlpha)
		surface.DrawRect(0, 0, ScrW(), ScrH())
	end

	if (afkLetterboxAlpha > 1) then
		local barHeight = math.ceil(ScrH() * LETTERBOX_HEIGHT)
		surface.SetDrawColor(0, 0, 0, afkLetterboxAlpha)
		surface.DrawRect(0, 0, ScrW(), barHeight)
		surface.DrawRect(0, ScrH() - barHeight, ScrW(), barHeight)
	end
end

function PLUGIN:PopulateCharacterInfo(client, character, container)
	if (client:Alive() and client:GetNetVar("IsAFK")) then
		local panel = container:AddRow("afk")
		panel:SetText(L("charAFK"))
		panel:SetBackgroundColor(Color(30, 30, 30, 255))
		panel:SizeToContents()
		panel:Dock(BOTTOM)
	end
end
