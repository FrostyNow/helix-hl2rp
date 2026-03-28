AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Union Lock Manual"
ENT.Category = "HL2 RP"
ENT.Spawnable = true
ENT.AdminOnly = true

if (SERVER) then
	function ENT:SpawnFunction(client, trace)
		if (!trace.Hit) then return end

		local angles = trace.HitNormal:Angle()
		
		-- Adjusting angles to match how the original lock sits on surfaces
		angles:RotateAroundAxis(angles:Up(), 90)
		angles:RotateAroundAxis(angles:Forward(), 180)
		angles:RotateAroundAxis(angles:Right(), 180)

		-- Spawn the original union lock entity
		local entity = ents.Create("ix_unionlock")
		
		-- Use the hit normal to slightly offset the lock so it is not clipped into the wall
		-- We use the same forward offset (7.2) as the original GetLockPosition function
		local position = trace.HitPos + trace.HitNormal * 7.2 + Vector(2, 0, 10)

		entity:SetPos(position)
		entity:SetAngles(angles)
		entity:Spawn()
		entity:Activate()

		-- If the target is a door, we still try to attach it so it functions correctly
		local door = trace.Entity
		if (IsValid(door) and door:IsDoor()) then
			-- SetDoor handles parenting and door-specific variables
			entity:SetDoor(door, position, angles)
		end

		local PLUGIN = ix and ix.plugin and ix.plugin.Get("unionlocks")
		if (PLUGIN and PLUGIN.SaveUnionLocks) then
			PLUGIN:SaveUnionLocks()
		end

		return entity
	end
end
