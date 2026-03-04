--[[
	Parallax Framework
	Copyright (c) 2025 Parallax Framework Contributors

	This file is part of the Parallax Framework and is licensed under the MIT License.
	You may use, copy, modify, merge, publish, distribute, and sublicense this file
	under the terms of the LICENSE file included with this project.

	Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PLUGIN = PLUGIN

PLUGIN.name = "StormFox2 Static Prop Lighting Fix"
PLUGIN.description = "Fixes static prop lighting issues when StormFox2 time changes, by toggling radiosity off and on in order to refresh said static prop lighting."
PLUGIN.author = "Riggs"

if (CLIENT) then
	local function StormFox2_StaticPropLightingFix()
		if not StormFox2 then return end

		RunConsoleCommand("r_radiosity", 0)

		timer.Simple(5, function()
			RunConsoleCommand("r_radiosity", 3)
		end)
	end

	hook.Add("StormFox2.Time.OnDay", "StormFox2.StaticPropLightingFix", StormFox2_StaticPropLightingFix)
	hook.Add("StormFox2.Time.OnNight", "StormFox2.StaticPropLightingFix", StormFox2_StaticPropLightingFix)
end