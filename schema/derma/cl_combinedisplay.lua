
local PANEL = {}
local DEFAULT_BACKGROUND = Color(0, 0, 0, 175)
local DEFAULT_TEXT_COLOR = Color(255, 255, 255)
local LINE_PADDING_X = 8
local LINE_PADDING_Y = 3
local LINE_SPACING = 2

AccessorFunc(PANEL, "font", "Font", FORCE_STRING)
AccessorFunc(PANEL, "maxLines", "MaxLines", FORCE_NUMBER)

function PANEL:Init()
	if (IsValid(ix.gui.combine)) then
		ix.gui.combine:Remove()
	end

	self.lines = {}

	self:SetMaxLines(12)
	self:SetFont("BudgetLabel")

	-- Default position
	local defaultY = (IsValid(ix.gui.bars) and ix.gui.bars:GetTall() or 0) + 4
	local x = cookie.GetNumber("ixHUD_msg_X", 6 / ScrW()) * ScrW()
	local y = cookie.GetNumber("ixHUD_msg_Y", defaultY / ScrH()) * ScrH()

	self:SetPos(x, y)
	self:SetSize(ScrW(), self.maxLines * (draw.GetFontHeight(self.font) + (LINE_PADDING_Y * 2) + LINE_SPACING))
	self:ParentToHUD()

	ix.gui.combine = self
end

-- Adds a line to the combine display. Set expireTime to 0 if it should never be removed.
function PANEL:AddLine(text, color, expireTime, ...)
	if (#self.lines >= self.maxLines) then
		for k, info in ipairs(self.lines) do
			if (info.expireTime != 0) then
				table.remove(self.lines, k)
				break -- Only remove the oldest expiring line
			end
		end
	end

	-- check for any phrases and replace the text
	if (text:sub(1, 1) == "@") then
		text = L(text:sub(2), ...)
	end

	local index = #self.lines + 1
	local background = color or DEFAULT_BACKGROUND

	self.lines[index] = {
		text = "<:: " .. text,
		background = Color(background.r, background.g, background.b, background.a or DEFAULT_BACKGROUND.a),
		textColor = DEFAULT_TEXT_COLOR,
		expireTime = (expireTime != 0 and (CurTime() + (expireTime or 20)) or 0),
		character = 1
	}

	return index
end

function PANEL:RemoveLine(id)
	if (self.lines[id]) then
		table.remove(self.lines, id)
	end
end

function PANEL:Think()
	local defaultY = (IsValid(ix.gui.bars) and ix.gui.bars:GetTall() or 0) + 4
	local x = cookie.GetNumber("ixHUD_msg_X", 6 / ScrW()) * ScrW()
	local y = cookie.GetNumber("ixHUD_msg_Y", defaultY / ScrH()) * ScrH()

	self:SetPos(x, y)
end

function PANEL:Paint(width, height)
	local textHeight = draw.GetFontHeight(self.font)
	local y = 0

	surface.SetFont(self.font)

	for k, info in ipairs(self.lines) do
		if (info.expireTime != 0 and CurTime() >= info.expireTime) then
			table.remove(self.lines, k)
			continue
		end

		if (info.character < info.text:len()) then
			info.character = info.character + 1
		end

		local visibleText = info.text:sub(1, info.character)
		local textWidth = surface.GetTextSize(visibleText)
		local boxHeight = textHeight + (LINE_PADDING_Y * 2)

		surface.SetDrawColor(info.background)
		surface.DrawRect(0, y, textWidth + (LINE_PADDING_X * 2), boxHeight)

		surface.SetTextColor(info.textColor)
		surface.SetTextPos(LINE_PADDING_X, y + LINE_PADDING_Y)
		surface.DrawText(visibleText)

		y = y + boxHeight + LINE_SPACING
	end

	surface.SetDrawColor(Color(0, 0, 0, 255))
end

vgui.Register("ixCombineDisplay", PANEL, "Panel")

if (IsValid(ix.gui.combine)) then
	vgui.Create("ixCombineDisplay")
end
