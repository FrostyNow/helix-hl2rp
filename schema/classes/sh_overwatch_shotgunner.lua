CLASS.name = "Overwatch Shotgunner"
CLASS.faction = FACTION_OTA
CLASS.isDefault = false

function CLASS:CanSwitchTo(client)
	return Schema:GetCombineRank(client:Name()) == "SGS"
end

function CLASS:OnSet(client)
	local character = client:GetCharacter()
	local inventory = character:GetInventory()

	client:GetCharacter():SetModel("models/combine_soldierproto.mdl")

	local bodygroupPlugin = ix.plugin.Get("bodygroupmanager")

	if (bodygroupPlugin) then
		local player = character:GetPlayer()

		player:SetSkin(1)
		bodygroupPlugin:SetPersistentAppearance(character, nil, 1)
	else
		client:SetSkin(1)
	end
end

CLASS_SGS = CLASS.index
