local PLUGIN = PLUGIN

PLUGIN.name = "Real Time Lighting"
PLUGIN.description = "Implements a simple real time lighting system which supports Simple Weather and StormFox2." // this has only been tested with simple weather, simple weather is giga chad. Also only supports maps with env_sun entities.
PLUGIN.author = "Reece™"

// r_farz needs to be 100000 if there is black skies sometimes. command requires sv_cheats sadly.
RunConsoleCommand("r_flashlightdepthres", "8192")

ix.option.Add("realTimeLightingEnabled", ix.type.bool, true, {
	category = "Real Time Lighting",
	default = true,
})

ix.lang.AddTable("english", {
	optRealTimeLightingEnabled = "Enabled",
	optdRealTimeLightingEnabled = "Wether or not you would like Real Time Lighting enabled.",
})

ix.lang.AddTable("korean", {
	["Real Time Lighting"] = "실시간 조명",
	optRealTimeLightingEnabled = "실시간 조명",
	optdRealTimeLightingEnabled = "실시간 조명(Real Time Lighting)을 적용합니다.",
})

ix.util.Include("cl_plugin.lua")