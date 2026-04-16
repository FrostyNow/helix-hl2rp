CLASS.name = "Overwatch Shotgunner"
CLASS.faction = FACTION_OTA
CLASS.isDefault = false

function CLASS:CanSwitchTo(client)
	return Schema:GetCombineRank(client:Name()) == "SGS"
end

function CLASS:OnSet(client)
	-- local character = client:GetCharacter()
	-- local inventory = character:GetInventory()

	-- client:GetCharacter():SetModel("models/combine_soldierproto.mdl")

	-- local bodygroupPlugin = ix.plugin.Get("bodygroupmanager")

	-- if (bodygroupPlugin) then
	-- 	local player = character:GetPlayer()
	-- 	local savedSkin = character:GetData("skin")
	-- 	local skin = savedSkin == nil and 1 or (tonumber(savedSkin) or 1)

	-- 	player:SetSkin(skin)

	-- 	if (savedSkin == nil) then
	-- 		bodygroupPlugin:SetPersistentAppearance(character, nil, skin)
	-- 	end
	-- else
	-- 	client:SetSkin(tonumber(character:GetData("skin")) or 1)
	-- end
end

CLASS_SGS = CLASS.index
