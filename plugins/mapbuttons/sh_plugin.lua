local PLUGIN = PLUGIN
PLUGIN.name = "Map Button Trigger"
PLUGIN.author = "Frosty"
PLUGIN.description = "Allows triggering custom events when specific map buttons are pressed."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.util.Include("sv_hooks.lua")

ix.lang.AddTable("english", {
	broadcastStaticNoise = "Static noise is heard simultaneously from broadcasting devices throughout the city.",
	broadcastRation = "todo",
})

ix.lang.AddTable("korean", {
	broadcastStaticNoise = "도시 이곳저곳의 방송 장치에서 일제히 잡음이 들립니다.",
	broadcastRation = "시민에게 알린다. 배급소가 개방되었다. 위치로 이동하여 배급을 수령하라.",
})

PLUGIN.buttonTriggers = {
	["rp_industrial17_v1"] = {
		[3889] = function(client, ent)
			ix.chat.Send(nil, "event", "@broadcastStaticNoise")
		end,
		-- [todo] = function(client, ent)
		-- 	ix.chat.Send(nil, "event", "@broadcastRation")
		-- end,
	},

	-- Example for another map
	-- ["rp_city17_v4"] = {
	--     [5678] = function(client, ent) ... end,
	-- }
}
