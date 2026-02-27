local PLUGIN = PLUGIN

PLUGIN.name = "Overwatch Shove"
PLUGIN.author = "Riggs Mackay"
PLUGIN.description = "A Command which gives the Overwatch the ability to knock players out with the /shove command."

ix.lang.AddTable("english", {
    shoveDesc = "Knock someone out.",
    shoveNotOTA = "You need to be a Overwatch Soldier to run this command.",
    shoveNoTarget = "You must be looking at someone!",
    shoveTooFar = "You need to be close to your target!",
})

ix.lang.AddTable("korean", {
    shoveDesc = "상대방을 밀쳐 기절시킵니다.",
    shoveNotOTA = "이 명령어를 사용하려면 감시 부대여야 합니다.",
    shoveNoTarget = "누군가를 바라보고 있어야 합니다!",
    shoveTooFar = "대상에게 더 가까이 다가가야 합니다!",
})

ix.config.Add("shoveTime", 20, "How long should a character be unconscious after being knocked out?", nil, {
    data = {min = 5, max = 60},
})

ix.command.Add("shove", {
    description = "@shoveDesc",
    OnRun = function(self, ply)
        if not ( ply:Team() == FACTION_OTA ) then
            return false, "@shoveNotOTA"
        end

        local ent = ply:GetEyeTraceNoCursor().Entity
        local target

        if ( ent:IsPlayer() ) then 
            target = ent
        else
            return false, "@shoveNoTarget"     
        end

        if ( target ) and ( target:GetPos():Distance(ply:GetPos()) >= 50 ) then
            return false, "@shoveTooFar"
        end 

        ply:ForceSequence("melee_gunhit")
        timer.Simple(0.3, function()
            target:SetVelocity(ply:GetAimVector() * 300)
        end)
        timer.Simple(0.4, function()
            ply:EmitSound("physics/body/body_medium_impact_hard6.wav")
            target:SetRagdolled(true, ix.config.Get("shoveTime", 20))
        end)
    end,
})
