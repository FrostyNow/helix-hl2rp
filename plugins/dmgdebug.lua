local PLUGIN = PLUGIN

PLUGIN.name = "Damage Debug"
PLUGIN.author = "Frosty"
PLUGIN.desc = "For debugging purpose."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

if SERVER then
	concommand.Add("ix_debug_damage_hooks", function(ply, cmd, args)
		if IsValid(ply) and not ply:IsSuperAdmin() then return end
		
		-- 데미지와 관련된 주요 훅 목록
		local hooksToCheck = {"EntityTakeDamage", "ScalePlayerDamage", "PlayerTraceAttack", "ScaleNPCDamage"}
		
		ply:PrintMessage(HUD_PRINTCONSOLE, "\n========== [데미지 관련 훅(Hook) 추적 결과] ==========")
		
		for _, event in ipairs(hooksToCheck) do
			ply:PrintMessage(HUD_PRINTCONSOLE, "\n▶ 훅 이벤트: " .. event)
			local hooks = hook.GetTable()[event]
			
			if hooks then
				for name, func in pairs(hooks) do
					if isfunction(func) then
						local info = debug.getinfo(func)
						if info then
							-- 어떤 플러그인/애드온의 파일인지, 몇 번째 줄인지 출력
							ply:PrintMessage(HUD_PRINTCONSOLE, string.format(" - 이름: %s | 경로: %s (줄: %d)", tostring(name), tostring(info.short_src), info.linedefined or 0))
						end
					else
						ply:PrintMessage(HUD_PRINTCONSOLE, string.format(" - 이름: %s | (함수가 아닙니다)", tostring(name)))
					end
				end
			else
				ply:PrintMessage(HUD_PRINTCONSOLE, " - 이 이벤트에 등록된 훅이 없습니다.")
			end
		end
		ply:PrintMessage(HUD_PRINTCONSOLE, "========================================================\n")
	end)
end