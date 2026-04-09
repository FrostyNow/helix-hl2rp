ENT.Type = "anim"
ENT.Base = "ix_scanner"
ENT.PrintName = "Shield Scanner"
ENT.Category = "HL2 RP"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SpawnFunction(ply, trace, className)
	local entity = ents.Create(className)
	entity:SetPos(trace.HitPos + Vector(0, 0, 32))
	entity:Spawn()
	entity:Activate()

	return entity
end
