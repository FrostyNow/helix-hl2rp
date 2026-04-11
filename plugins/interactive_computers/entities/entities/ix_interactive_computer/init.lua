AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local GENERAL_BOOT_SOUND = "npc/scanner/combat_scan1.wav"
local ACTIVE_CHECK_INTERVAL = 3.0 -- Throttled from 0.2s for server performance
local SUPPORT_CHECK_INTERVAL = 5.0 -- Throttled from 1.0s

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
		className or self:GetClass(),
		nil,
		nil,
		nil,
		true
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

function ENT:GetComputerDataReadOnly()
	return self.ixComputerData or {}
end

function ENT:SetPowered(state, silent)
	local plugin = ix.plugin.Get("interactive_computers")
	state = state == true
	local previousState = self.ixPowered == true or self:GetNetVar("powered", false)
	local hasStateChanged = previousState != state
	self.ixPowered = state
	self:SetNetVar("powered", state)

	local definition = plugin and plugin:GetAssemblyDefinition(self)
	local isCombineFamily = definition and definition.family == "combine"
	local isGeneralFamily = definition and definition.family == "general"
	local bootTimerID = "ixInteractiveComputerBootTone" .. self:EntIndex()

	if (plugin) then
		local visualState = state and "on" or (self:GetNetVar("assemblyError", false) and "error" or "off")
		plugin:UpdateComputerVisualState(self, visualState)
	end

	if (isGeneralFamily) then
		timer.Remove(bootTimerID)

		if (state and hasStateChanged) then
			timer.Create(bootTimerID, 1, 1, function()
				if (IsValid(self) and self:GetPowered()) then
					self:EmitSound(GENERAL_BOOT_SOUND, 80, 108, 0.5)
				end
			end)
		end
	end

	if (!silent and hasStateChanged) then
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
	if (!plugin) then
		return
	end

	if (plugin:IsSupportComputer(self)) then
		self:NextThink(CurTime() + SUPPORT_CHECK_INTERVAL)
		return true
	end

	-- Throttle assembly validation: only check if we moved or every few seconds.
	local currentTime = CurTime()
	local lastCheck = self.ixLastAssemblyCheck or 0
	local pos = self:GetPos()

	if (lastCheck + ACTIVE_CHECK_INTERVAL > currentTime and (self.ixLastAssemblyPos or Vector()):DistToSqr(pos) < 1) then
		self:NextThink(currentTime + 1)
		return true
	end

	self.ixLastAssemblyCheck = currentTime
	self.ixLastAssemblyPos = pos

	local bPowered = self:GetPowered()
	local bValid = plugin:IsComputerAssemblyValid(self)
	local bHasError = !bValid

	if (bPowered) then
		if (bHasError) then
			if (!self:IsCombineTerminal() and plugin.HandleGeneralAssemblyFailure) then
				plugin:HandleGeneralAssemblyFailure(self)
			else
				if (self:GetNetVar("assemblyError") != true) then
					self:SetNetVar("assemblyError", true)
					plugin:UpdateComputerVisualState(self, "error")
				end
				self:SetPowered(false)
			end
		elseif (self:GetNetVar("assemblyError") != false) then
			self:SetNetVar("assemblyError", false)
			plugin:UpdateComputerVisualState(self, "on")
		end
	else
		if (self:GetNetVar("assemblyError") != bHasError) then
			self:SetNetVar("assemblyError", bHasError)
			plugin:UpdateComputerVisualState(self, bHasError and "error" or "off")
		end
	end

	self:NextThink(currentTime + 1)
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
	timer.Remove("ixInteractiveComputerBootTone" .. self:EntIndex())
end
