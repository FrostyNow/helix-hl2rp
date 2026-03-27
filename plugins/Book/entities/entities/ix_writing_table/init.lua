-- init.lua
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

util.AddNetworkString("ix_book_open_ui")
util.AddNetworkString("ix_book_finish")
util.AddNetworkString("ix_book_read_ui") 

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
    self:SetModel("models/props_wasteland/controlroom_desk001b.mdl")
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetUseType( SIMPLE_USE )
    local phys = self:GetPhysicsObject()
    if (phys:IsValid()) then
        phys:Wake()
        phys:SetMass( 1000 )
    end

    self.drafts = {} 
end

function ENT:Use(client)
    local char = client:GetCharacter()
    if (!char) then return end

    self.drafts = self.drafts or {}

	-- 모든 능력치를 받습니다.
    local allAttributes = {}
    for k, v in pairs(ix.attributes.list) do
        allAttributes[k] = char:GetAttribute(k, 0)
    end

    local charID = client:SteamID64() .. "_" .. char:GetName()
    local myDrafts = self.drafts[charID] or {} 

    net.Start("ix_book_open_ui")
        net.WriteTable(allAttributes)
        net.WriteEntity(self)
        net.WriteTable(myDrafts) 
    net.Send(client)
end

net.Receive("ix_book_finish", function(len, client)
    local title = net.ReadString()
    local content = net.ReadString()
    local attrID = net.ReadString()
    local ent = net.ReadEntity()

    local char = client:GetCharacter()
    if (!IsValid(ent) or !char) then return end
    
    ent.drafts = ent.drafts or {}
    local charID = client:SteamID64() .. "_" .. char:GetName()
    ent.drafts[charID] = ent.drafts[charID] or {}

    local totalTime = 10
    local targetIndex = nil

    for i, d in ipairs(ent.drafts[charID]) do
        if (d.attrID == attrID) then
            totalTime = d.remaining or 10
            targetIndex = i
            break
        end
    end

    local uniqueID = "ixBookCraft_" .. client:SteamID64()
    client:SetAction("책 제작중...", totalTime)
    client:SetNetVar("can_action", true)

    timer.Create(uniqueID, 1, totalTime, function()
        if (!IsValid(client) or !IsValid(ent)) then return end

        local trace = client:GetEyeTrace()
        local dist = client:GetPos():DistToSqr(ent:GetPos())
        local repsLeft = timer.RepsLeft(uniqueID)

        if (trace.Entity ~= ent or dist > 8500) then
            local newDraft = {
                title = title,
                content = content,
                attrID = attrID,
                remaining = repsLeft
            }

            if (targetIndex) then
                ent.drafts[charID][targetIndex] = newDraft
            else
                if (#ent.drafts[charID] < 5) then
                    table.insert(ent.drafts[charID], newDraft)
                else
                    client:Notify("저장 공간이 가득 찼습니다. (최대 5개)")
                end
            end

            client:SetAction(false)
            client:SetNetVar("can_action", false)
            client:Notify("진행도가 저장되었습니다. (남은 시간: " .. repsLeft .. "초)")
            timer.Remove(uniqueID)
            return
        end

        if (repsLeft == 0) then
            client:SetNetVar("can_action", false)
            
            local skillLevel = char:GetAttribute(attrID, 0)
            
            char:GetInventory():Add("testbook", 1, {
                ["name"] = title,
                ["content"] = content,
                ["attr"] = attrID,
                ["level"] = tonumber(skillLevel)
            })
            
            if (targetIndex) then
                table.remove(ent.drafts[charID], targetIndex)
            end
            
            client:Notify("'" .. title .. "' 책 제작 완료! (기록된 숙련도: " .. math.floor(skillLevel) .. ")")
        end
    end)
end)