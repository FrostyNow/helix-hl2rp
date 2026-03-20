local PLUGIN = PLUGIN
local applyCooldowns = {}

ix.command.Add("Apply", {
	alias = {"CID"},
	description = "@cmdApply",
	OnRun = function(self, client)
		local curTime = CurTime()
		local nextApplyTime = applyCooldowns[client]

		if (nextApplyTime and nextApplyTime > curTime) then
			return client:NotifyLocalized("applyCooldown", math.ceil(nextApplyTime - curTime))
		end

		local character = client:GetCharacter()

		if character then
			local cidData = Schema.GetIdentificationData and Schema:GetIdentificationData(character)

			if cidData then
				cidData = PLUGIN:GetCIDData(cidData.item or cidData, character)
				local name = cidData.name

				applyCooldowns[client] = curTime + 5

				-- ix.chat.Send(client, "me", name .. " #" .. id)

				local data = {}
				data.start = client:GetShootPos()
				data.endpos = data.start + client:GetAimVector() * 96
				data.filter = client
				local target = util.TraceLine(data).Entity

				if (IsValid(target) and target:IsPlayer()) then
					-- Recognition logic: if CID name matches character name, target recognizes client
					if (name == character:GetName()) then
						target:GetCharacter():Recognize(character:GetID())
					end

					PLUGIN:SendCIDPanel(target, client, cidData)
				end
			else
				return client:NotifyLocalized("dontHaveCID")
			end
		else
			return client:NotifyLocalized("dontHaveCID")
		end
	end
})

ix.command.Add("Name", {
	description = "@cmdName",
	OnRun = function(self, client)
		local character = client:GetCharacter()

		if character then
			ix.chat.Send(client, "ic", client:Name())
		end
	end
})
