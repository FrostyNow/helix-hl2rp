-- by steamId

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:SpawnFunction(client, trace)
	local SpawnPos = trace.HitPos + trace.HitNormal * 46
	local entity = ents.Create( "ix_writing_table" )
	
	entity:SetPos( SpawnPos )

	local angles = (entity:GetPos() - client:GetPos()):Angle()
	angles.p = 0
	angles.y = 0
	angles.r = 0

	entity:SetAngles(angles)
	entity:Spawn()
	entity:Activate()

	for k, v in pairs(ents.FindInBox(entity:LocalToWorld(entity:OBBMins()), entity:LocalToWorld(entity:OBBMaxs()))) do
		if (string.find(v:GetClass(), "prop") and v:GetModel() == "models/props/slotmachine/slotmachinefinal.mdl") then
			entity:SetPos(v:GetPos())
			entity:SetAngles(v:GetAngles())
			SafeRemoveEntity(v)

			break
		end
	end

	return entity

end

function ENT:Initialize()
	self.Entity:SetModel( "models/props/slotmachine/slotmachinefinal.mdl" )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetUseType( SIMPLE_USE )
	size = 1.0
	self.Entity:SetModelScale(size,0)

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
        phys:SetMass( 1000 )
	end
end


function ENT:Use(client)

	local character = client:GetCharacter()
	local allAttributes = {}

	if (not character) then return end
	-- Get All Attribute

	if (ix.attributes and ix.attributes.list) then
		for k, v in pairs(ix.attributes.list) do
			allAttributes[k] = character:GetAttribute(k, 0)
		end
	end
	
	if (table.Count(allAttributes) == 0) then
		client:Notify("No Attribute.")
    return
end
