PLUGIN.name = "Any timers"
PLUGIN.author = "Junk | Heavily modified by Frosty"
PLUGIN.description = ""

ix.lang.AddTable("english", {
	cmdTimerCreate = "Creates a countdown timer with custom text.",
	cmdTimerRemove = "Stops and removes the currently running timer.",
	cmdTimerPause = "Pauses or resumes the currently running timer.",
})
ix.lang.AddTable("korean", {
	cmdTimerCreate = "사용자 지정 문구와 함께 카운트다운 타이머를 생성합니다.",
	cmdTimerRemove = "현재 진행 중인 타이머를 중지하고 제거합니다.",
	cmdTimerPause = "현재 진행 중인 타이머를 일시정지하거나 다시 재개합니다.",
})

if SERVER then
    function PLUGIN:RemoveTimer()
        SetGlobalString("anyTimerText", "")
        SetGlobalFloat("anyTimerEnd", 0)
        SetGlobalBool("anyTimerPaused", false)
        SetGlobalFloat("anyTimerRemaining", 0)
        
        if timer.Exists("anyTimerFinish") then
            timer.Remove("anyTimerFinish")
        end
    end

    function PLUGIN:CreateTimer(text, time)
        self:RemoveTimer()
        
        SetGlobalString("anyTimerText", text)
        SetGlobalFloat("anyTimerEnd", CurTime() + time)
        SetGlobalBool("anyTimerPaused", false)
        SetGlobalFloat("anyTimerRemaining", time)
        
        timer.Create("anyTimerFinish", time, 1, function()
            self:RemoveTimer()
        end)
    end
    
    function PLUGIN:PauseTimer()
        if GetGlobalString("anyTimerText", "") == "" then return end
        
        local isPaused = GetGlobalBool("anyTimerPaused", false)
        if isPaused then
            SetGlobalBool("anyTimerPaused", false)
            local remaining = GetGlobalFloat("anyTimerRemaining", 0)
            SetGlobalFloat("anyTimerEnd", CurTime() + remaining)
            
            timer.Create("anyTimerFinish", remaining, 1, function()
                self:RemoveTimer()
            end)
        else
            SetGlobalBool("anyTimerPaused", true)
            local remaining = math.max(0, GetGlobalFloat("anyTimerEnd", 0) - CurTime())
            SetGlobalFloat("anyTimerRemaining", remaining)
            
            if timer.Exists("anyTimerFinish") then
                timer.Remove("anyTimerFinish")
            end
        end
    end
end

if CLIENT then
    local function getFomatted(time)
        local m, s
        m = math.floor(time / 60) % 60
        s = math.floor(time) % 60

        return string.format('%02i:%02i', m, s)
    end

    function PLUGIN:HUDPaint()
        local text = GetGlobalString("anyTimerText", "")
        if text == "" then return end

        local isPaused = GetGlobalBool("anyTimerPaused", false)
        local remaining = 0

        if isPaused then
            remaining = GetGlobalFloat("anyTimerRemaining", 0)
        else
            remaining = GetGlobalFloat("anyTimerEnd", 0) - CurTime()
        end

        remaining = math.max(0, remaining)

        if not isPaused and remaining <= 5 and remaining > 0 then
            local sec = math.ceil(remaining)
            if self.LastTimerBeep ~= sec then
                self.LastTimerBeep = sec
                LocalPlayer():EmitSound("ui/buttonrollover.wav", 100, 200)
            end
        end

        ix.util.DrawText(text .. " " .. getFomatted(remaining), ScrW()/2, ScrH()*0.98, color_white, 1, 1, "ixBigFont")
    end
end

ix.command.Add("timerCreate", {
    description = "@cmdTimerCreate",
    adminOnly = true,
    arguments = {
        ix.type.string,
        ix.type.number
    },
    OnRun = function(self, client, text, time)
        local plugin = ix.plugin.list["anytimers"]
        if plugin then plugin:CreateTimer(text, time) end

        for _, v in ipairs(player.GetAll()) do
            v:EmitSound("buttons/combine_button3.wav")
        end
    end
})

ix.command.Add("timerRemove", {
    description = "@cmdTimerRemove",
    adminOnly = true,
    OnRun = function(self, client)
        local plugin = ix.plugin.list["anytimers"]
        if plugin then plugin:RemoveTimer() end
    end
})

ix.command.Add("timerPause", {
    description = "@cmdTimerPause",
    adminOnly = true,
    OnRun = function(self, client)
        local plugin = ix.plugin.list["anytimers"]
        if plugin then plugin:PauseTimer() end
    end
})