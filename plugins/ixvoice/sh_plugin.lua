PLUGIN.name = "ixVoice with Vocoder"
PLUGIN.description = "Let's users string multiple voice commands together. The name of the plugin same with each plugins by DoopieWop and sanny but core contents has been newly rewritten and replaced by Ronald and Frosty. Please respect their copyrights as well as ours."
PLUGIN.author = "Ronald and Frosty"
PLUGIN.schema = "HL2 RP"

PLUGIN.radioNoiseDistance = PLUGIN.radioNoiseDistance or 1200
PLUGIN.radioNoiseDistanceSqr = PLUGIN.radioNoiseDistanceSqr or (PLUGIN.radioNoiseDistance * PLUGIN.radioNoiseDistance)

ix.util.Include("cl_plugin.lua")
ix.util.Include("sv_plugin.lua")

if (SERVER) then
	resource.AddWorkshop("2291046370")
end

sound.Add({
	name = "Vocoder.On",
	channel = CHAN_STATIC,
	volume = 1,
	level = 60,
	sound = {
		"npc/combine_soldier/vo/on1.wav",
		"npc/combine_soldier/vo/on2.wav",
		-- "vocoder/on4.wav",
		-- "vocoder/on5.wav",
		-- "vocoder/on6.wav",
	}
})

sound.Add({
	name = "Vocoder.Off",
	channel = CHAN_STATIC,
	volume = 1,
	level = 60,
	sound = {
		"npc/combine_soldier/vo/off1.wav",
		"npc/combine_soldier/vo/off2.wav",
		"npc/combine_soldier/vo/off3.wav",
		-- "vocoder/off4.wav",
		"vocoder/off5.wav",
		-- "vocoder/off6.wav",
		-- "vocoder/off7.wav",
		"vocoder/off8.wav",
	}
})
