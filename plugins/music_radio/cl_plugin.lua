local PLUGIN = PLUGIN
PLUGIN.nextCheck = 0
PLUGIN.activeRadios = PLUGIN.activeRadios or {}


function PLUGIN:Think()
    local time = CurTime()

    -- Avoid lag
    if ( time < self.nextCheck ) then return end
    self.nextCheck = time + 0.2

    -- Start near inactive radios
    local ents = ents.FindInSphere(LocalPlayer():GetPos(), ix.config.Get("radioDist"))

    for _, v in pairs ( ents ) do

        if ( v.isMusicRadio and v:GetNetVar("power") == true ) then
            if ( not v.started ) then
                v:StartStream()
                table.insert(self.activeRadios, v)
            end

            -- Tell the last check for the next loop
            v.lastCheck = time
        end

    end

    -- Stop far away radios
    for k, v in pairs(self.activeRadios) do

        if ( IsValid(v) and time > v.lastCheck or not v:GetNetVar("power") ) then
            v:StopStream()
            self.activeRadios[k] = nil
        end

    end
end

net.Receive("ixMusicRadioOpenUI", function()
    local entity = net.ReadEntity()
    if (IsValid(entity)) then
        vgui.Create("ixMusicRadioMenu"):SetEntity(entity)
    end
end)

local function CreateDial(parent, x, y, size, min, max, initial, label)
    local pnl = parent:Add("DPanel")
    pnl:SetPos(x, y)
    pnl:SetSize(size, size + 30)
    pnl.value = initial
    pnl.min = min
    pnl.max = max
    
    pnl.Paint = function(s, w, h)
        local c = Color(255, 255, 255, 200)
        surface.SetDrawColor(c)
        draw.NoTexture()
        local r = size / 2 - 2
        local cx, cy = w/2, size/2
        
        -- Draw outer ring
        for i = 1, 360, 5 do
            surface.DrawLine(
                cx + math.cos(math.rad(i)) * r, cy + math.sin(math.rad(i)) * r,
                cx + math.cos(math.rad(i+5)) * r, cy + math.sin(math.rad(i+5)) * r
            )
        end
        
        -- Draw value indicator line
        local range = s.max - s.min
        local pct = (s.value - s.min) / range
        local ang = math.rad(135 + (pct * 270))
        surface.DrawLine(cx, cy, cx + math.cos(ang) * (r-4), cy + math.sin(ang) * (r-4))
        
        draw.SimpleText(label, "Trebuchet18", w/2, size + 5, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        local valText = string.format("%.1f", s.value)
        if s.max == 100 then valText = math.Round(s.value) .. "%" end
        draw.SimpleText(valText, "DermaDefault", w/2, cy + r - 15, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    pnl.OnMousePressed = function(s, btn)
        s.dragging = true
        s:MouseCapture(true)
        s:UpdateFromMouse()
    end
    pnl.OnMouseReleased = function(s, btn)
        s.dragging = false
        s:MouseCapture(false)
        if (s.OnValueChanged) then s:OnValueChanged(s.value) end
    end
    pnl.UpdateFromMouse = function(s)
        local x, y = s:CursorPos()
        local cx, cy = s:GetWide()/2, size/2
        local dx, dy = x - cx, y - cy
        local ang = math.deg(math.atan2(dy, dx))
        if ang < 90 then ang = ang + 360 end
        ang = math.Clamp(ang, 135, 405)
        
        local pct = (ang - 135) / 270
        s.value = math.Round(s.min + (pct * (s.max - s.min)), 1)
        if (s.OnCursorMovedVal) then s:OnCursorMovedVal(s.value) end
    end
    pnl.OnCursorMoved = function(s, x, y)
        if (s.dragging) then
            s:UpdateFromMouse()
        end
    end
    return pnl
end

local PANEL = {}

function PANEL:Init()
    self:SetSize(800, 400)
    self:Center()
    self:MakePopup()
    self:SetTitle("")
    self:ShowCloseButton(false)

    self.closeBtn = self:Add("DButton")
    self.closeBtn:SetSize(30, 30)
    self.closeBtn:SetPos(self:GetWide() - 40, 10)
    self.closeBtn:SetText("")
    self.closeBtn:SetTextColor(color_white)
    self.closeBtn.Paint = function(s, w, h)
        surface.SetDrawColor(255, 255, 255, s:IsHovered() and 255 or 150)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        surface.DrawLine(4, 4, w - 4, h - 4)
        surface.DrawLine(w - 4, 4, 4, h - 4)
    end
    self.closeBtn.DoClick = function()
        if (IsValid(self.entity)) then
            net.Start("ixMusicRadioCloseUI")
            net.WriteEntity(self.entity)
            net.SendToServer()
        end
        self:Close()
    end

    self.powerBtn = self:Add("DButton")
    self.powerBtn:SetSize(80, 80)
    self.powerBtn:SetPos(450, 250)
    self.powerBtn:SetText("")
    self.powerBtn.Paint = function(s, w, h)
        local c = s.isOn and Color(255, 255, 255, 200) or Color(100, 100, 100, 200)
        surface.SetDrawColor(c)
        
        draw.NoTexture()
        if (s.isOn) then
            for i = 1, 360, 10 do
                local r = w / 2 - 2
                surface.DrawLine(w/2, h/2, w/2 + math.cos(math.rad(i)) * r, h/2 + math.sin(math.rad(i)) * r)
            end
        end

        for i = 1, 360, 5 do
            local r = w / 2 - 2
            surface.DrawLine(
                w/2 + math.cos(math.rad(i)) * r, h/2 + math.sin(math.rad(i)) * r,
                w/2 + math.cos(math.rad(i+5)) * r, h/2 + math.sin(math.rad(i+5)) * r
            )
        end

        draw.SimpleText("PWR", "Trebuchet18", w/2, h/2, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    self.powerBtn.DoClick = function(s)
        s.isOn = not s.isOn
        self:OnSettingChanged()
    end

    self.freqDial = CreateDial(self, 550, 100, 80, 88.0, 108.0, 88.0, "TUNING")
    self.freqDial.OnValueChanged = function(s, val)
        self:OnSettingChanged()
    end
    self.freqDial.OnCursorMovedVal = function(s, val)
        if (!s.nextNetwork or CurTime() > s.nextNetwork) then
            self:OnSettingChanged()
            s.nextNetwork = CurTime() + 0.1
        end
    end

    self.volumeDial = CreateDial(self, 650, 100, 80, 0, 100, 100, "VOLUME")
    self.volumeDial.OnValueChanged = function(s, val)
        self:OnSettingChanged()
    end
    self.volumeDial.OnCursorMovedVal = function(s, val)
        if (!s.nextNetwork or CurTime() > s.nextNetwork) then
            self:OnSettingChanged()
            s.nextNetwork = CurTime() + 0.1
        end
    end
end

function PANEL:Paint(w, h)
    ix.util.DrawBlur(self, 10)
    
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(255, 255, 255, 100)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    surface.DrawOutlinedRect(5, 5, w-10, h-10, 1)

    -- Speaker grill art
    surface.DrawOutlinedRect(30, 30, 380, 340, 1)
    surface.SetDrawColor(255, 255, 255, 50)
    for i = 1, 35 do
        surface.DrawLine(40, 30 + i * 9, 399, 30 + i * 9)
    end
    
    -- Screen display box
    surface.SetDrawColor(255, 255, 255, 100)
    surface.DrawOutlinedRect(450, 30, 300, 40, 1)

    if (IsValid(self.entity)) then
        local displayFreq = string.format("FREQ: %.1f FM", self.freqDial.value or 88.0)
        draw.SimpleText(self.powerBtn.isOn and displayFreq or "OFF", "DermaLarge", 460, 35, Color(255, 255, 255, 200))
    end
end

function PANEL:SetEntity(entity)
    self.entity = entity
    self.powerBtn.isOn = entity:GetNetVar("power", false)
    self.freqDial.value = entity:GetNetVar("channel", 88.0)
    self.volumeDial.value = entity:GetNetVar("volume", 100)
end

function PANEL:OnSettingChanged()
    if (not IsValid(self.entity)) then return end

    local power = self.powerBtn.isOn
    local channel = self.freqDial.value
    local volume = math.Round(self.volumeDial.value)

    net.Start("ixMusicRadioUpdate")
    net.WriteEntity(self.entity)
    net.WriteBool(power)
    net.WriteFloat(channel)
    net.WriteUInt(volume, 8)
    net.SendToServer()
end

vgui.Register("ixMusicRadioMenu", PANEL, "DFrame")