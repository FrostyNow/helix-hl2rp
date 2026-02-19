
DEFINE_BASECLASS("base_gmodentity")

ENT.Type = "anim"
ENT.Author = "Aspect™ & Trudeau"
ENT.PrintName = "Camera Terminal"
ENT.Category = "HL2 RP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.UsableInVehicle = true

function ENT:GetEntityMenu(client)
	local options = {}
	
	options["Disable"] = true

	for _, v in pairs(ents.FindByClass("npc_combine_camera")) do
		options["View C-i" .. v:EntIndex()] = true
	end

	return options
end

if (CLIENT) then
	function ENT:OnPopulateEntityInfo(container)
		local camera = self:GetNWEntity("camera")

		if (IsValid(camera) and camera != self) then
			return
		end

		local name = container:AddRow("name")
		name:SetImportant()
		name:SetText(L("Camera Terminal"))
		name:SizeToContents()

		local desc = container:AddRow("desc")
		desc:SetText(L("cameraTerminalDesc"))
		desc:SizeToContents()
	end
end