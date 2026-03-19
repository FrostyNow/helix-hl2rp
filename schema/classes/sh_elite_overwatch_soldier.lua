CLASS.name = "Elite Overwatch Soldier"
CLASS.faction = FACTION_OTA
CLASS.isDefault = false

function CLASS:CanSwitchTo(client)
	return Schema:GetCombineRank(client:Name()) == "EOW"
end

function CLASS:OnSet(client)
	if client and client:IsValid() then
		if client:GetCharacter() then
			client:GetCharacter():SetModel("models/combine_super_soldierproto.mdl")

			local character = client:GetCharacter()
			local bodygroupPlugin = ix.plugin.Get("bodygroupmanager")

			if (bodygroupPlugin) then
				local player = character:GetPlayer()
				local savedSkin = character:GetData("skin")
				local skin = savedSkin == nil and 1 or (tonumber(savedSkin) or 1)

				player:SetSkin(skin)

				if (savedSkin == nil) then
					bodygroupPlugin:SetPersistentAppearance(character, nil, skin)
				end
			end
		end
	end
end

CLASS_EOW = CLASS.index
