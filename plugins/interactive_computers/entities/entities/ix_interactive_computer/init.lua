AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

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

	if (plugin) then
		local visualState = state and "on" or (self:GetNetVar("assemblyError", false) and "error" or "off")
		plugin:UpdateComputerVisualState(self, visualState)
	end

	if (!silent) then
		self:EmitSound(state and "buttons/combine_button1.wav" or "buttons/combine_button2.wav", 60, state and 110 or 95, 0.7)
	end
end

function ENT:GetPowered()
	return self.ixPowered == true or self:GetNetVar("powered", false)
end

function ENT:Think()
	local plugin = ix.plugin.Get("interactive_computers")

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
