
AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Broadcast Console"
ENT.Author = "Frosty"
ENT.Category = "HL2 RP"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PhysgunDisable = true
ENT.bNoPersist = true
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

if (SERVER) then
	function ENT:SpawnFunction(client, trace)
		local console = ents.Create("ix_broadcast_console")

		console:SetPos(trace.HitPos)
		console:SetAngles(Angle(0, (console:GetPos() - client:GetPos()):Angle().y - 180, 0))
		console:Spawn()
		console:Activate()

		Schema:SaveMachines()
		return console
	end

	function ENT:Initialize()
		self:SetModel("models/props_combine/combine_interface001.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:DrawShadow(true)
		self:SetUseType(SIMPLE_USE)

		local physics = self:GetPhysicsObject()

		if (IsValid(physics)) then
			physics:Wake()
		end
	end

    function ENT:Use(activator)
        -- Provide feedback that this is a broadcast console
        activator:NotifyLocalized("broadcastConsoleUse")
    end

    function ENT:OnRemove()
        if (!ix.shuttingDown) then
            Schema:SaveMachines()
        end
    end
else
    function ENT:Draw()
        self:DrawModel()
    end
	function ENT:OnPopulateEntityInfo(container)
		local name = container:AddRow("name")
		name:SetImportant()
		name:SetText(L("Broadcast Console"))
		name:SizeToContents()

		local desc = container:AddRow("desc")
		desc:SetText(L("broadcastConsoleDesc"))
		desc:SizeToContents()

		local instruction = container:AddRow("instruction")
		instruction:SetText(L("broadcastConsoleUse"))
		instruction:SetBackgroundColor(Color(85, 127, 242, 50))
		instruction:SizeToContents()
	end
end
