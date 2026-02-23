
-- local PLUGIN = PLUGIN

-- PLUGIN.name = "Localized damage"
-- PLUGIN.author = "Subleader"
-- PLUGIN.description = "Damage are different depending on which limb is being hurt."

-- ix.config.Add("localizedDamage", true, "Activate the Localized Damage.", nil, {
-- 	category = "Localized damage"
-- })

-- ix.config.Add("HeadScaleDamage", 3, "How much should head damage be scaled by?", nil, {
-- 	data = {min = 0, max = 10, decimals = 1},
-- 	category = "Localized damage"
-- })

-- ix.config.Add("ArmsScaleDamage", 0.4, "How much should arms damage be scaled by?", nil, {
-- 	data = {min = 0, max = 10, decimals = 1},
-- 	category = "Localized damage"
-- })

-- ix.config.Add("LegsScaleDamage", 0.5, "How much should legs damage be scaled by?", nil, {
-- 	data = {min = 0, max = 10, decimals = 1},
-- 	category = "Localized damage"
-- })

-- ix.config.Add("StomachScaleDamage", 0.8, "How much should stomach damage be scaled by?", nil, {
-- 	data = {min = 0, max = 10, decimals = 1},
-- 	category = "Localized damage"
-- })

-- function PLUGIN:ScalePlayerDamage(client, hitgroup, dmginfo)
-- 	if (ix.config.Get("localizedDamage")) then
-- 		if (SERVER) then
-- 			ix.log.AddRaw("Base damage : "..dmginfo:GetDamage().." / HITGROUP : "..hitgroup);
-- 		end

-- 		local scale = 1
-- 		local finalExpectedScale = 1

-- 		if (hitgroup == HITGROUP_STOMACH) then
-- 			finalExpectedScale = ix.config.Get("StomachScaleDamage", 0.8)
-- 			scale = finalExpectedScale
-- 		elseif ((hitgroup == HITGROUP_LEFTARM) or (hitgroup == HITGROUP_RIGHTARM)) then
-- 			finalExpectedScale = ix.config.Get("ArmsScaleDamage", 0.4)
-- 			scale = finalExpectedScale / 0.25
-- 		elseif (hitgroup == HITGROUP_HEAD) then
-- 			finalExpectedScale = ix.config.Get("HeadScaleDamage", 3)
-- 			scale = finalExpectedScale / 2
-- 		elseif ((hitgroup == HITGROUP_LEFTLEG) or (hitgroup == HITGROUP_RIGHTLEG)) then
-- 			finalExpectedScale = ix.config.Get("LegsScaleDamage", 0.5)
-- 			scale = finalExpectedScale / 0.25
-- 		end

-- 		dmginfo:ScaleDamage(scale)

-- 		if (SERVER) then
-- 			local expectedFinalDamage = dmginfo:GetDamage()
-- 			if (hitgroup == HITGROUP_HEAD) then expectedFinalDamage = expectedFinalDamage * 2
-- 			elseif (hitgroup == HITGROUP_LEFTARM or hitgroup == HITGROUP_RIGHTARM or hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG) then expectedFinalDamage = expectedFinalDamage * 0.25 end
			
-- 			ix.log.AddRaw("Intended Final damage (Plugin) : "..expectedFinalDamage.." / HITGROUP : "..hitgroup);
-- 		end
-- 	end
-- end