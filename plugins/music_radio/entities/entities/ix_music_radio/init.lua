AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')


function ENT:Initialize()
    self:SetModel("models/props_lab/citizenradio.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
end


function ENT:Use(activator, caller)
    if ( IsValid(caller) and activator:IsPlayer() ) then
        if (IsValid(self.occupier) and self.occupier != activator and self.occupier:GetPos():DistToSqr(self:GetPos()) < 100000) then
            activator:NotifyLocalized("alreadyUsingRadio")
            return
        end

        self.occupier = activator

        net.Start("ixMusicRadioOpenUI")
        net.WriteEntity(self)
        net.Send(activator)
    end
end