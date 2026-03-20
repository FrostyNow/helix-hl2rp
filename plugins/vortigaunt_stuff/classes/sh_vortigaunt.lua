CLASS.name = "Vortigaunt"
CLASS.faction = FACTION_VORT
CLASS.isDefault = false

function CLASS:CanSwitchTo(client)
	return false
end

function CLASS:OnSet(client)
	local plugin = ix.plugin.Get("vortigaunt_stuff")

	if (plugin and IsValid(client)) then
		plugin:ApplyVortigauntClassState(client:GetCharacter(), client, CLASS_VORT)
	end
end

CLASS_VORT = CLASS.index
