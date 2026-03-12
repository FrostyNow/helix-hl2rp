AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local COMBINE_LOOP_SOUND = "ambient/machines/combine_terminal_loop1.wav"
local GENERAL_LOOP_SOUND = "npc/scanner/combat_scan_loop6.wav"
local GENERAL_BOOT_SOUND = "npc/scanner/combat_scan1.wav"
local GENERAL_LOOP_INTERVAL = 1.1

function ENT:Initialize()
	local plugin = ix.plugin.Get("interactive_computers")
	local model = self.ixModelOverride or self.SpawnModel or (plugin and plugin.defaultModel) or "models/props/cs_office/computer.mdl"

	self:SetComputerModel(model)
	self:SetUseType(SIMPLE_USE)
	self:DrawShadow(true)
	self:SetNetVar("assemblyError", false)
	self:SetPowered(false, true)
	self:SetComputerData(plugin and plugin:CreateDefaultData() or {})
end

function ENT:SpawnFunction(client, trace, className)
	if (!trace.Hit or trace.HitSky) then
		return
	end

	local plugin = ix.plugin.Get("interactive_computers")
	if (!plugin) then
		return
	end

	local entity = plugin:CreateComputer(
		trace.HitPos + trace.HitNormal * 16,
		Angle(0, client:EyeAngles().y - 90, 0),
		className or self:GetClass()
	)

	if (IsValid(entity)) then
		plugin:SaveData()
	end

	return entity
end

function ENT:SetComputerModel(model)
	local plugin = ix.plugin.Get("interactive_computers")
	model = string.lower(model or "")

	if (plugin and !plugin:IsValidComputerModel(model)) then
		model = plugin.defaultModel
	end

	self:SetModel(model)
	self:SetCombineTerminal(plugin and plugin:IsCombineModel(model) or false)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)

	local physicsObject = self:GetPhysicsObject()
	if (IsValid(physicsObject)) then
		physicsObject:Wake()
	end
end

function ENT:SetCombineTerminal(state)
	self.ixCombineTerminal = state == true
	self:SetNetVar("combineTerminal", self.ixCombineTerminal)
end

function ENT:IsCombineTerminal()
	return self.ixCombineTerminal == true or self:GetNetVar("combineTerminal", false)
end

function ENT:SetSecurityBypass(duration)
	duration = tonumber(duration) or 0
	self.ixSecurityBypassUntil = CurTime() + math.max(duration, 0)
	self:SetNetVar("securityBypassUntil", self.ixSecurityBypassUntil)
end

function ENT:IsSecurityBypassed()
	return (self.ixSecurityBypassUntil or self:GetNetVar("securityBypassUntil", 0)) > CurTime()
end

function ENT:SetComputerID(computerID)
	self.ixComputerID = tonumber(computerID) or 0
	self:SetNetVar("computerID", self.ixComputerID)
end

function ENT:GetComputerID()
	return self.ixComputerID or self:GetNetVar("computerID", 0)
end

function ENT:SetComputerData(data)
	local plugin = ix.plugin.Get("interactive_computers")
	self.ixComputerData = plugin and plugin:NormalizeData(data) or table.Copy(data or {})
end

function ENT:GetComputerData()
	return table.Copy(self.ixComputerData or {})
end

function ENT:SetPowered(state, silent)
	local plugin = ix.plugin.Get("interactive_computers")
	state = state == true
	self.ixPowered = state
	self:SetNetVar("powered", state)

	local definition = plugin and plugin:GetAssemblyDefinition(self)
	local isCombineFamily = definition and definition.family == "combine"
	local isGeneralFamily = definition and definition.family == "general"
	local bootTimerID = "ixInteractiveComputerBootTone" .. self:EntIndex()
	local generalLoopTimerID = "ixInteractiveComputerGeneralLoop" .. self:EntIndex()

	if (plugin) then
		local visualState = state and "on" or (self:GetNetVar("assemblyError", false) and "error" or "off")
		plugin:UpdateComputerVisualState(self, visualState)
	end

	if (isCombineFamily) then
		self.ixLoopSound = self.ixLoopSound or CreateSound(self, COMBINE_LOOP_SOUND)

		if (state) then
			if (self.ixLoopSound) then
				self.ixLoopSound:PlayEx(0.08, 100)
			end
		elseif (self.ixLoopSound) then
			self.ixLoopSound:Stop()
		end
	elseif (isGeneralFamily) then
		if (state) then
			timer.Remove(generalLoopTimerID)
			self:EmitSound(GENERAL_LOOP_SOUND, 80, 108, 0.12)
			timer.Create(generalLoopTimerID, GENERAL_LOOP_INTERVAL, 0, function()
				if (IsValid(self) and self:GetPowered()) then
					self:EmitSound(GENERAL_LOOP_SOUND, 80, 108, 0.12)
				else
					timer.Remove(generalLoopTimerID)
				end
			end)

			timer.Remove(bootTimerID)
			timer.Create(bootTimerID, 1, 1, function()
				if (IsValid(self) and self:GetPowered()) then
					self:EmitSound(GENERAL_BOOT_SOUND, 80, 108, 0.5)
				end
			end)
		else
			timer.Remove(generalLoopTimerID)
			timer.Remove(bootTimerID)
		end
	end

	if (!silent) then
		if (isCombineFamily) then
			self:EmitSound(state and "buttons/combine_button1.wav" or "buttons/combine_button2.wav", 80, state and 110 or 95, 0.75)
			if (!state) then
				self:EmitSound("ambient/machines/combine_terminal_idle4.wav", 70, 100, 0.75)
			end
		elseif (state) then
			self:EmitSound("buttons/button1.wav", 80, 100, 0.6)
		else
			self:EmitSound("npc/scanner/scanner_blip1.wav", 80, 88, 0.35)
		end
	end
end

function ENT:GetPowered()
	return self.ixPowered == true or self:GetNetVar("powered", false)
end

function ENT:Think()
	local plugin = ix.plugin.Get("interactive_computers")
	if (plugin and plugin:IsSupportComputer(self)) then
		self:NextThink(CurTime() + 1)
		return true
	end

	if (plugin and self:GetPowered() and !plugin:IsComputerAssemblyValid(self)) then
		self:SetNetVar("assemblyError", true)
		plugin:UpdateComputerVisualState(self, "error")
		self:SetPowered(false)
	elseif (plugin and !self:GetPowered()) then
		local hasError = !plugin:IsComputerAssemblyValid(self)
		self:SetNetVar("assemblyError", hasError)
		plugin:UpdateComputerVisualState(self, hasError and "error" or "off")
	end

	self:NextThink(CurTime() + 1)
	return true
end

function ENT:Use(activator)
	if (!IsValid(activator) or !activator:IsPlayer()) then
		return
	end

	local plugin = ix.plugin.Get("interactive_computers")
	if (plugin and plugin:IsInteractiveComputer(self)) then
		plugin:OpenComputer(activator, self)
	end
end

function ENT:OnRemove()
	if (self.ixLoopSound) then
		self.ixLoopSound:Stop()
		self.ixLoopSound = nil
	end

	timer.Remove("ixInteractiveComputerBootTone" .. self:EntIndex())
	timer.Remove("ixInteractiveComputerGeneralLoop" .. self:EntIndex())
end
