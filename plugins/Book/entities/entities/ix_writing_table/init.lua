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
	
	-- Debug Test
	-- PrintTable(allAttributes)
	-- 이미 무언가 하고 있다면 중단
    if (client:GetNetVar("can_action", false)) then return end

    -- [진행 바 시작] 3초 동안 글을 쓰는 동작을 가정
    client:SetAction("작성 중...", 3) 
    client:DoStaredAction(self, function()
        -- 성공 시: UI 열기 신호 전송
        net.Start("ix_book_open_ui")
        net.Send(client)
        
        client:Notify("원고를 정리하기 시작합니다.")
    end, 3, function()
        -- 실패 시 (움직이거나 취소됨)
        client:Notify("작성이 중단되었습니다.")
    end)
	
end
