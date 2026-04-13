ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Combine Barricade"
ENT.Author = "Frosty"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "BarricadeID")
	self:NetworkVar("Int", 0, "OwnerCID")
	self:NetworkVar("String", 1, "OwnerName")
end
