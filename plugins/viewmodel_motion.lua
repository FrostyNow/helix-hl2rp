--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PLUGIN = PLUGIN

PLUGIN.name = "Viewmodel Motion"
PLUGIN.author = "kek, Revlis, Riggs | Modified by Frosty"
PLUGIN.description = "Adds a small muzzle-driven camera sway effect to the player's viewmodel, along with viewmodel inertia."

ix.lang.AddTable("english", {
	optMuzzlecamScale = "Muzzlecam Intensity",
	optdMuzzlecamScale = "The intensity of the muzzlecam effect.",
})
ix.lang.AddTable("korean", {
	optMuzzlecamScale = "카메라 흔들림 강도",
	optdMuzzlecamScale = "카메라 흔들림 효과의 강도를 설정합니다.",
})

ix.option.Add("muzzlecamScale", ix.type.number, 1, {
	category = "appearance",
	min = 0,
	max = 5,
	decimals = 1
})

local weapon_exclusion_list = {
    ["gmod_tool"] = true,
    ["weapon_physcannon"] = true,
    ["weapon_physgun"] = true,
}

local weapon_prefix_exclusion_list = {
    "arc9_",
    "mg_",
    "tacrp_",
}

local excluded_acts = {
    [ACT_VM_HOLSTER] = true,
}

local lastMuzzleAng = Angle(0, 0, 0)
local muzzleVel = Angle(0, 0, 0)
local viewOffset = Angle(0, 0, 0)

function PLUGIN:CalcView(client, origin, angles, fov)
    if (!IsValid(client) or !client:Alive() or client:InVehicle() or client:ShouldDrawLocalPlayer()) then return end

    local wep = client:GetActiveWeapon()
    if (!IsValid(wep)) then return end

    local wepClass = wep:GetClass()
    if (weapon_exclusion_list[wepClass]) then return end

    for _, prefix in ipairs(weapon_prefix_exclusion_list) do
        if (string.StartWith(wepClass, prefix)) then
            return
        end
    end

    local vm = client:GetViewModel()
    if (!IsValid(vm)) then return end

    local seq = vm:GetSequence()
    local act = vm:GetSequenceActivity(seq)
    if (excluded_acts[act]) then return end

    local attID
    for k, v in pairs(vm:GetAttachments()) do
        if (v.name:lower():find("muzzle")) then
            attID = v.ID
            break
        end
    end

    if (!attID or attID <= 0) then return end

    local att = vm:GetAttachment(attID)
    if (!att or !att.Ang) then return end

    local scale = ix.option.Get("muzzlecamScale", 1)
    if (scale <= 0) then return end

    local muzzleAng = vm:WorldToLocalAngles(att.Ang)
    local ft = FrameTime()
    local delta = lastMuzzleAng - muzzleAng
    delta:Normalize()

    muzzleVel = muzzleVel + delta * 2 * scale

    muzzleVel.p = Lerp(math.Clamp(ft * 20, 0, 1), muzzleVel.p, -viewOffset.p * 2)
    muzzleVel.p = math.Clamp(muzzleVel.p, -scale * 5, scale * 5)

    muzzleVel.y = Lerp(math.Clamp(ft * 20, 0, 1), muzzleVel.y, -viewOffset.y * 2)
    muzzleVel.y = math.Clamp(muzzleVel.y, -scale * 5, scale * 5)

    muzzleVel.r = Lerp(math.Clamp(ft * 20, 0, 1), muzzleVel.r, -viewOffset.r * 2)
    muzzleVel.r = math.Clamp(muzzleVel.r, -scale * 5, scale * 5)

    viewOffset.p = math.Clamp(viewOffset.p + muzzleVel.p * ft, -90, 90)
    viewOffset.y = math.Clamp(viewOffset.y + muzzleVel.y * ft, -90, 90)
    viewOffset.r = math.Clamp(viewOffset.r + muzzleVel.r * ft, -90, 90)

    viewOffset.p = Lerp(math.Clamp(ft * math.abs(viewOffset.p) * 16, 0, 1), viewOffset.p, 0)
    viewOffset.y = Lerp(math.Clamp(ft * math.abs(viewOffset.y) * 16, 0, 1), viewOffset.y, 0)
    viewOffset.r = Lerp(math.Clamp(ft * math.abs(viewOffset.r) * 16, 0, 1), viewOffset.r, 0)

    lastMuzzleAng = muzzleAng

    angles:Add(viewOffset)
end
