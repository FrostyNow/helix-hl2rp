
local PLUGIN = PLUGIN

function PLUGIN:CharacterLoaded(character)
	local client = character:GetPlayer()

	if (IsValid(client)) then
		local uniqueID = "ixAntiAFK"..client:SteamID64()

		timer.Create(uniqueID, ix.config.Get("afkTime"), 0, function()
			if (IsValid(client) and client:GetCharacter()) then
				PLUGIN:Update(client)
			else
				timer.Remove(uniqueID)
			end
		end)
	end
end

function PLUGIN:CanPlayerEarnSalary(client, faction)
	if (client.isAFK) then
		return false
	end
end

function PLUGIN:SetupMove(client, mv, cmd)
	if (client.isAFK) then
		if (cmd:GetButtons() > 0 or cmd:GetMouseX() ~= 0 or cmd:GetMouseY() ~= 0) then
			client.isManualAFK = nil
			client.isAFK = nil
			client:SetNetVar("IsAFK", false)
			client.ixLastAimVector = client:GetAimVector()
			client.ixLastPosition = client:GetPos()
		end
	end
end

function PLUGIN:PlayerSay(client, text)
	if (client.isAFK) then
		client.isManualAFK = nil
		client.isAFK = nil
		client:SetNetVar("IsAFK", false)
		client.ixLastAimVector = client:GetAimVector()
		client.ixLastPosition = client:GetPos()
	end
end
