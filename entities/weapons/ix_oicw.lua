AddCSLuaFile()
DEFINE_BASECLASS("weapon_rtbr_base")

SWEP.Base			= "weapon_rtbr_base"
SWEP.PrintName		= "#rtbr.weapons.oicw"
SWEP.Category		= "HL2 RP"

if CLIENT then
	SWEP.WepSelectIcon	= surface.GetTextureID("sprites/weapons/oicw.vmt")
end

SWEP.ViewModel		= "models/rtbr/weapons/OICW/c_oicw.mdl"
SWEP.WorldModel		= "models/rtbr/weapons/OICW/w_oicw.mdl"

SWEP.Spawnable		= true
SWEP.Slot			= 2
SWEP.SlotPos		= 4

SWEP.Primary.Ammo			= "5.56x45mm"
SWEP.Primary.ClipSize		= 30
SWEP.Primary.DefaultClip	= 0
SWEP.Primary.ClipMax		= 60 -- for TTT

SWEP.Secondary.Ammo			= "SMG1_Grenade"
SWEP.Secondary.ClipSize		= 2
SWEP.Secondary.DefaultClip	= 0

SWEP.FireRate			= 0.1
SWEP.FireRateScoped		= 0.25
SWEP.BulletSpread		= Vector( 0.02618, 0.02618, 0.02618 )
SWEP.BulletSpreadScoped	= Vector( 0.00873, 0.00873, 0.00873 )
SWEP.BulletDamage		= 8

SWEP.CrosshairX		= 0.5
SWEP.CrosshairY		= 0.0
SWEP.HoldType		= "ar2"

SWEP.ShootSound		= "RTBR.Weapon_OICW.Fire_Player"	-- beware, gets overwritten by Scope function below
SWEP.AltShootSound	= "RTBR.Weapon_OICW.Fire_Alt_Player"
SWEP.DeploySound	= "RTBR.Weapon_OICW.Draw"
SWEP.ZoomInSound	= "RTBR.Weapon_OICW.Zoom_In"
SWEP.ZoomOutSound	= "RTBR.Weapon_OICW.Zoom_Out"
SWEP.DryFireSound	= "Weapon_AR2.Empty"

SWEP.ReadyTimings	= {
	[ACT_VM_DRAW]	= 31/50,
	[ACT_VM_RELOAD]	= 110/50,
	[ACT_VM_RELOAD2] = 109/50,
}
SWEP.ReloadTime		= 50/50
SWEP.ReloadTimeAlt	= 94/50

if CLIENT then
	SWEP.DesiredCrosshairScale = 1.0
	SWEP.OldCrosshairScale = 1.0
	SWEP.CrosshairScaleStartTime = 0.0
	SWEP.CrosshairScaleEndTime = 0.0
end

-- TTT overrides
if engine.ActiveGamemode() == "terrortown" then
	SWEP.PrintName		= "OICW"
	SWEP.Primary.Ammo	= "SMG1"
	SWEP.Kind			= WEAPON_HEAVY
	SWEP.AmmoEnt		= "item_ammo_smg1_ttt"
	SWEP.Icon 			= "VGUI/ttt/icon_rtbr_oicw"
	SWEP.AutoSpawnable	= true
end

local OICW_ACCURACY_RESET_TIME = 0.75
local OICW_MIN_CROSSHAIR_SCALE = 0.5
local OICW_MED_CROSSHAIR_SCALE1 = 0.65
local OICW_MED_CROSSHAIR_SCALE2 = 0.8
local OICW_MAX_CROSSHAIR_SCALE = 1.0
local OICW_MIN_SCALE_TIME = 0.15
local OICW_NORM_SCALE_TIME = 0.05

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)
	self:NetworkVar( "Bool", "IsScoped" )
	self:NetworkVar( "Float", "ScopeTime" )

	if SERVER then
		self:SetIsScoped(false)
		self:SetScopeTime(-1)
	end
end

function SWEP:Holster(wpn)
	self:Descope()
	self:SetCrosshairScale(OICW_MAX_CROSSHAIR_SCALE, 0.0)
	return BaseClass.Holster(self, wpn)
end

function SWEP:GetFireRate()
	if self:GetIsScoped() then
		return self.FireRateScoped
	end

	return self.FireRate
end

function SWEP:GetBulletSpread()
	local cone = self.BulletSpread
	if self:GetIsScoped() then
		local shots = self:GetShotsFired()
		if shots == 0 then
			cone = vector_origin
			self:SetCrosshairScale(OICW_MED_CROSSHAIR_SCALE1, OICW_NORM_SCALE_TIME)
		elseif shots < 3 then
			cone = self.BulletSpreadScoped * 0.25
			if shots == 2 then
				self:SetCrosshairScale(OICW_MED_CROSSHAIR_SCALE2, OICW_NORM_SCALE_TIME)
			end
		elseif shots < 5 then
			cone = self.BulletSpreadScoped * 0.5
			if shots == 4 then
				self:SetCrosshairScale(OICW_MAX_CROSSHAIR_SCALE, OICW_NORM_SCALE_TIME)
			end
		else
			cone = self.BulletSpreadScoped * 1.5
			self:SetCrosshairScale(OICW_MAX_CROSSHAIR_SCALE, OICW_NORM_SCALE_TIME)
		end
	end

	return cone
end

-- dumb hack but i can't really be bothered to do better. BITE ME.
local unscoped_shoot= "RTBR.Weapon_OICW.Fire_Player"
local scoped_shoot	= "RTBR.Weapon_OICW.Fire_Scoped"

function SWEP:ToggleScope()
	if CurTime() < self:GetScopeTime() then return end
	if CurTime() < self:GetNextPrimaryFire() then return end
	if not self:GetIsScoped() then
		self:Scope()
	else
		self:Descope()
	end
	self:SetScopeTime(CurTime() + 0.4)
end

function SWEP:Scope()
	if self:GetIsScoped() then return end

	local owner = self:GetOwner()
	self:SetIsScoped(true)
	owner:SetFOV(30, 0.2)
	self:EmitSound(self.ZoomInSound)
	self.ShootSound = scoped_shoot
	owner:DrawViewModel( false, 0 )
	owner:DrawViewModel( false, 1 )
	owner:SetCanZoom( false )
	owner:ScreenFade( SCREENFADE.IN, color_black, 0.4, 0 )

	self:SetCrosshairScale(OICW_MIN_CROSSHAIR_SCALE, OICW_MIN_SCALE_TIME)
end

function SWEP:Descope()
	if not self:GetIsScoped() then return end

	local owner = self:GetOwner()
	self:SetIsScoped(false)
	owner:SetFOV(0, 0)
	owner:DrawViewModel( true, 0 )
	owner:DrawViewModel( true, 1 )
	owner:SetCanZoom( true )
	self:EmitSound(self.ZoomOutSound)
	if SERVER then owner:StopZooming() end -- prevents suit zoom overlay from getting stuck
	self.ShootSound = unscoped_shoot

	self:SetCrosshairScale(OICW_MAX_CROSSHAIR_SCALE, 0)
end

if engine.ActiveGamemode() == "terrortown" then
	function SWEP:SecondaryAttack()
		self:ToggleScope()
	end
else
	function SWEP:SecondaryAttack()
		if self:GetIsScoped() then return end
		local owner = self:GetOwner()

		if self:Clip2() == 0 then
			self:PlayActivity(ACT_VM_DRYFIRE)
			self:EmitSound(self.DryFireSound)

			self:SetNextSecondaryFire(CurTime() + 0.3)
			self:ReloadSecondary()
			return
		end

		if owner:WaterLevel() == 3 and not self.FiresUnderwater then
			self:EmitSound(self.DryFireSound)
			self:SetNextSecondaryFire(CurTime() + 0.2)
			return
		end

		self:SetClip2(self:Clip2() - 1)

		self:EmitSound(self.AltShootSound)
		self:PlayActivity(ACT_VM_SECONDARYATTACK)
		self:GetOwner():SetAnimation( PLAYER_ATTACK1 )
		self:SetNextSecondaryFire(CurTime() + 0.5)
		self:SetNextPrimaryFire(CurTime() + 0.5)

		if SERVER then
			local angs = owner:EyeAngles() + owner:GetViewPunchAngles()
			local throwvec = angs:Forward() * 1000

			local nade = ents.Create("rtbr_grenade_oicw")
			nade:SetOwner(owner)
			nade:SetPos(owner:GetShootPos())
			nade:SetAngles(angs)
			nade:SetVelocity(throwvec)
			nade:SetLocalAngularVelocity( AngleRand(-400, 400) )
			nade:Spawn()
		end
	end
end

if CLIENT then
	local scopeOverlay = Material( "effects/weapons/oicw_scope" )

	function SWEP:DrawHUD()
		if self:GetIsScoped() then
			render.SetMaterial(scopeOverlay)
			render.DrawScreenQuad()
		end
	end

	function SWEP:CustomAmmoDisplay()
		local display = {
			Draw = true,
			PrimaryClip = self:Clip1(),
			PrimaryAmmo = self:Ammo1(),
			SecondaryAmmo = self:Clip2() + self:Ammo2(),
		}
		return display
	end
end

function SWEP:CanReloadSecondary()
	if self:Clip2() < self:GetMaxClip2() and self:Ammo2() > 0 and CurTime() > self:GetNextPrimaryFire() then return true end
	return false
end

function SWEP:Reload()
	if self:CanReload() then
		self:Descope()
	else
		if self:CanReloadSecondary() then
			self:ReloadSecondary()
			return
		end
	end
	BaseClass.Reload(self)
end

function SWEP:ReloadSecondary()
	if not self:CanReloadSecondary() or self:GetIsReloading() then return end

	self:Descope()

	self:SetIsReloading(true)
	self:PlayActivity(ACT_VM_RELOAD2, true)
	self:GetOwner():SetAnimation( PLAYER_RELOAD )

	local delay = self:SequenceDuration()
	delay = self.ReloadTimeAlt
	self:SetReloadTime(CurTime() + delay)
end

function SWEP:FinishReload()
	if self:GetActivity() == ACT_VM_RELOAD2 then
		local num = self:GetMaxClip2() - self:Clip2()
		num = math.min(num, self:Ammo2())

		self:SetClip2( self:Clip2() + num )
		self:GetOwner():RemoveAmmo(num, self:GetSecondaryAmmoType())
		self:SetIsReloading(false)
		return
	end
	BaseClass.FinishReload(self)
end

function SWEP:GetAccuraryRecoverTime()
	if self:GetIsScoped() then
		return OICW_ACCURACY_RESET_TIME
	end
	return self:GetFireRate()
end

function SWEP:Think()
	self:UpdateCrosshairScale()

	if game.SinglePlayer() and CLIENT then return end

	local owner = self:GetOwner()

	if not self:GetIsReloading() and self:Clip1() == 0 and self:CanReload() then
		self:Reload()
	end

	if self:GetOwner():KeyDown(IN_WEAPON1) then
		self:ToggleScope()
	end

	if self:GetIsReloading() and self:GetReloadTime() <= CurTime() then
		self:FinishReload()
	end

	if self:GetShotsFired() > 0 and CurTime() > self:GetNextPrimaryFire() + self:GetAccuraryRecoverTime() then
		self:SetFireDuration(0)
		self:SetShotsFired(0)
		if self:GetIsScoped() then
			self:SetCrosshairScale(OICW_MIN_CROSSHAIR_SCALE, OICW_MIN_SCALE_TIME)
		end
	end

	self:Idle()
	--BaseClass.Think(self)
end

function SWEP:SetCrosshairScale(scale, time)
	if SERVER then
		if game.SinglePlayer() then
			self:CallOnClient("SetCrosshairScale", string.format("%f:%f", scale, time))
		end
		return
	end

	if type(scale) == "string" then
		local unfuckit = string.Split(scale, ':')
		scale, time = tonumber(unfuckit[1]), tonumber(unfuckit[2])

		if scale == nil or time == nil then
			warn("SWEP:SetCrosshairScale -- something went wrong")
			return
		end
	end

	self.DesiredCrosshairScale = scale
	if time <= 0 then
		self.CrosshairScale = scale
		self.OldCrosshairScale = scale
		self.CrosshairScaleStartTime = CurTime()
		self.CrosshairScaleEndTime = CurTime()
	else
		self.OldCrosshairScale = self.CrosshairScale
		self.CrosshairScaleStartTime = CurTime()
		self.CrosshairScaleEndTime = CurTime() + time
	end
end

function SWEP:UpdateCrosshairScale()
	if not CLIENT then return end

	if self.CrosshairScale == self.DesiredCrosshairScale then return end

	local s = math.Remap(math.min(CurTime(), self.CrosshairScaleEndTime),
						self.CrosshairScaleStartTime,
						self.CrosshairScaleEndTime,
						self.OldCrosshairScale,
						self.DesiredCrosshairScale)

	self.CrosshairScale = s
end

function SWEP:ApplyViewKick()
	local vertical_kick = 1.0
	local slide_limit	= 2.0

	if self:GetIsScoped() then
		vertical_kick	= 0.1
		slide_limit		= 0.2
	end

	self:DoMachineGunKick(vertical_kick, self:GetFireDuration(), slide_limit)
end
