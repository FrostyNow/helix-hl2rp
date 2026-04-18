local PLUGIN = PLUGIN

surface.CreateFont("ixTerritoryLabel", {
	font = "NanumGothic" or "Tahoma",
	size = ScreenScale(6),
	weight = 500,
	antialias = true
})

surface.CreateFont("ixTerritoryArea", {
	font = "NanumGothic" or "Tahoma",
	size = ScreenScale(7),
	weight = 700,
	antialias = true
})

local function DrawArc(cx, cy, radius, thickness, startAngle, endAngle, color)
	local segments = 48
	local step = math.max((endAngle - startAngle) / segments, 1)
	local polys = {}

	for angle = startAngle, endAngle - step, step do
		local nextAngle = math.min(angle + step, endAngle)
		local rad1 = math.rad(angle)
		local rad2 = math.rad(nextAngle)

		polys[#polys + 1] = {
			{
				x = cx + math.cos(rad1) * (radius - thickness),
				y = cy + math.sin(rad1) * (radius - thickness)
			},
			{
				x = cx + math.cos(rad1) * radius,
				y = cy + math.sin(rad1) * radius
			},
			{
				x = cx + math.cos(rad2) * radius,
				y = cy + math.sin(rad2) * radius
			},
			{
				x = cx + math.cos(rad2) * (radius - thickness),
				y = cy + math.sin(rad2) * (radius - thickness)
			}
		}
	end

	draw.NoTexture()
	surface.SetDrawColor(color)

	for _, poly in ipairs(polys) do
		surface.DrawPoly(poly)
	end
end

function PLUGIN:HUDPaint()
	local client = LocalPlayer()
	local areaID = client:GetLocalVar("territoryAreaID")

	if (!areaID) then
		return
	end

	local areaName = client:GetLocalVar("territoryAreaName", areaID)
	local ownerTeamID = client:GetLocalVar("territoryOwnerTeamID")
	local progressTeamID = client:GetLocalVar("territoryProgressTeamID")
	local progress = math.Clamp(client:GetLocalVar("territoryProgress", 0), 0, 1)
	local contested = client:GetLocalVar("territoryContested", false)
	local statusText = self:GetCaptureStatusText(areaID, ownerTeamID, progressTeamID, contested, client)

	local x = ScrW() * 0.5
	local y = ScrH() - 110
	local textColor = color_white
	local accent = progressTeamID and self:GetCaptureTeamColor(progressTeamID)
		or ownerTeamID and self:GetCaptureTeamColor(ownerTeamID)
		or Color(210, 210, 210)

	draw.SimpleText(areaName, "ixTerritoryArea", x, y, Color(230, 230, 230, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(statusText, "ixTerritoryLabel", x, y + 18, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if (contested) then
		draw.SimpleText(L("territoryContestedShort", client), "ixTerritoryLabel", x, y + 38, Color(220, 120, 120, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		return
	end

	if (!progressTeamID or progress <= 0) then
		return
	end

	local radius = 24
	local thickness = 5
	local circleY = y - 8

	DrawArc(x, circleY, radius, thickness, -90, 270, Color(20, 20, 20, 180))
	DrawArc(x, circleY, radius, thickness, -90, -90 + (360 * progress), accent)
	draw.SimpleText(math.ceil(progress * 100) .. "%", "ixTerritoryLabel", x, circleY, Color(240, 240, 240, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
