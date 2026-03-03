local playerMeta = FindMetaTable("Player")

function playerMeta:IsCombine()
	local character = self:GetCharacter()
	if (character and character:IsCombine()) then
		return true
	end

	local faction = self:Team()
	return faction == FACTION_MPF or faction == FACTION_OTA
end

function playerMeta:IsDispatch()
	local name = self:Name()
	local faction = self:Team()
	local bStatus = (self:IsAdmin() and faction == FACTION_OTA) or faction == FACTION_ADMIN or self:IsAdmin()

	if (!bStatus) then
		for k, v in ipairs({ "OfC", "SCN", "DvL", "SeC" }) do
			if (Schema:IsCombineRank(name, v)) then
				bStatus = true

				break
			end
		end
	end

	return bStatus
end

function playerMeta:IsBreencast()
	local name = self:Name()
	local faction = self:Team()
	local bStatus = faction == FACTION_ADMIN or self:IsAdmin()

	return bStatus
end
