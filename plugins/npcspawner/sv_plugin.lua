local PLUGIN = PLUGIN

util.AddNetworkString("ixNpcSpawnerEdit")
util.AddNetworkString("ixNpcSpawnerSync")

function PLUGIN:AddSpawner(id, pos, template)
    if template then
        self.spawners[id] = {
            pos = pos,
            classes = table.Copy(template.classes or {}),
            maxSpawned = template.maxSpawned,
            maxNearby = template.maxNearby,
            spawnDelay = template.spawnDelay,
            minDistance = template.minDistance,
            lastSpawn = 0,
            spawnedNPCs = {}
        }
    else
        self.spawners[id] = {
            pos = pos,
            classes = {}, 
            maxSpawned = 5,
            maxNearby = 10,
            spawnDelay = 60,
            minDistance = 1000, 
            lastSpawn = 0,
            spawnedNPCs = {}
        }
    end

    self:SaveSpawners()
    self:SyncSpawners()
end

function PLUGIN:RemoveSpawner(id)
    self.spawners[id] = nil
    self:SaveSpawners()
    self:SyncSpawners()
end

function PLUGIN:SaveSpawners()
    local data = {}
    for id, spawner in pairs(self.spawners) do
        data[id] = {
            pos = spawner.pos,
            classes = spawner.classes,
            maxSpawned = spawner.maxSpawned,
            maxNearby = spawner.maxNearby,
            spawnDelay = spawner.spawnDelay,
            minDistance = spawner.minDistance
        }
    end
    self:SetData(data)
end

function PLUGIN:LoadData()
    local data = self:GetData() or {}
    for id, spawner in pairs(data) do
        self.spawners[id] = {
            pos = spawner.pos,
            classes = spawner.classes or {},
            maxSpawned = spawner.maxSpawned or 5,
            maxNearby = spawner.maxNearby or 10,
            spawnDelay = spawner.spawnDelay or 60,
            minDistance = spawner.minDistance or 1000,
            lastSpawn = 0,
            spawnedNPCs = {}
        }
    end
end

function PLUGIN:SyncSpawners(client)
    local data = {}
    for id, spawner in pairs(self.spawners) do
        data[id] = {
            pos = spawner.pos,
            classes = spawner.classes,
            maxSpawned = spawner.maxSpawned,
            maxNearby = spawner.maxNearby,
            spawnDelay = spawner.spawnDelay,
            minDistance = spawner.minDistance
        }
    end

    net.Start("ixNpcSpawnerSync")
    net.WriteTable(data)
    if (client) then
        net.Send(client)
    else
        net.Broadcast()
    end
end

function PLUGIN:PlayerInitialSpawn(client)
    self:SyncSpawners(client)
end

net.Receive("ixNpcSpawnerEdit", function(len, client)
    if (not client:IsSuperAdmin()) then return end

    local id = net.ReadString()
    local data = net.ReadTable()

    if (PLUGIN.spawners[id]) then
        PLUGIN.spawners[id].classes = data.classes
        PLUGIN.spawners[id].maxSpawned = data.maxSpawned
        PLUGIN.spawners[id].maxNearby = data.maxNearby
        PLUGIN.spawners[id].spawnDelay = data.spawnDelay
        PLUGIN.spawners[id].minDistance = data.minDistance
        
        PLUGIN:SaveSpawners()
        PLUGIN:SyncSpawners()
        client:NotifyLocalized("spawnerEditedMsg")
    end
end)

function PLUGIN:GetGlobalNPCCount()
    local count = 0
    for _, ent in ipairs(ents.FindByClass("npc_*")) do
        if (ent:IsNPC() and not ent.ixIgnoreSpawner) then
            count = count + 1
        end
    end
    return count
end

function PLUGIN:GetNearbyNPCCount(pos, radius)
    local count = 0
    for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
        if (ent:IsNPC() and not ent.ixIgnoreSpawner) then
            count = count + 1
        end
    end
    return count
end

function PLUGIN:IsPlayerLookingOrNear(pos, minDistance)
    for _, ply in ipairs(player.GetAll()) do
        if (not ply:Alive() or ply:GetMoveType() == MOVETYPE_NOCLIP) then continue end
        
        local dist = ply:GetPos():Distance(pos)
        if (dist < minDistance) then
            return true
        end
        
        local tr = util.TraceLine({
            start = ply:EyePos(),
            endpos = pos,
            filter = ply
        })
        
        if (not tr.HitWorld) then 
            local aimVec = ply:GetAimVector()
            local dirToPos = (pos - ply:EyePos()):GetNormalized()
            local dot = aimVec:Dot(dirToPos)
            if (dot > 0.7) then
                return true
            end
        end
    end
    return false
end

function PLUGIN:SelectRandomClass(classes)
    local totalWeight = 0
    for _, weight in pairs(classes) do
        totalWeight = totalWeight + tonumber(weight)
    end
    
    if totalWeight <= 0 then return nil end
    
    local r = math.random() * totalWeight
    local current = 0
    for class, weight in pairs(classes) do
        current = current + tonumber(weight)
        if r <= current then
            return class
        end
    end
end

function PLUGIN:FindValidSpawnPos(pos, class)
    if (class == "npc_barnacle") then
        local upTr = util.TraceLine({
            start = pos,
            endpos = pos + Vector(0, 0, 500),
            mask = MASK_SOLID_BRUSHONLY
        })
        
        if upTr.Hit then
            return upTr.HitPos - Vector(0, 0, 5)
        end
        return nil
    end

    local function IsEmpty(checkPos)
        local tr = util.TraceHull({
            start = checkPos + Vector(0, 0, 5),
            endpos = checkPos + Vector(0, 0, 5),
            mins = Vector(-16, -16, 0),
            maxs = Vector(16, 16, 72),
            mask = MASK_NPCSOLID
        })
        return not tr.Hit
    end

    if IsEmpty(pos) then return pos end

    for i = 1, 15 do
        local rad = math.rad(math.random(0, 360))
        local dist = math.random(40, 150)
        local offset = pos + Vector(math.cos(rad) * dist, math.sin(rad) * dist, 10)
        
        if IsEmpty(offset) then
            local dropTr = util.TraceLine({
                start = offset,
                endpos = offset - Vector(0, 0, 200),
                mask = MASK_SOLID_BRUSHONLY
            })
            
            if dropTr.Hit then
                local finalPos = dropTr.HitPos
                if IsEmpty(finalPos) then
                    return finalPos
                end
            end
        end
    end
    
    return nil
end

function PLUGIN:Think()
    if ((self.nextSpawnCheck or 0) > CurTime()) then return end
    self.nextSpawnCheck = CurTime() + 2

    local globalLimit = ix.config.Get("npcSpawnerGlobalLimit", 50)
    local globalCount = self:GetGlobalNPCCount()
    
    if (globalCount >= globalLimit) then return end

    for id, spawner in pairs(self.spawners) do
        if ((spawner.lastSpawn + spawner.spawnDelay) > CurTime()) then continue end
        
        local activeNPCs = 0
        local newSpawned = {}
        for _, ent in ipairs(spawner.spawnedNPCs) do
            if (IsValid(ent) and ent:IsNPC() and ent:Health() > 0) then
                activeNPCs = activeNPCs + 1
                table.insert(newSpawned, ent)
            end
        end
        spawner.spawnedNPCs = newSpawned

        if (activeNPCs >= spawner.maxSpawned) then continue end
        
        local nearbyCount = self:GetNearbyNPCCount(spawner.pos, 1000)
        if (nearbyCount >= spawner.maxNearby) then continue end
        
        if (self:IsPlayerLookingOrNear(spawner.pos, spawner.minDistance)) then continue end
        
        local class = self:SelectRandomClass(spawner.classes)
        if (not class) then continue end
        
        local spawnPos = self:FindValidSpawnPos(spawner.pos, class)
        if (not spawnPos) then continue end

        local ent = ents.Create(class)
        if (IsValid(ent)) then
            ent:SetPos(spawnPos)
            ent:Spawn()
            ent:Activate()
            
            table.insert(spawner.spawnedNPCs, ent)
            spawner.lastSpawn = CurTime()
            
            globalCount = globalCount + 1
            if (globalCount >= globalLimit) then
                break
            end
        end
    end
end
