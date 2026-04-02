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
	optAutoVoiceEnabled = "Automatic voice reactions",
	optdAutoVoiceEnabled = "Allows supported factions to automatically speak in response to nearby events."
})

ix.lang.AddTable("korean", {
	optAutoVoiceEnabled = "자동 보이스 반응",
	optdAutoVoiceEnabled = "지원되는 진영이 주변 상황에 자동으로 음성을 내도록 합니다."
})

ix.option.Add("autoVoiceEnabled", ix.type.bool, true, {
	category = "voices"
})

if (ix.area and ix.area.AddProperty) then
	ix.area.AddProperty("sector", ix.type.number, 0, {
		category = "Automatic Voice"
	})
end

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

ix.util.Include("sv_plugin.lua")

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
