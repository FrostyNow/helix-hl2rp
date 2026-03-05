local PLUGIN = PLUGIN

local PANEL = {}
local ScrW, ScrH = ScrW(), ScrH()
function PANEL:Init()
    if ix.gui.cinematicSplashText then
        ix.gui.cinematicSplashText:Remove()
    end

    ix.gui.cinematicSplashText = self
    self.data = {}

    self:SetSize(ScrW, ScrH)
    self.barSize  = ScrH*(ix.config.Get("cinematicBarSize", 0.18))
end

function PANEL:OnRemove()
    if (self.music) then
        self.music:Stop()
        self.music = nil
    end
end

function PANEL:Paint()
end

function PANEL:DrawBlackBars()
    self.topBar = self:Add("DPanel")
    self.topBar:SetSize(ScrW, self.barSize + 10) -- +10 in to make sure it covers the top
    self.topBar:SetPos(0, -self.barSize) -- set it to be outside of the screen
    self.topBar.Paint = function(this, w, h)
        surface.SetDrawColor(0,0,0, 255)
        surface.DrawRect(0, 0, w, h)
    end

    self.bottomBar = self:Add("DPanel")
    self.bottomBar:SetSize(ScrW, self.barSize + 10)  -- +10 in to make sure it covers the bottom
    self.bottomBar:SetPos(0, ScrH) -- set it to be outside of the screen
    self.bottomBar.Paint = function(this, w, h)
        surface.SetDrawColor(0,0,0, 255)
        surface.DrawRect(0, 0, w, h)
    end
end

function PANEL:TriggerBlackBars()
    if not (IsValid(self.topBar) and IsValid(self.bottomBar)) then return end -- dont do anything if the bars dont exist

    self.topBar:MoveTo(0, 0, 2, 0, 0.5)
    self.bottomBar:MoveTo(0, ScrH - self.barSize, 2, 0, 0.5, function() self:TriggerText() end)
end

function PANEL:TriggerText()
    local textPanel = self:Add("DPanel")
    textPanel.Paint = function() end
    local panelWide, panelTall = 300, 300
    textPanel:SetSize(panelWide, panelTall)

    local data = self.data

    if data.text and data.text ~= "" then
        textPanel.text = textPanel:Add("DLabel")
        textPanel.text:SetFont("cinematicSplashFont")
        textPanel.text:SetTextColor(data.color or color_white)
        textPanel.text:SetText(data.text)
        textPanel.text:SetAutoStretchVertical(true)
        textPanel.text:Dock(TOP)
        textPanel.text:SetAlpha(0)
        textPanel.text:AlphaTo(255, 2, 0, function()
            if not data.bigText then self:TriggerCountdown() end
        end)

        surface.SetFont("cinematicSplashFont")
        textPanel.text.textWide, textPanel.text.textTall = surface.GetTextSize(data.text)
        panelWide = panelWide > textPanel.text.textWide and panelWide or textPanel.text.textWide
        panelTall = panelTall + textPanel.text.textTall
        textPanel:SetSize(panelWide, panelTall)
    end

    if data.bigText and data.bigText ~= "" then
        textPanel.bigText = textPanel:Add("DLabel")
        textPanel.bigText:SetFont("cinematicSplashFontBig")
        textPanel.bigText:SetTextColor(data.color or color_white)
        textPanel.bigText:SetText(data.bigText)
        textPanel.bigText:SetAutoStretchVertical(true)
        textPanel.bigText:Dock(TOP)
        textPanel.bigText:SetAlpha(0)
        textPanel.bigText:AlphaTo(255, 2, 1, function()
            self:TriggerCountdown()
        end)

        surface.SetFont("cinematicSplashFontBig")
        textPanel.bigText.textWide, textPanel.bigText.textTall = surface.GetTextSize(data.bigText)
        panelWide = panelWide > textPanel.bigText.textWide and panelWide or textPanel.bigText.textWide
        panelTall = panelTall + textPanel.bigText.textTall
        textPanel:SetSize(panelWide, panelTall)
    end

    if textPanel.text then textPanel.text:DockMargin((panelWide/2) - (textPanel.text.textWide/2), 0, 0, 20) end
    if textPanel.bigText then textPanel.bigText:DockMargin((panelWide/2) - (textPanel.bigText.textWide/2), 0, 0, 20) end
    textPanel:InvalidateLayout(true)

    textPanel:SetPos(ScrW - textPanel:GetWide() - ScrW*0.05, ScrH*0.58)

    if data.music and data.music ~= "" then
        self.music = CreateSound(LocalPlayer(), data.music)
        self.music:PlayEx(0, 100)
        self.music:ChangeVolume(1, 2)
    end
end

function PANEL:TriggerCountdown()
    local duration = self.data.duration or 6

    self:AlphaTo(0, 4, duration, function()
        self:Remove()
    end)
    timer.Simple(duration, function()
        if IsValid(self) and self.music then self.music:FadeOut(4) end
    end)
end

vgui.Register("cinematicSplashText", PANEL, "DPanel")

net.Receive("triggerCinematicSplashMenu", function()
    local text = net.ReadString()
    local bigText = net.ReadString()
    local duration = net.ReadUInt(6)
    local blackbars = net.ReadBool()
    local music = net.ReadString()
    local color = net.ReadColor()

    local splashText = vgui.Create("cinematicSplashText")
    splashText.data = {
        text = text ~= "" and text or nil,
        bigText = bigText ~= "" and bigText or nil,
        duration = duration,
        music = music,
        color = color
    }

    if blackbars then
        splashText:DrawBlackBars()
        splashText:TriggerBlackBars()
    else
        splashText:TriggerText()
    end
end)