local PLUGIN = PLUGIN

PLUGIN.name = "Map Button Trigger"
PLUGIN.author = "Frosty"
PLUGIN.description = "Allows triggering custom events when specific map buttons are pressed."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.lang.AddTable("english", {
	broadcastStaticNoise = "Static noise is heard simultaneously from broadcasting devices throughout the city.",
	broadcastRation = "Attention City 17, rations are now available, at the ration distribution terminal.",
	broadcastRationOffline = "Attention City 17, the ration distribution terminal is now offline.",
	broadcastLabour = "Attention City 17, looking for citizens. please proceed to Warehouse 3, immediately.",
})

ix.lang.AddTable("korean", {
	broadcastStaticNoise = "도시 이곳저곳의 방송 장치에서 일제히 잡음이 들립니다.",
	broadcastRation = "17번 지구 주목. 현재 배급소에서 배급이 시작되었다.",
	broadcastRationOffline = "17번 지구 주목. 현재 배급소가 폐쇄되었다.",
	broadcastLabour = "17번 지구 주목. 시민을 소집하고 있다. 즉시 3번 창고로 이동하라.",
})

PLUGIN.buttonTriggers = {
	["rp_industrial17_v1"] = {
		[5377] = function(client, ent)
			for _, v in player.Iterator() do
				ix.chat.Send(nil, "event", L("broadcastStaticNoise", v), false, {v})
			end
		end,
		[4353] = function(client, ent)
			for _, v in player.Iterator() do
				ix.chat.Send(nil, "dispatch", L("broadcastRation", v), false, {v})
			end
		end,
		[4354] = function(client, ent)
			for _, v in player.Iterator() do
				ix.chat.Send(nil, "dispatch", L("broadcastRationOffline", v), false, {v})
			end
		end,
		[5801] = function(client, ent)
			for _, v in player.Iterator() do
				ix.chat.Send(nil, "dispatch", L("broadcastLabour", v), false, {v})
			end
		end,
	},
}

ix.util.Include("sv_hooks.lua")
