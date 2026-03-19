
local PANEL = {}

-- [[
--  Generic HUD Locator Panel
--  Used to visually move HUD elements and save their coordinates.
-- ]]

function PANEL:Init()
	self:SetSize(140, 32)
	self:SetMouseInputEnabled(true)
	self:SetDraggable(true)
	self:SetTitle("")
	self:ShowCloseButton(false)
	self:SetScreenLock(true)
	self:SetAlpha(200)

	self.label = self:Add("DLabel")
	self.label:Dock(FILL)
	self.label:SetContentAlignment(5)
	self.label:SetFont("BudgetLabel")
	self.label:SetTextColor(color_white)
	self.label:SetAutoStretchVertical(true)
end

function PANEL:Setup(id, name, defaultX, defaultY)
	self.hudID = id
	self.label:SetText(name)
	self.defaultX = defaultX
	self.defaultY = defaultY

	-- Load saved position (fractions of screen size for resolution independence)
	local x = cookie.GetNumber("ixHUD_" .. id .. "_X", defaultX / ScrW())
	local y = cookie.GetNumber("ixHUD_" .. id .. "_Y", defaultY / ScrH())

	self:SetPos(x * ScrW(), y * ScrH())
end

function PANEL:OnMouseReleased()
	self:SetDragging(false)
	self:MouseCapture(false)
	
	-- Save normalized coordinates (0.0 - 1.0)
	local x, y = self:GetPos()
	cookie.Set("ixHUD_" .. self.hudID .. "_X", x / ScrW())
	cookie.Set("ixHUD_" .. self.hudID .. "_Y", y / ScrH())
end

function PANEL:Paint(w, h)
	-- Cyan border and semi-transparent background for "Combine" feel
	surface.SetDrawColor(0, 150, 255, 60)
	surface.DrawRect(0, 0, w, h)
	
	surface.SetDrawColor(0, 200, 255, 180)
	surface.DrawOutlinedRect(0, 0, w, h)
	
	-- Crosshair guide lines
	surface.SetDrawColor(255, 255, 255, 20)
	surface.DrawLine(0, 0, w, h)
	surface.DrawLine(w, 0, 0, h)
end

vgui.Register("ixHUDLocator", PANEL, "DFrame")
