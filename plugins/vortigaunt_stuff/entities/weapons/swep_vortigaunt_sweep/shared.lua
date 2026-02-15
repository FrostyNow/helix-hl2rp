if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
end

if (CLIENT) then
	SWEP.Slot = 3;
	SWEP.SlotPos = 5;
	SWEP.DrawAmmo = false;
	SWEP.PrintName = "Broom";
	SWEP.DrawCrosshair = true;
end

SWEP.Author					= "JohnyReaper"
SWEP.Instructions 			= "Primary Fire: Sweep";
SWEP.Purpose 				= "To sweep up dirt and trash.";
SWEP.Contact 				= ""

SWEP.Category				= "Vort Swep" 
SWEP.Slot					= 3
SWEP.SlotPos				= 5
SWEP.Weight					= 5
SWEP.Spawnable     			= true
SWEP.AdminSpawnable			= false;
// SWEP.ViewModel 			= "" -- causes console error spam
SWEP.WorldModel 			= ""
SWEP.HoldType 				= "sweep"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= 1
SWEP.Secondary.DefaultClip	= 1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

function SWEP:Initialize()
	if (self.SetHoldType) then
		self:SetHoldType("normal")
	else
		self:SetWeaponHoldType("normal")
	end
end

function SWEP:Deploy()
	if (!IsValid(self.Owner)) then return false end
	if (!self.Owner:Alive()) then return false end
	if (!self.Owner:GetCharacter() or !self.Owner:GetCharacter():IsVortigaunt()) then return false end

	if (SERVER) then
	self.Owner.broomModel = ents.Create("prop_dynamic")
	self.Owner.broomModel:SetModel("models/props_c17/pushbroom.mdl")
	self.Owner.broomModel:SetMoveType(MOVETYPE_NONE)
	self.Owner.broomModel:SetSolid(SOLID_NONE)
	self.Owner.broomModel:SetParent(self.Owner)
	self.Owner.broomModel:DrawShadow(true)
	self.Owner.broomModel:Spawn()
	self.Owner.broomModel:Fire("setparentattachment", "cleaver_attachment", 0.01)
	end

end

if (CLIENT) then
	function SWEP:PreDrawViewModel(viewModel, weapon, client)
		return true
	end

	function SWEP:DrawWorldModel()
		return
	end
end
function SWEP:Holster()
	if (!IsValid(self.Owner)) then return true end

	if (SERVER) then
		if (self.Owner.broomModel) then
			if (self.Owner.broomModel:IsValid()) then
				self.Owner.broomModel:Remove()
			end
		end
	end

	return true
end


function SWEP:OnRemove()
	if (!IsValid(self.Owner)) then return true end

	if (SERVER) then
		if (self.Owner.broomModel) then
			if (self.Owner.broomModel:IsValid()) then
				self.Owner.broomModel:Remove()
			end
		end
	end

	return true
end


function SWEP:PrimaryAttack()
	if (!IsValid(self.Owner)) then return false end
	if (!self.Owner:Alive()) then return false end
	if (!self.Owner:GetCharacter() or !self.Owner:GetCharacter():IsVortigaunt()) then return false end
	if (!self.Owner:OnGround()) then return false end

	self:SetNextPrimaryFire( CurTime() + 2 )
	-- self.Owner:SetAnimation( PLAYER_ATTACK1 )

	if (SERVER) then
		local soundPath = "physics/cardboard/cardboard_box_scrape_smooth_loop1.wav"
		self.Owner:EmitSound(soundPath, 70, 100, 0.1)

		timer.Simple(1, function()
			if (IsValid(self) and IsValid(self.Owner)) then
				self.Owner:StopSound(soundPath)
				self.Owner:EmitSound(soundPath, 70, 100, 0.1)

				timer.Simple(0.7, function()
					if (IsValid(self) and IsValid(self.Owner)) then
						self.Owner:StopSound(soundPath)
					end
				end)
			end
		end)
		self.Owner:ForceSequence("sweep", nil,nil, false)
	end


end;


function SWEP:SecondaryAttack()
	return false
end

