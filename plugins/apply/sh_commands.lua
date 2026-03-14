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
			local inv = character:GetInventory()
			local cidItem
			for _, v in pairs(inv:GetItems()) do
				if (v.uniqueID == "cid") then
					cidItem = v
					break
				end
			end

			if cidItem then
				local name = cidItem:GetData("name", character:GetName())
				local id = cidItem:GetData("id", "00000")
				local class = cidItem:GetData("class", "Second Class Citizen")

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

					net.Start("ixApplyCID")
						net.WriteTable({
							name = name,
							id = id,
							class = class,
							owner = client -- Pass owner for distance check on client
						})
					net.Send(target)
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
