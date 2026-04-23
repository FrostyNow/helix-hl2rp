AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Notepad"
ENT.Author = "Black Tea | Ported by Frosty";
ENT.Category = "Helix"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.PhysgunDisable = true
ENT.bNoPersist = true
ENT.PopulateEntityInfo = true

if (SERVER) then
	function ENT:Initialize()
	end

	function ENT:OnRemove()
	end

	function ENT:Use(activator)
		if (self.id and WRITINGDATA[self.id]) then
			netstream.Start(activator, "receiveNote", self.id, WRITINGDATA[self.id], self:CanWrite(activator))
		end
	end
else
	function ENT:OnPopulateEntityInfo(container)
		local name = container:AddRow("name")
		name:SetImportant()
		name:SetText(L("Notepad"))
		name:SizeToContents()

		local desc = container:AddRow("desc")
		desc:SetText(L("notepadDesc"))
		desc:SizeToContents()
	end

	function ENT:Draw()
		self:DrawModel()
	end
end

function ENT:GetOwner()
	return self:GetNetVar("ownerChar")
end

function ENT:CanWrite(client)
	if (client) then
		return (client:IsAdmin() or client:GetChar().id == self:GetOwner())
	end
end