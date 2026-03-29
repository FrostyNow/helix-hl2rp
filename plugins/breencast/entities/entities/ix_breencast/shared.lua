ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Breen Cast"
ENT.Author = "Antigravity"
ENT.Category = "Helix"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Playing")
    self:NetworkVar("Int", 0, "Interval")
    self:NetworkVar("Bool", 1, "Looping")
end
