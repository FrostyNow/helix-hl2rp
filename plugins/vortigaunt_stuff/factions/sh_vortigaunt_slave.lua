
FACTION.name = "Enslaved Vortigaunt"
FACTION.description = "vortigauntDesc"
FACTION.color = Color(77, 158, 154, 255)
FACTION.models = {"models/vortigaunt_slave.mdl"}
FACTION.weapons = {"swep_vortigaunt_sweep"}
FACTION.isDefault = true
FACTION.isGloballyRecognized = false

function FACTION:OnTransfered(client)
	local character = client:GetCharacter()

	character:SetModel("models/vortigaunt_slave.mdl")
	
	-- Assign enslaved vortigaunt class
	for k, v in pairs(ix.class.list) do
		if v.faction == FACTION_ENSLAVEDVORTIGAUNT and v.isDefault then
			character:SetClass(k)
			break
		end
	end
	
	-- Remove free vortigaunt weapons (keep only sweep)
	character:TakeWeapon("swep_vortigaunt_beam_edit")
	character:TakeWeapon("swep_vortigaunt_heal")
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


FACTION_ENSLAVEDVORTIGAUNT = FACTION.index
