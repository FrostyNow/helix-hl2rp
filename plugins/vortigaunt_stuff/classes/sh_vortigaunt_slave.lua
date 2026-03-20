CLASS.name = "Enslaved Vortigaunt"
CLASS.faction = FACTION_VORT
CLASS.isDefault = true

function CLASS:CanSwitchTo(client)
	return false
end

function CLASS:OnSet(client)
	local plugin = ix.plugin.Get("vortigaunt_stuff")

	if (plugin and IsValid(client)) then
		plugin:ApplyVortigauntClassState(client:GetCharacter(), client, CLASS_SLAVE_VORT)
	end
end

CLASS_SLAVE_VORT = CLASS.index
