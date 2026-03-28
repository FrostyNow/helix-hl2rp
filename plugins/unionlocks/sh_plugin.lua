
local PLUGIN = PLUGIN
-- credits to neb.cloud dev team, not taking credit for most of this code.
PLUGIN.name = "Union Locks"
PLUGIN.author = "Nforce | Modified by Frosty"
PLUGIN.description = "Adds locks for civil workers."

ix.util.Include("sv_hooks.lua")

ix.lang.AddTable("english", {
	unionLockDesc = "A metal apparatus applied to doors."
})

ix.lang.AddTable("korean", {
	["Union Lock"] = "조합 잠금장치",
	unionLockDesc = "문짝에 부착하는 금속 장치입니다.",
})

if SERVER then
    function PLUGIN:SaveUnionLocks()
        local data = {}
    
        for _, v in ipairs(ents.FindByClass("ix_unionlock")) do
            if (IsValid(v.door)) then
                data[#data + 1] = {
                    v.door:MapCreationID(),
                    v.door:WorldToLocal(v:GetPos()),
                    v.door:WorldToLocalAngles(v:GetAngles()),
                    v:GetLocked(),
                    v.ixOldBodygroup,
                    v.ixOldPartnerBodygroup
                }
            end
        end
    
        ix.data.Set("unionLocks", data)
    end

    function PLUGIN:LoadUnionLocks()
        for _, v in ipairs(ix.data.Get("unionLocks") or {}) do
            local door = ents.GetMapCreatedEntity(v[1])
    
            if (IsValid(door) and door:IsDoor()) then
                local lock = ents.Create("ix_unionlock")
    
                lock:SetPos(door:GetPos())
                lock:Spawn()
                lock.ixOldBodygroup = v[5]
                lock.ixOldPartnerBodygroup = v[6]
                lock:SetDoor(door, door:LocalToWorld(v[2]), door:LocalToWorldAngles(v[3]))
                lock:SetLocked(v[4])
            end
        end
    end
end
