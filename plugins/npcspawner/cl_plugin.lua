local PLUGIN = PLUGIN

ix.util.Include("derma/cl_spawner.lua")

net.Receive("ixNpcSpawnerSync", function()
    PLUGIN.spawners = net.ReadTable()
end)

net.Receive("ixNpcSpawnerEdit", function()
    local id = net.ReadString()
    local data = net.ReadTable()
    
    if (IsValid(ix.gui.npcSpawnerEdit)) then
        ix.gui.npcSpawnerEdit:Remove()
    end
    
    ix.gui.npcSpawnerEdit = vgui.Create("ixNpcSpawnerEdit")
    ix.gui.npcSpawnerEdit:SetSpawner(id, data)
end)

function PLUGIN:HUDPaint()
    if (not ix.option.Get("npcSpawnerESP", true)) then return end

    local client = LocalPlayer()
    if (not client:IsSuperAdmin()) then return end
    if (client:GetMoveType() ~= MOVETYPE_NOCLIP) then return end

    for id, spawner in pairs(self.spawners or {}) do
        local pos = spawner.pos:ToScreen()
        local dist = client:GetPos():Distance(spawner.pos)
        
        if (pos.visible) then
            if (dist < 500) then
                draw.SimpleTextOutlined(L("npcSpawnerESPPrefix", id), "BudgetLabel", pos.x, pos.y, Color(255, 100, 100, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0, 150))
                
                local delayText = L("npcSpawnerESPInfo", spawner.spawnDelay or 0, spawner.maxSpawned or 0, spawner.maxNearby or 0)
                draw.SimpleTextOutlined(delayText, "BudgetLabel", pos.x, pos.y + 15, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 150))
                
                local classLines = {L("npcSpawnerESPClasses") .. ":"}
                local count = 0
                for class, weight in pairs(spawner.classes or {}) do
                    table.insert(classLines, class .. " (" .. L("spawnerColumnWeight") .. " " .. weight .. ")")
                    count = count + 1
                end
                
                if count == 0 then 
                    table.insert(classLines, L("npcSpawnerESPNone"))
                end
                
                for i, line in ipairs(classLines) do
                    draw.SimpleTextOutlined(line, "BudgetLabel", pos.x, pos.y + 15 + (i * 15), Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 150))
                end
            else
                draw.SimpleTextOutlined(L("npcSpawnerESPPrefix", id), "BudgetLabel", pos.x, pos.y, Color(255, 100, 100, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 100))
            end
        end
    end
end
