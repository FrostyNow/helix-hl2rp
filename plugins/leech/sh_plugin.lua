local PLUGIN = PLUGIN

PLUGIN.name = "Leeches"
PLUGIN.author = "Frosty"
PLUGIN.description = "Adds aggressive leeches to deep water areas."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.util.Include("sv_plugin.lua")

ix.lang.AddTable("korean", {
	leeches = "거머리",
	leechesBitten = "거머리떼가 당신을 공격합니다!",
	leechWarning1 = "물 속에 뭔가가 움직이는 것 같습니다...",
	leechWarning2 = "물 속에서 뭔가가 느껴집니다...",
	leechWarning3 = "물 위의 잔물결이 심상치 않습니다..."
})

ix.lang.AddTable("english", {
	leeches = "Leeches",
	leechesBitten = "A swarm of leeches is biting you!",
	leechWarning1 = "Something seems to be moving in the water...",
	leechWarning2 = "You feel something moving in the water...",
	leechWarning3 = "The ripples in the water seem unusual..."
})

function PLUGIN:SetupAreaProperties()
	ix.area.AddProperty("leeches", ix.type.bool, false)
end
