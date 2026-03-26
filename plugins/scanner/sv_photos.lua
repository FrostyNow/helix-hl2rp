local PLUGIN = PLUGIN

util.AddNetworkString("ixScannerData")
util.AddNetworkString("ixScannerPicture")
util.AddNetworkString("ixSurveillancePhotoRequest")

PLUGIN.photoHistory = PLUGIN.photoHistory or {}

net.Receive("ixScannerData", function(length, ply)
    local isSurveillance = net.ReadBool()
    local length = net.ReadUInt(16)
    local data = net.ReadData(length)

    local canCapture = false
    if (isSurveillance) then
        -- We trust the client if we're doing surveillance, 
        -- but we could add a check if they were actually requested.
        canCapture = true
    elseif (IsValid(ply.ixScn) and ply:GetViewEntity() == ply.ixScn and (ply.ixNextPic or 0) < CurTime()) then
        local delay = 15
        ply.ixNextPic = CurTime() + delay - 1
        canCapture = true
    end

    if (canCapture) then
        if (length != #data) then
            return
        end

        local receivers = {}

        for k, v in ipairs(player.GetAll()) do
            if (Schema and Schema.CanPlayerSeeCombineOverlay and Schema:CanPlayerSeeCombineOverlay(v)) then
                receivers[#receivers + 1] = v
            end
        end

        if (#receivers > 0) then
            net.Start("ixScannerData")
                net.WriteBool(isSurveillance) 
                net.WriteUInt(#data, 16)
                net.WriteData(data, #data)
            net.Send(receivers)
        end

        -- Store in history for Combine Computer
        table.insert(PLUGIN.photoHistory, 1, {
            data = data,
            isSurveillance = isSurveillance,
            time = os.time()
        })

        if (#PLUGIN.photoHistory > 12) then
            table.remove(PLUGIN.photoHistory)
        end
    end
end)

net.Receive("ixScannerPicture", function(length, ply)
    if (not IsValid(ply.ixScn)) then return end
    if (ply:GetViewEntity() ~= ply.ixScn) then return end
    if ((ply.ixNextFlash or 0) >= CurTime()) then return end

    ply.ixNextFlash = CurTime() + 1
    ply.ixScn:flash()

    for k, v in pairs(ents.FindInSphere(ply.ixScn:GetPos(), 128)) do
        if v:IsPlayer() then
            if not (v:SteamID64() == ply:SteamID64()) then
                v:ScreenFade(1, Color(255, 255, 255), 5, 2)
                v:SetDSP(31)
                timer.Simple(4, function() v:SetDSP(1) end)
            end
        end
    end
end)