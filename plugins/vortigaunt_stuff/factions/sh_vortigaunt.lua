
FACTION.name = "Vortigaunt"
FACTION.description = "vortigauntDesc"
FACTION.color = Color(77, 158, 154, 255)
FACTION.models = {"models/vortigaunt_slave.mdl"}
FACTION.weapons = {}
FACTION.isDefault = true
FACTION.isGloballyRecognized = false

function FACTION:OnCharacterCreated(client, character)
	character:SetModel("models/vortigaunt_slave.mdl")

	if (CLASS_SLAVE_VORT) then
		character:SetClass(CLASS_SLAVE_VORT)
	end

	local plugin = ix.plugin.Get("vortigaunt_stuff")

	if (plugin and plugin.EnsureVortigauntCID) then
		plugin:EnsureVortigauntCID(character, client)
	end
end

function FACTION:OnTransferred(character)
	character:SetModel("models/vortigaunt_slave.mdl")

	if (CLASS_SLAVE_VORT) then
		character:SetClass(CLASS_SLAVE_VORT)
	end

	local plugin = ix.plugin.Get("vortigaunt_stuff")

	if (plugin and plugin.EnsureVortigauntCID) then
		plugin:EnsureVortigauntCID(character, character:GetPlayer())
	end
end

function FACTION:ModifyPlayerStep(client, data)
	-- Don't replace sounds while climbing ladders or wading through water
	if data.ladder or data.submerged then
		return
	end

	-- Only replace running sounds
	if data.running then
		data.snd = "npc/vort/vort_foot" .. math.random(1, 4) .. ".wav"
		data.volume = data.volume * 0.2
	end
end

FACTION_VORT = FACTION.index
