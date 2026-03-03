local PLUGIN = PLUGIN

ix.command.Add("Apply", {
	description = "@cmdApply",
	OnRun = function(self, client)
		local character = client:GetCharacter()
		local inv = character:GetInventory()

		if character then
			if inv:HasItem("cid") then
				local name = name
				local id = id

				for _, v in pairs(inv:GetItems()) do
					if (v.uniqueID == "cid") then
						name = v:GetData("name")
						id = v:GetData("id")
					end
				end
				
				if id then
					ix.chat.Send(client, "me", name .. " #" .. id)
				elseif client:IsCombine() then
					return client:NotifyLocalized("notCitizen", client:Name())
				else
					return client:NotifyLocalized("dontHaveCID")
				end
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