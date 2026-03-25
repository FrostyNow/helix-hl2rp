ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Furniture"
ENT.Category = "Helix"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "FurnitureID")
	self:NetworkVar("String", 1, "OwnerName")
	self:NetworkVar("Int", 0, "OwnerCID")
end
