-- by steamId

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

util.AddNetworkString("ix_book_open_ui")
util.AddNetworkString("ix_book_finish")

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

	return entity
end

function ENT:Initialize()
	self.Entity:SetModel("models/props_wasteland/controlroom_desk001b.mdl")
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetUseType( SIMPLE_USE )
	local size = 1.0
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
	
    if (client:GetNetVar("can_action", false)) then return end

    client:SetAction("Clean up before work...", 3) 

	client:DoStaredAction(self, function()
        
		net.Start("ix_book_open_ui")
        	net.WriteTable(allAttributes)
		net.Send(client)
        
        client:Notify("Ready Writing Book.") end, 3, function()
        
		client:SetAction(false)
		
		client:Notify("Canceld Wrting Book.")
    end)
	
end
