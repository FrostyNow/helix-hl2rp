
Schema.name = "HL2 RP"
Schema.author = "nebulous.cloud"
Schema.description = "schemaDesc"

-- Include netstream
ix.util.Include("libs/thirdparty/sh_netstream2.lua")

ix.util.Include("sh_configs.lua")
ix.util.Include("sh_commands.lua")

ix.util.Include("cl_schema.lua")
ix.util.Include("cl_hooks.lua")
ix.util.Include("sh_hooks.lua")
ix.util.Include("sh_voices.lua")
ix.util.Include("sv_schema.lua")
ix.util.Include("sv_hooks.lua")

ix.util.Include("meta/sh_player.lua")
ix.util.Include("meta/sv_player.lua")
ix.util.Include("meta/sh_character.lua")

ix.flag.Add("v", "Access to light blackmarket goods.")
ix.flag.Add("V", "Access to heavy blackmarket goods.")
ix.flag.Add("b", "Allows using the bodygroup command to edit your own bodygroups.")

ix.anim.SetModelClass("models/eliteghostcp.mdl", "metrocop")
ix.anim.SetModelClass("models/eliteshockcp.mdl", "metrocop")
ix.anim.SetModelClass("models/leet_police2.mdl", "metrocop")
ix.anim.SetModelClass("models/sect_police2.mdl", "metrocop")
ix.anim.SetModelClass("models/policetrench.mdl", "metrocop")
ix.anim.SetModelClass("models/dpfilms/metropolice/hdpolice.mdl", "metrocop")
ix.anim.SetModelClass("models/dpfilms/metropolice/hl2concept.mdl", "metrocop")
ix.anim.SetModelClass("models/dpfilms/metropolice/policetrench.mdl", "metrocop")
ix.anim.SetModelClass("models/metropolice/leet_police_v2.mdl", "metrocop")

ix.anim.SetModelClass("models/ninja/combine/combine_soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/ninja/combine/combine_soldier_prisonguard.mdl", "overwatch")
ix.anim.SetModelClass("models/ninja/combine/combine_super_soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/characters/combine_soldier/jqblk/combine_s.mdl", "overwatch")
ix.anim.SetModelClass("models/characters/combine_soldier/jqblk/combine_s_super.mdl", "overwatch")
ix.anim.SetModelClass("models/jq/hlvr/characters/combine/combine_captain/combine_captain_hlvr_npc.mdl", "overwatch")
ix.anim.SetModelClass("models/jq/hlvr/characters/combine/grunt/combine_grunt_hlvr_npc.mdl", "overwatch")
ix.anim.SetModelClass("models/jq/hlvr/characters/combine/heavy/combine_heavy_hlvr_npc.mdl", "overwatch")
ix.anim.SetModelClass("models/jq/hlvr/characters/combine/suppressor/combine_suppressor_hlvr_npc.mdl", "overwatch")

ix.anim.SetModelClass("models/armacham/scientists/scientists_1.mdl", "player")
ix.anim.SetModelClass("models/armacham/security/enemy/guard_1.mdl", "overwatch")

ALWAYS_RAISED["gmod_gphone"] = true
ALWAYS_RAISED["weapon_portalgun"] = true

game.AddAmmoType({name = "5.56x45mm"})
game.AddAmmoType({name = "7.62x51mm"})
game.AddAmmoType({name = "9x19mm"})
game.AddAmmoType({name = ".45 ACP"})
game.AddAmmoType({name = "5.45x39mm"})
game.AddAmmoType({name = "7.62x39mm"})
game.AddAmmoType({name = "9x18mm"})
game.AddAmmoType({name = "12 Gauge"})
game.AddAmmoType({name = ".357 Magnum"})
game.AddAmmoType({name = "7.62x25mm"})
game.AddAmmoType({name = "Flares"})

ix.ammo.Register("5.56x45mm")
ix.ammo.Register("7.62x51mm")
ix.ammo.Register("9x19mm")
ix.ammo.Register(".45 ACP")
ix.ammo.Register("5.45x39mm")
ix.ammo.Register("7.62x39mm")
ix.ammo.Register("9x18mm")
ix.ammo.Register("12 Gauge")
ix.ammo.Register(".357 Magnum")
ix.ammo.Register("7.62x25mm")
ix.ammo.Register("Flares")
ix.ammo.Register("PanzerFaust3 Rocket")

function Schema:ZeroNumber(number, length)
	local amount = math.max(0, length - string.len(number))
	return string.rep("0", amount)..tostring(number)
end

function Schema:IsCombineRank(text, rank)
	return string.find(text, "[%D+]"..rank.."[%D+]")
end

local function addNameColoredMessage(color, speaker, formatted)
	if (!IsValid(speaker)) then
		chat.AddText(color, formatted)
		return
	end

	local name = speaker:Name()
	local nameStart, nameEnd = formatted:find(name, 1, true)

	if (nameStart and nameEnd) then
		local beforeName = formatted:sub(1, nameStart - 1)
		local afterName = formatted:sub(nameEnd + 1)

		chat.AddText(color, beforeName, speaker, color, afterName)
		return
	end

	chat.AddText(color, formatted)
end

do
	local CLASS = {}
	CLASS.color = Color(150, 100, 100)
	CLASS.format = "chatDispatchFormat"

	function CLASS:CanSay(speaker, text)
		if (!speaker:IsDispatch()) then
			speaker:NotifyLocalized("notAllowed")

			return false
		end
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, L(self.format, text))
	end

	ix.chat.Register("dispatch", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(75, 150, 50)
	CLASS.format = "chatRadioFormat"

	function CLASS:CanHear(speaker, listener)
		local character = listener:GetCharacter()
		local inventory = character:GetInventory()
		local bHasRadio = false

		for k, v in pairs(inventory:GetItemsByUniqueID("handheld_radio", true)) do
			if (v:GetData("enabled", false) and speaker:GetCharacter():GetData("frequency") == character:GetData("frequency")) then
				bHasRadio = true
				break
			end
		end

		return bHasRadio
	end

	function CLASS:OnChatAdd(speaker, text)
		text = speaker:IsCombine() and string.format("<:: %s ::>", text) or text
		addNameColoredMessage(self.color, speaker, L(self.format, speaker:Name(), text))
	end

	ix.chat.Register("radio", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(255, 255, 175)
	CLASS.format = "chatRadioFormat"

	function CLASS:GetColor(speaker, text)
		if (LocalPlayer():GetEyeTrace().Entity == speaker) then
			return Color(175, 255, 175)
		end

		return self.color
	end

	function CLASS:CanHear(speaker, listener)
		if (ix.chat.classes.radio:CanHear(speaker, listener)) then
			return false
		end

		local chatRange = ix.config.Get("chatRange", 280)

		return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
	end

	function CLASS:OnChatAdd(speaker, text)
		text = speaker:IsCombine() and string.format("<:: %s ::>", text) or text
		chat.AddText(self.color, L(self.format, speaker:Name(), text))
	end

	ix.chat.Register("radio_eavesdrop", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(175, 125, 100)
	CLASS.format = "chatRequestFormat"

	function CLASS:CanHear(speaker, listener)
		return listener:IsCombine() or speaker:Team() == FACTION_ADMIN
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, L(self.format, speaker:Name(), text))
	end

	ix.chat.Register("request", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(175, 125, 100)
	CLASS.format = "chatRequestFormat"

	function CLASS:CanHear(speaker, listener)
		if (ix.chat.classes.request:CanHear(speaker, listener)) then
			return false
		end

		local chatRange = ix.config.Get("chatRange", 280)

		return (speaker:Team() == FACTION_CITIZEN and !listener:IsCombine())
		and (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, L(self.format, speaker:Name(), text))
	end

	ix.chat.Register("request_eavesdrop", CLASS)
end

do
	local CLASS = {}
	CLASS.color = Color(150, 125, 175)
	CLASS.format = "chatBroadcastFormat"

	function CLASS:CanSay(speaker, text)
		if (speaker:Team() != FACTION_ADMIN) then
			speaker:NotifyLocalized("notAllowed")

			return false
		end
	end

	function CLASS:OnChatAdd(speaker, text)
		chat.AddText(self.color, L(self.format, speaker:Name(), text))
	end

	ix.chat.Register("broadcast", CLASS)
end
