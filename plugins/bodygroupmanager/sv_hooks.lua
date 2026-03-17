local PLUGIN = PLUGIN

util.AddNetworkString("ixBodygroupView")
util.AddNetworkString("ixBodygroupTableSet")

ix.log.AddType("bodygroupEditor", function(client, target)
	return string.format("%s has changed %s's bodygroups.", client:GetName(), target:GetName())
end)

net.Receive("ixBodygroupTableSet", function(length, client)
	local target = net.ReadEntity()

	if (!IsValid(target) or !target:IsPlayer() or !target:GetCharacter()) then
		return
	end

	local character = client:GetCharacter()
	local targetCharacter = target:GetCharacter()

	local canAdminEdit = ix.command.HasAccess(client, "CharEditBodygroup")
	local isSelf = (target == client)

	local canEditBodygroups = canAdminEdit or (isSelf and character:HasFlags("b"))
	local canEditSkin = canAdminEdit or (isSelf and character:HasFlags("s"))

	if (!canEditBodygroups and !canEditSkin) then
		return
	end

	PLUGIN:EnsureOriginalAppearance(targetCharacter, target)

	local bodygroups = net.ReadTable()
	local skin = net.ReadUInt(8)
	local modelChangingOutfit = PLUGIN:HasEquippedModelChangingOutfit(targetCharacter)
	local allowedGroups = PLUGIN:GetEditableBodygroupValues(targetCharacter, target, bodygroups)
	local changedPersistentData = false

	if (canEditBodygroups) then
		local groups = {}

		for k, v in pairs(allowedGroups) do
			local index = tonumber(k) or 0
			local value = tonumber(v) or 0
			target:SetBodygroup(index, value)

			local name = target:GetBodygroupName(index)
			if (name and name != "") then
				groups[name] = value
			else
				groups[index] = value
			end
		end

		if (!modelChangingOutfit) then
			PLUGIN:SetPersistentAppearance(targetCharacter, groups)
			changedPersistentData = true
		elseif (!table.IsEmpty(bodygroups)) then
			client:NotifyLocalized("temporaryBodygroupChanges")
		end
	end

	if (canEditSkin) then
		target:SetSkin(skin)

		if (!modelChangingOutfit) then
			PLUGIN:SetPersistentAppearance(targetCharacter, nil, skin)
			changedPersistentData = true
		else
			client:NotifyLocalized("temporaryBodygroupChanges")
		end
	end

	if (changedPersistentData) then
		targetCharacter:Save()
	end
	ix.log.Add(client, "bodygroupEditor", target)
end)
