local PLUGIN = PLUGIN

util.AddNetworkString("openCinematicSplashMenu")
util.AddNetworkString("triggerCinematicSplashMenu")

net.Receive("triggerCinematicSplashMenu", function(_, client)
    if not client:IsAdmin() then return end

    local text = net.ReadString()
    local bigText = net.ReadString()
    local duration = net.ReadUInt(6)
    local blackBars = net.ReadBool()
    local music = net.ReadString()
    local color = net.ReadColor()

    net.Start("triggerCinematicSplashMenu")
        net.WriteString(text)
        net.WriteString(bigText)
        net.WriteUInt(duration, 6)
        net.WriteBool(blackBars)
        net.WriteString(music)
        net.WriteColor(color)
    net.Broadcast()
end)

function PLUGIN:OnCharacterLoaded(character)
    local client = character:GetPlayer()

    if (ix.config.Get("cinematicTextAuto", false)) then
        local text = ix.config.Get("cinematicTextAutoLine1", "")
        local bigText = ix.config.Get("cinematicTextAutoLine2", "")
        local music = ix.config.Get("cinematicTextAutoMusic", "")

        net.Start("triggerCinematicSplashMenu")
            net.WriteString(text)
            net.WriteString(bigText)
            net.WriteUInt(6, 6) -- Default duration for auto
            net.WriteBool(true) -- Always black bars for auto? Or maybe config? I'll stick to true.
            net.WriteString(music)
            net.WriteColor(color_white)
        net.Send(client)
    end
end