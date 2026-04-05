include("shared.lua")

local SCREEN_SCALE = 0.03
local ACTIVE_COLOR = Color(110, 255, 110, 240)
local DIM_COLOR = Color(25, 70, 25, 220)
local GLOW_MATERIAL = ix.util.GetMaterial("sprites/glow04_noz")
local COMBINE_IDLE_SOUND = "ambient/machines/combine_terminal_loop1.wav"
local GENERAL_IDLE_SOUND = "npc/scanner/combat_scan_loop6.wav"
local CLIENT_IDLE_CHECK_INTERVAL = 0.2
local COMBINE_IDLE_VOLUME = 0.16
local GENERAL_IDLE_VOLUME = 0.12
local GENERAL_IDLE_PITCH = 108
local GENERAL_LIGHT_COLOR = Color(96, 220, 128)
local CIVIC_LIGHT_COLOR = Color(110, 255, 110)
local GENERAL_LIGHT_BRIGHTNESS = 1.15
local CIVIC_LIGHT_BRIGHTNESS = 2.8
local GENERAL_LIGHT_SIZE = 72
local CIVIC_LIGHT_SIZE = 160
local SCREEN_LIGHT_INNER_ANGLE = 18
local SCREEN_LIGHT_OUTER_ANGLE = 64

local function IsGeneralMonitor(definition)
	return definition and definition.family == "general" and definition.role == "monitor"
end

local function StopIdleSound(self, fadeTime)
	if (!self.ixIdleSound) then
		return
	end

	if (fadeTime and fadeTime > 0) then
		self.ixIdleSound:FadeOut(fadeTime)
	else
		self.ixIdleSound:Stop()
	end

	self.ixIdleSoundPath = nil
end

local function GetIdleSoundConfig(self)
	local plugin = ix.plugin.Get("interactive_computers")
	local definition = plugin and (plugin:GetAssemblyDefinition(self) or plugin:GetComputerDefinition(self:GetClass()))

	if (!definition or !definition.family) then
		return
	end

	if (definition.family == "combine") then
		return COMBINE_IDLE_SOUND, COMBINE_IDLE_VOLUME, 100
	end

	if (definition.family == "general") then
		return GENERAL_IDLE_SOUND, GENERAL_IDLE_VOLUME, GENERAL_IDLE_PITCH
	end
end

local function ApplyScreenLight(dlight, position, direction, color, brightness, size, decay)
	if (!dlight) then
		return
	end

	dlight.pos = position
	dlight.r = color.r
	dlight.g = color.g
	dlight.b = color.b
	dlight.brightness = brightness
	dlight.Decay = decay
	dlight.Size = size
	dlight.dir = direction
	dlight.innerangle = SCREEN_LIGHT_INNER_ANGLE
	dlight.outerangle = SCREEN_LIGHT_OUTER_ANGLE
	dlight.DieTime = CurTime() + 0.1
end

function ENT:UpdateIdleSound()
	local soundPath, volume, pitch = GetIdleSoundConfig(self)
	local shouldPlay = soundPath and self:GetNetVar("powered", false)

	if (!shouldPlay) then
		StopIdleSound(self, 0.35)
		return
	end

	if (self.ixIdleSoundPath != soundPath) then
		StopIdleSound(self)
		self.ixIdleSound = nil
	end

	if (!self.ixIdleSound) then
		self.ixIdleSound = CreateSound(self, soundPath)
		self.ixIdleSoundPath = soundPath
	end

	if (!self.ixIdleSound) then
		return
	end

	if (!self.ixIdleSound:IsPlaying()) then
		self.ixIdleSound:PlayEx(0, pitch)
	end

	self.ixIdleSound:ChangePitch(pitch, 0)
	self.ixIdleSound:ChangeVolume(volume, 0.25)
end

function ENT:Initialize()
	self:UpdateIdleSound()
end

function ENT:Think()
	self:UpdateIdleSound()
	self:SetNextClientThink(CurTime() + CLIENT_IDLE_CHECK_INTERVAL)

	return true
end

function ENT:OnRemove()
	StopIdleSound(self)
	self.ixIdleSound = nil
end

function ENT:Draw()
	self:DrawModel()
end

local MAX_LIGHT_DIST = 1000 * 1000

function ENT:DrawTranslucent()
	-- Lighting culling based on distance below


	-- Point 4: Performance - only create lighting when the player is close
	if (EyePos():DistToSqr(self:GetPos()) > MAX_LIGHT_DIST) then
		return
	end

	if (!self:GetNetVar("powered", false)) then
		return
	end

	local plugin = ix.plugin.Get("interactive_computers")
	local definition = plugin and plugin:GetComputerDefinition(self:GetClass())
	if (!definition) then
		return
	end

	if (IsGeneralMonitor(definition)) then
		local lightPosition = self:GetPos() + self:GetForward() * 11 + self:GetUp() * 10
		local dlight = DynamicLight(self:EntIndex())

		ApplyScreenLight(dlight, lightPosition, self:GetForward(), GENERAL_LIGHT_COLOR, GENERAL_LIGHT_BRIGHTNESS, GENERAL_LIGHT_SIZE, 140)

		return
	end

	if (self:GetClass() != "ix_computer_civic_interface") then
		return
	end

	local position = self:GetPos() + self:GetUp() * 33 + self:GetForward() * 2 + self:GetRight() * 13
	local color = Color(110, 255, 110)

	-- Point 2: Fake Light (Glow Sprite) - visual light source visible within range
	render.SetMaterial(GLOW_MATERIAL)
	render.DrawSprite(position, 10, 10, color)

	-- Level 1: Dynamic Light - illuminate surroundings when close
	local dlight = DynamicLight(self:EntIndex())

	ApplyScreenLight(dlight, position, self:GetForward(), CIVIC_LIGHT_COLOR, CIVIC_LIGHT_BRIGHTNESS, CIVIC_LIGHT_SIZE, 1200)
end

function ENT:OnPopulateEntityInfo(container)
	local plugin = ix.plugin.Get("interactive_computers")
	local displayName = plugin and plugin:GetDisplayName(self:GetClass()) or L("interactiveComputer")
	local isInteractive = plugin and plugin:IsInteractiveComputer(self)
	local definition = plugin and plugin:GetComputerDefinition(self:GetClass())

	local name = container:AddRow("name")
	name:SetImportant()
	name:SetText(displayName)
	name:SizeToContents()

	local description = container:AddRow("description")
	description:SetText(L(isInteractive and "interactiveComputerDesc" or "interactiveComputerSupportDesc"))
	description:SizeToContents()

	if (isInteractive) then
		local action = container:AddRow("action")
		action:SetText(L("interactiveComputerUse"))
		action:SetBackgroundColor(Color(85, 127, 242, 50))
		action:SizeToContents()
	end
end
