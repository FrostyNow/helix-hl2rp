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
	optdIxCalloutClientEnabled = "Allows supported factions to automatically speak in response to nearby events."
})

ix.lang.AddTable("korean", {
	optIxCalloutClientEnabled = "자동 보이스 반응",
	optdIxCalloutClientEnabled = "지원되는 진영이 주변 상황에 자동으로 음성을 내도록 합니다."
})

ix.option.Add("ixCalloutClientEnabled", ix.type.bool, true, {
	category = "Helix Callout"
})

ix.config.Add("ixCalloutEnabled", true, "Whether or not the automatic callout system is enabled.", nil, {
	category = "Helix Callout"
})

if (ix.area and ix.area.AddProperty) then
	ix.area.AddProperty("sector", ix.type.number, 0, {
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

ix.config.Add("mpfCalloutTheme", ix.type.string, "auto", {
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
	local sector = properties and tonumber(properties.sector) or nil

	if (sector and sector > 0) then
		return math.floor(sector)
	end
end

function PLUGIN:GetAreaSectorLabel(areaID)
	local sector = self:GetAreaSectorNumber(areaID)

	if (!sector) then
		return nil
	end

	return string.format("구역 %d", sector)
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

ix.util.Include("sv_plugin.lua")

function PLUGIN:IsVoicePluginAvailable()
	return ix.config.Get("ixCalloutEnabled", true) and (ix.plugin.list["ixvoice"] != nil)
end

function PLUGIN:InitializedPlugins()
	self.ixVoicePlugin = ix.plugin.list["ixvoice"]

	if (SERVER) then
		self.reactedGrenades = self.reactedGrenades or {}
		self.playerCooldowns = self.playerCooldowns or {}
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
