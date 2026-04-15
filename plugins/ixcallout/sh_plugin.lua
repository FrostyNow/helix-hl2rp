local PLUGIN = PLUGIN

PLUGIN.name = "Automatic Callout"
PLUGIN.author = "Frosty"
PLUGIN.description = "Adds NPC-style automatic voice reactions for supported factions."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

PLUGIN.voiceTypes = PLUGIN.voiceTypes or {
	combine = {
		factions = {}
	},
	metropolice = {
		factions = {}
	}
}

ix.lang.AddTable("english", {
	optIxCalloutClientEnabled = "Automatic voice reactions",
	optdIxCalloutClientEnabled = "Allows supported factions to automatically speak in response to nearby events.",
	optCalloutMenuBind = "Callout menu bind",
	optdCalloutMenuBind = "Key used to open the quick callout menu. Use values like Z, F5, KP_1, or NONE to disable.",
	calloutMenuTitle = "Callout Menu",
	calloutMenuPage = "Page %d / %d",
	calloutMenuExit = "Exit",
	["sector_index"] = "Sector Index",
	["calloutTheme"] = "Theme",
})

ix.lang.AddTable("korean", {
	optIxCalloutClientEnabled = "자동 보이스 반응",
	optdIxCalloutClientEnabled = "지원되는 진영이 주변 상황에 자동으로 음성을 내도록 합니다.",
	optCalloutMenuBind = "콜아웃 메뉴 바인드",
	optdCalloutMenuBind = "빠른 콜아웃 메뉴를 여는 키입니다. Z, F5, KP_1 같은 값을 쓰고, NONE으로 비활성화할 수 있습니다.",
	calloutMenuTitle = "콜아웃 메뉴",
	calloutMenuPage = "%d / %d 페이지",
	calloutMenuExit = "나가기",
	["Affirmative/Roger"] = "긍정",
	["Negative"] = "부정",
	["Contact"] = "포착",
	["Attack"] = "공격",
	["Sector Clear"] = "구역 확보",
	["Need Backup"] = "지원 요청",
	["GO"] = "전진",
	["Take Cover"] = "엄폐",
	["Fall Back"] = "후퇴",
	["Report In"] = "상황 보고",
	["Hold This Position"] = "위치 사수",
	["sector_index"] = "구역 번호",
	["calloutTheme"] = "테마",
})

ix.option.Add("ixCalloutClientEnabled", ix.type.bool, true, {
	category = "Helix Callout",
	bNetworked = true
})

if (CLIENT) then
	local bUpdatingCalloutBind = false
	local BIND_ALIASES = {
		[""] = "NONE", OFF = "NONE", DISABLE = "NONE", DISABLED = "NONE",
		ESC = "ESCAPE", RETURN = "ENTER"
	}

	local function resolveCalloutBindCode(bindText)
		local normalized = string.upper(string.Trim(tostring(bindText or "")))
		normalized = normalized:gsub("^KEY_", "")
		normalized = normalized:gsub("[%s%-]+", "_")
		normalized = BIND_ALIASES[normalized] or normalized

		if (normalized == "NONE") then return KEY_NONE, normalized end

		local keyCode = input.GetKeyCode and input.GetKeyCode(normalized) or nil
		if (isnumber(keyCode) and keyCode != KEY_NONE) then return keyCode, normalized end

		keyCode = _G[normalized] or _G["KEY_" .. normalized]
		if (isnumber(keyCode)) then return keyCode, normalized end
	end

	function PLUGIN:GetCalloutMenuBindCode()
		local code = resolveCalloutBindCode(ix.option.Get("calloutMenuBind", "NONE"))
		return code or KEY_NONE
	end

	ix.option.Add("calloutMenuBind", ix.type.string, "NONE", {
		category = "Helix Callout",
		OnChanged = function(_, value)
			if (bUpdatingCalloutBind) then return end
			local normalized = select(2, resolveCalloutBindCode(value))
			local next = normalized or "NONE"
			if (next != value) then
				bUpdatingCalloutBind = true
				ix.option.Set("calloutMenuBind", next)
				bUpdatingCalloutBind = false
			end
		end
	})
end

ix.config.Add("ixCalloutEnabled", true, "Whether or not the automatic callout system is enabled.", nil, {
	category = "Helix Callout"
})

if (ix.area and ix.area.AddProperty) then
	ix.area.AddProperty("sector_index", ix.type.number, 0, {
		category = "Helix Callout"
	})

	ix.area.AddProperty("calloutTheme", ix.type.string, "none", {
		name = "Callout Theme Override",
		category = "Helix Callout",
		data = {
			choices = {
				"none",
				"default",
				"trainstation",
				"canals",
				"restricted",
				"ravenholm",
				"coast",
				"prison",
				"urban",
				"citadel"
			}
		}
	})
end

ix.config.Add("mpfCalloutTheme", "auto", "The default voice theme for automatic callouts.", nil, {
	category = "Helix Callout",
	data = {
		choices = {
			"auto",
			"default",
			"trainstation",
			"canals",
			"restricted",
			"ravenholm",
			"coast",
			"prison",
			"urban",
			"citadel"
		}
	}
})

function PLUGIN:GetAreaSectorNumber(areaID)
	if (!areaID or areaID == "" or !ix.area or !ix.area.stored) then
		return nil
	end

	local area = ix.area.stored[areaID]
	local properties = area and area.properties
	local sector_index = properties and tonumber(properties.sector_index) or nil

	if (sector_index and sector_index > 0) then
		return math.floor(sector_index)
	end
end

function PLUGIN:GetAreaSectorLabel(areaID)
	local sector_index = self:GetAreaSectorNumber(areaID)

	if (!sector_index) then
		return nil
	end

	return string.format("구역 %d", sector_index)
end

function PLUGIN:GetAreaCalloutTheme(areaID)
	if (!areaID or areaID == "" or !ix.area or !ix.area.stored) then
		return nil
	end

	local area = ix.area.stored[areaID]
	local properties = area and area.properties
	local theme = properties and properties.calloutTheme or "none"

	if (theme and theme != "none") then
		return theme
	end
end

-- Manual voice menu categories (shared across all supported factions).
-- templates: uses BuildTemplateEvent for context-aware random playback.
-- voices:    picks one voice key directly from Schema.voices ("Combine" class).
PLUGIN.MANUAL_CATEGORIES = {
	-- Page 1
	{
		labelKey = "Affirmative/Roger",
		templates = { "answer" }
	},
	{
		labelKey = "Negative",
		voices = { "10-2" }
	},
	{
		labelKey = "Contact",
		templates = { "go_alert", "leader_alert", "combatCallout" }
	},
	{
		labelKey = "Attack",
		templates = { "assault", "flank" }
	},
	{
		labelKey = "Sector Clear",
		templates = { "clear" }
	},
	{
		labelKey = "Need Backup",
		voices = { "heavy resistance", "request reinforce", "request reserve", "request backup", "request medivac", "11-99", "10-78" }
	},
	-- Page 2
	{
		labelKey = "GO",
		voices = { "move in", "go sharp", "go sharp go sharp", "advance" }
	},
	{
		labelKey = "Take Cover",
		voices = { "cover", "cover hurt", "cover me", "request cover" }
	},
	{
		labelKey = "Fall Back",
		voices = { "run", "fall out" }
	},
	{
		labelKey = "Report In",
		templates = { "check" }
	},
	{
		labelKey = "Hold This Position",
		voices = { "harden position", "hold pos", "hold cp" }
	},
}

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_voicemenu.lua")

function PLUGIN:IsVoicePluginAvailable()
	return ix.config.Get("ixCalloutEnabled", true) and (ix.plugin.list["ixvoice"] != nil)
end

function PLUGIN:InitializedPlugins()
	self.ixVoicePlugin = ix.plugin.list["ixvoice"]

	if (SERVER) then
		self.reactedGrenades = self.reactedGrenades or {}
		self.playerCooldowns = self.playerCooldowns or {}
		self.activePhysicsThreats = self.activePhysicsThreats or {}
		self.nextGrenadeScan = 0
		self.nextDeathReaction = 0
		self.nextCombatScan = 0
	end

	if (self.voiceTypes) then
		if (self.voiceTypes.combine) then
			self.voiceTypes.combine.factions = {
				[FACTION_OTA] = true
			}
		end

		if (self.voiceTypes.metropolice) then
			self.voiceTypes.metropolice.factions = {
				[FACTION_MPF] = true
			}
		end
	end

	if (SERVER) then
		self:AssignAreaSectors()
	end
end
