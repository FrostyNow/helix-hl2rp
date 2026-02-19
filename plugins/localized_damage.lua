
local PLUGIN = PLUGIN

PLUGIN.name = "Localized damage"
PLUGIN.author = "Subleader"
PLUGIN.description = "Damage are different depending on which limb is being hurt."

ix.config.Add("localizedDamage", true, "Activate the Localized Damage.", nil, {
	category = "Localized damage"
})

ix.config.Add("HeadScaleDamage", 3, "How much should head damage be scaled by?", nil, {
	data = {min = 0, max = 10, decimals = 1},
	category = "Localized damage"
})

ix.config.Add("ArmsScaleDamage", 0.4, "How much should arms damage be scaled by?", nil, {
	data = {min = 0, max = 10, decimals = 1},
	category = "Localized damage"
})

ix.config.Add("LegsScaleDamage", 0.5, "How much should legs damage be scaled by?", nil, {
	data = {min = 0, max = 10, decimals = 1},
	category = "Localized damage"
})

ix.config.Add("StomachScaleDamage", 0.8, "How much should stomach damage be scaled by?", nil, {
	data = {min = 0, max = 10, decimals = 1},
	category = "Localized damage"
})

function PLUGIN:ScalePlayerDamage(client, hitgroup, dmginfo)
	if (ix.config.Get("localizedDamage")) then
		if (SERVER) then
			ix.log.AddRaw("Base damage : "..dmginfo:GetDamage().." / HITGROUP : "..hitgroup);
		end
		if (hitgroup == HITGROUP_STOMACH) then
			dmginfo:ScaleDamage(ix.config.Get("StomachScaleDamage", 0.8))
		elseif ((hitgroup == HITGROUP_LEFTARM) or (hitgroup == HITGROUP_RIGHTARM)) then
			dmginfo:ScaleDamage(ix.config.Get("ArmsScaleDamage", 0.4))
		elseif (hitgroup == HITGROUP_HEAD) then
			dmginfo:ScaleDamage(ix.config.Get("HeadScaleDamage", 3))
		elseif ((hitgroup == HITGROUP_LEFTLEG) or (hitgroup == HITGROUP_RIGHTLEG)) then
			dmginfo:ScaleDamage(ix.config.Get("LegsScaleDamage", 0.5))
		end
	end
	if (SERVER) then
		ix.log.AddRaw("Scaled damage : "..dmginfo:GetDamage().." / HITGROUP : "..hitgroup);
	end
end