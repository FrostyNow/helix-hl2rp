include("shared.lua")

local SCALE = 0.1
local PADDING = 10
local MAX_DIST_SQR = 500 * 500

function ENT:Draw()
	if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > MAX_DIST_SQR then return end

	local w = self:GetNetVar("panelW", 400)
	local h = self:GetNetVar("panelH", 300)
	local text = self:GetNetVar("text", "")
	local fontSize = self:GetNetVar("fontSize", 24)
	local plugin = ix.plugin.Get("scrollpanel")
	if not plugin or not plugin.WrapText or not plugin.GetTextLayout then return end

	local fontName, lineHeight = plugin:GetTextLayout(fontSize)

	if not self.ixLines or self.ixLastText ~= text or self.ixLastW ~= w or self.ixLastFontSize ~= fontSize then
		local textW = w - PADDING * 2 - 10
		self.ixLines = plugin:WrapText(text, textW, fontName)
		self.ixLastText = text
		self.ixLastW = w
		self.ixLastFontSize = fontSize
	end

	local hw = w / 2
	local hh = h / 2
	local isAimed = (ixScrollPanelAimed == self)
	local scrollY = (ixScrollPanelOffsets and ixScrollPanelOffsets[self:EntIndex()]) or 0
	local lines = self.ixLines

	cam.Start3D2D(self:GetPos(), self:GetAngles(), SCALE)
		if isAimed then
			surface.SetDrawColor(255, 255, 255, 40)
			surface.DrawOutlinedRect(-hw, -hh, w, h, 1)
		end

		if not lines or #lines == 0 then
			draw.SimpleText(text == "" and "[ No text ]" or "", fontName, 0, 0, Color(150, 150, 150, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			local topY = -hh + PADDING
			local botY = hh - PADDING

			for i, line in ipairs(lines) do
				local y = topY + (i - 1) * lineHeight - scrollY
				if y + lineHeight > topY and y < botY then
					draw.SimpleText(line, fontName, -hw + PADDING, y, Color(255, 255, 255, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				end
			end

			local totalH = #lines * lineHeight
			local visibleH = h - PADDING * 2
			if totalH > visibleH then
				local barH = math.max(20, (visibleH / totalH) * visibleH)
				local maxScroll = totalH - visibleH
				local barY = -hh + PADDING + (scrollY / maxScroll) * (visibleH - barH)

				if isAimed then
					surface.SetDrawColor(255, 255, 255, 20)
					surface.DrawRect(hw - PADDING - 4, -hh + PADDING, 3, visibleH)
				end

				surface.SetDrawColor(255, 255, 255, isAimed and 100 or 50)
				surface.DrawRect(hw - PADDING - 4, barY, 3, barH)
			end
		end
	cam.End3D2D()
end
