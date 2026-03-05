LockpickingPlugin = LockpickingPlugin or PLUGIN

PLUGIN.name = "Lockpicking"
PLUGIN.author = "Abel Witz"
PLUGIN.desc = "Allows to pick locks with bobby pins"

ix.config.Add("lockpickUnlockSize", 1, "", nil, {
    data = {min = 1, max = 180},
    category = "Lockpicking"
})

ix.config.Add("lockpickWeakSize", 20, "", nil, {
    data = {min = 1, max = 180},
    category = "Lockpicking"
})

ix.config.Add("lockpickUnlockMaxAngle", -90, "", nil, {
    data = {min = -180, max = -1},
    category = "Lockpicking"
})

ix.config.Add("lockpickHardMaxAngle", -30, "", nil, {
    data = {min = -180, max = -1},
    category = "Lockpicking"
})

ix.config.Add("lockpickTurningSpeed", 90, "", nil, {
    data = {min = 10, max = 500},
    category = "Lockpicking"
})

ix.config.Add("lockpickReleasingSpeed", 200, "", nil, {
    data = {min = 10, max = 1000},
    category = "Lockpicking"
})

ix.config.Add("lockpickSpamTime", 0.1, "", nil, {
    data = {min = 0, max = 2, decimals = 2},
    category = "Lockpicking"
})

ix.config.Add("lockpickMaxLookDistance", 50, "", nil, {
    data = {min = 10, max = 500},
    category = "Lockpicking"
})

ix.config.Add("lockpickFadeTime", 4, "", nil, {
    data = {min = 0, max = 30, decimals = 1},
    category = "Lockpicking"
})


-- Lockpick stop messages
PLUGIN.StopAfk = 1
PLUGIN.StopTooFar = 2

PLUGIN.Messages = {
	"lockpickingAfk",
	"lockpickingTooFar"
}

function PLUGIN:GetEntityLookedAt(player, maxDistance)
    local data = {}
    data.filter = player
    data.start = player:GetShootPos()
    data.endpos = data.start + player:GetAimVector()*maxDistance

    return util.TraceLine(data).Entity
end

ix.util.Include("sv_sessions.lua")
ix.util.Include("cl_session.lua")

ix.util.Include("ui/cl_interface.lua")
ix.util.Include("ui/cl_button.lua")
ix.util.Include("ui/cl_label.lua")