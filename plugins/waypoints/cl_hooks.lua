
local PLUGIN = PLUGIN

PLUGIN.waypoints = {}

function PLUGIN:HUDPaint()
	local height = draw.GetFontHeight("BudgetLabel")
	local client = LocalPlayer()
	local clientPos = client:EyePos()
	local character = client:GetCharacter()
	if (not character) then return end

	local faction = ix.faction.Get(character:GetFaction())
	local bHasPermission = faction and faction.canSeeWaypoints
	local bIsAdmin = client:IsAdmin()
	local bInNoclip = client:GetMoveType() == MOVETYPE_NOCLIP

	local bCanSeeByPermission = bHasPermission
	if (bCanSeeByPermission and client:IsCombine() and not Schema:CanPlayerSeeCombineOverlay(client)) then
		bCanSeeByPermission = false
	end

	if (not bCanSeeByPermission and not (bIsAdmin and bInNoclip)) then
		return
	end

	for index, waypoint in pairs(self.waypoints) do
		if (waypoint.time < CurTime()) then
			self.waypoints[index] = nil

			continue
		end

		local screenPos = waypoint.pos:ToScreen()
		local color = waypoint.color
		local text = waypoint.text
		local x, y = screenPos.x, screenPos.y

		surface.SetDrawColor(color)
		surface.DrawLine(x + 15, y, x - 15, y)
		surface.DrawLine(x, y + 15, x, y - 15)
		surface.DrawOutlinedRect(x - 8, y - 8, 17, 17)
		if (client:IsLineOfSightClear(waypoint.pos)) then
			surface.DrawOutlinedRect(x - 5, y - 5, 11, 11)
		end

		surface.SetFont("BudgetLabel")
		surface.SetTextColor(color)
		local width = surface.GetTextSize(text)
		surface.SetTextPos(x - width / 2, y + 17)
		surface.DrawText(text)

		if (!waypoint.noDistance) then
			local distanceText = tostring(math.Round(clientPos:Distance(waypoint.pos) * 0.01905, 2)).."m"
			width = surface.GetTextSize(distanceText)
			surface.SetTextPos(x - width / 2, y - (15 + height))
			surface.DrawText(distanceText)
		end
	end
end

net.Receive("SetupWaypoints", function()
	local bWaypoints = net.ReadBool()

	if (!bWaypoints) then
		PLUGIN.waypoints = {}

		return
	end

	local data = net.ReadTable()

	for index, waypoint in pairs(data) do
		local text = waypoint.text

		-- Translate arguments if they are phrases
		if (waypoint.arguments) then
			for k, v in ipairs(waypoint.arguments) do
				if (type(v) == "string" and v:sub(1, 1) == "@") then
					waypoint.arguments[k] = L(v:sub(2))
				end
			end
		end

		-- check for any phrases and replace the text
		if (text:sub(1, 1) == "@") then
			waypoint.text = "<:: "..L(text:sub(2), unpack(waypoint.arguments or {})).." ::>"
		else
			waypoint.text = "<:: "..text.." ::>"
		end

		data[index] = waypoint
	end

	PLUGIN.waypoints = data
end)

net.Receive("UpdateWaypoint", function()
	local data = net.ReadTable()

	if (data[2] != nil) then
		local text = data[2].text

		-- Translate arguments if they are phrases
		if (data[2].arguments) then
			for k, v in ipairs(data[2].arguments) do
				if (type(v) == "string" and v:sub(1, 1) == "@") then
					data[2].arguments[k] = L(v:sub(2))
				end
			end
		end

		-- check for any phrases and replace the text
		if (text:sub(1, 1) == "@") then
			data[2].text = "<:: "..L(text:sub(2), unpack(data[2].arguments or {})).." ::>"
		else
		    data[2].text = "<:: "..text.." ::>"
		end
	end

	PLUGIN.waypoints[data[1]] = data[2]
end)
