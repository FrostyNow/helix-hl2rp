
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

	local bodygroups = net.ReadTable()
	local skin = net.ReadUInt(8)

	if (canEditBodygroups) then
		local groups = {}

		for k, v in pairs(bodygroups) do
			target:SetBodygroup(tonumber(k) or 0, tonumber(v) or 0)
			groups[tonumber(k) or 0] = tonumber(v) or 0
		end

		targetCharacter:SetData("groups", groups)
	end

	if (canEditSkin) then
		target:SetSkin(skin)
		targetCharacter:SetData("skin", skin)
	end

	targetCharacter:Save()
	ix.log.Add(client, "bodygroupEditor", target)
end)
