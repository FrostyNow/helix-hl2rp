ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Breencast"
ENT.Author = "Antigravity"
ENT.Category = "Helix"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.AutomaticFrameAdvance = true

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Playing")
	self:NetworkVar("Bool", 1, "Looping")
	self:NetworkVar("Bool", 2, "Broadcasting")
	self:NetworkVar("Bool", 3, "LiveRelay")
	self:NetworkVar("Float", 0, "Interval")
	self:NetworkVar("Float", 1, "ActiveUntil")
	self:NetworkVar("Float", 2, "BroadcastDuration")
	self:NetworkVar("Int", 0, "Volume")
	self:NetworkVar("String", 0, "CurrentText")
	self:NetworkVar("String", 1, "CurrentSource")
end

function ENT:IsRelayActive()
	return self:GetBroadcasting() and self:GetActiveUntil() > CurTime()
end
