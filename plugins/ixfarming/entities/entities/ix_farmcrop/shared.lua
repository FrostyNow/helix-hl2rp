ENT.Type = "anim"
ENT.PrintName = "Crop"
ENT.Category = "HL2 RP"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "FarmBox")
end
