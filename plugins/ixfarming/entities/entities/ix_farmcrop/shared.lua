ENT.Type = "anim"
ENT.PrintName = "Crop"
ENT.Category = "Helix Farming"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "FarmBox")
end
