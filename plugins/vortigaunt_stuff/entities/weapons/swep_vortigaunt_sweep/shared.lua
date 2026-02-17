if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
end

if (CLIENT) then
	SWEP.Slot = 3;
	SWEP.SlotPos = 5;
	SWEP.DrawAmmo = false;
	SWEP.PrintName = L("Broom", LocalPlayer());
	SWEP.DrawCrosshair = true;
	SWEP.Instructions = L("Primary Fire: Sweep\nSecondary Fire: Push/Knock")
	SWEP.Purpose = L("To sweep up dirt and trash.")
end

SWEP.Author					= "JohnyReaper"

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
	self:SetNextSecondaryFire( CurTime() + 2 )

	if (SERVER) then
		local soundPath = "physics/cardboard/cardboard_box_scrape_smooth_loop1.wav"
		
		-- Freeze player to stop footstep sounds
		self.Owner:Freeze(true)
		self.Owner:ForceSequence("sweep", nil,nil, false)
		self.Owner:EmitSound(soundPath, 70, 100, 0.1)

		timer.Simple(1, function()
			if (IsValid(self) and IsValid(self.Owner)) then
				self.Owner:StopSound(soundPath)
				self.Owner:EmitSound(soundPath, 70, 100, 0.1)

				timer.Simple(0.7, function()
					if (IsValid(self) and IsValid(self.Owner)) then
						self.Owner:StopSound(soundPath)
						-- Unfreeze player after sweep animation
						self.Owner:Freeze(false)
					end
				end)
			end
		end)
	end
end;


function SWEP:SecondaryAttack()
	if (!IsValid(self.Owner)) then return false end
	if (!self.Owner:Alive()) then return false end
	if (!self.Owner:GetCharacter() or !self.Owner:GetCharacter():IsVortigaunt()) then return false end

	self.Owner:LagCompensation(true)
		local data = {}
			data.start = self.Owner:GetShootPos()
			data.endpos = data.start + self.Owner:GetAimVector()*72
			data.filter = self.Owner
			data.mins = Vector(-8, -8, -30)
			data.maxs = Vector(8, 8, 10)
		local trace = util.TraceHull(data)
		local entity = trace.Entity
	self.Owner:LagCompensation(false)

	if (SERVER and IsValid(entity)) then
		local bPushed = false

		if (entity:IsDoor()) then
			if (hook.Run("PlayerCanKnock", self.Owner, entity) == false) then
				return
			end

			self.Owner:ViewPunch(Angle(-1.3, 1.8, 0))
			self.Owner:EmitSound("physics/wood/wood_crate_impact_hard3.wav")
			self.Owner:SetAnimation(PLAYER_ATTACK1)

			self:SetNextSecondaryFire(CurTime() + 0.4)
			self:SetNextPrimaryFire(CurTime() + 1)
		elseif (entity:IsPlayer()) then
			local direction = self.Owner:GetAimVector() * (300 + (self.Owner:GetCharacter():GetAttribute("str", 0) * 3))
				direction.z = 0
			entity:SetVelocity(direction)

			bPushed = true
		else
			local physObj = entity:GetPhysicsObject()

			if (IsValid(physObj)) then
				physObj:SetVelocity(self.Owner:GetAimVector() * 180)
			end

			bPushed = true
		end

		if (bPushed) then
			self:SetNextSecondaryFire(CurTime() + 1.5)
			self:SetNextPrimaryFire(CurTime() + 1.5)
			self.Owner:EmitSound("Weapon_Crossbow.BoltHitBody")
		end
	end
end

