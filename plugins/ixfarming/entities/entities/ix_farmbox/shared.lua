ENT.Type = "anim"
ENT.PrintName = "Farm Box"
ENT.Category = "HL2 RP"
ENT.Spawnable = true
ENT.bNoPersist = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "CropType")
	self:NetworkVar("Float", 0, "Progress")
	self:NetworkVar("Int", 0, "WaterAmount")
	self:NetworkVar("Bool", 0, "HasFertilizer")
	self:NetworkVar("Bool", 0, "HasPesticide")
	self:NetworkVar("Int", 1, "WaterQuality")
end
