if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
end

if (CLIENT) then
	SWEP.Slot = 5;
	SWEP.SlotPos = 5;
	SWEP.DrawAmmo = false;
	SWEP.PrintName = "Heal Ability";
	SWEP.DrawCrosshair = true;
	SWEP.Instructions = "Primary Fire: Heal"
	SWEP.Purpose = "To healing people."
end

SWEP.Author					= "JohnyReaper"

SWEP.Contact 				= ""

SWEP.Category				= "Vort Swep" 
SWEP.Slot					= 5
SWEP.SlotPos				= 5
SWEP.Weight					= 5
SWEP.Spawnable     			= true
SWEP.AdminSpawnable		= false;
SWEP.ViewModel 			= ""
SWEP.WorldModel 			= ""
SWEP.HoldType 				= "heal"

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
	self.NextNotifyTime = 0 -- Cooldown for notification spam
end

function SWEP:Deploy()
	if (SERVER) then
		-- Hide viewmodel and keep weapon raised
		self.Owner:DrawViewModel(false)
		self.Owner:SetNWBool("ixRaised", true)
	
		if (!self.HealSound) then
			self.HealSound = CreateSound( self.Weapon, "npc/vort/health_charge.wav" );
		end
	end

	return true
end

function SWEP:Holster()
	return true
end


function SWEP:OnRemove()
	return true
end

function SWEP:DispatchEffect(EFFECTSTR)
	local pPlayer=self.Owner;
	if !pPlayer then return end
	local view;
	if CLIENT then view=GetViewEntity() else view=pPlayer:GetViewEntity() end
		if ( !pPlayer:IsNPC() && view:IsPlayer() ) then
			ParticleEffectAttach( EFFECTSTR, PATTACH_POINT_FOLLOW, pPlayer, pPlayer:LookupAttachment( "leftclaw" ) );
		else
			ParticleEffectAttach( EFFECTSTR, PATTACH_POINT_FOLLOW, pPlayer, pPlayer:LookupAttachment( "leftclaw" ) );
		end
end


function SWEP:PrimaryAttack()
	
	if (!self.Owner:Alive()) then return false end
	if (!self.Owner:GetCharacter():IsVortigaunt()) then return false end

	-- self.Owner:SetAnimation( PLAYER_ATTACK1 )

	local eye = self.Owner:GetEyeTrace()
	local target = eye.Entity
	local bIsPlayer = target:IsPlayer()
	local bIsRagdoll = target:GetClass() == "prop_ragdoll"
	local ply = bIsRagdoll and target:GetNetVar("player")

	if (!bIsPlayer and !(bIsRagdoll and IsValid(ply) and !ply:Alive())) then return end
	
	if self.Owner:Health() <= 50 then
		if (SERVER) and CurTime() > (self.NextNotifyTime or 0) then
			self.Owner:NotifyLocalized("tooWeakToHeal")
			self.NextNotifyTime = CurTime() + 2
		end
		return
	end
	
	-- Check stamina
	local stmCost = (bIsRagdoll and IsValid(ply) and !ply:Alive()) and 40 or 20
	if self.Owner:GetLocalVar("stm", 0) < stmCost then
		if (SERVER) and CurTime() > (self.NextNotifyTime or 0) then
			self.Owner:NotifyLocalized("notEnoughStamina")
			self.NextNotifyTime = CurTime() + 2
		end
		return
	end

	if target:GetPos():Distance(self.Owner:GetShootPos()) > 105 then return end

	if bIsPlayer and target:Health() >= target:GetMaxHealth() then
		if (SERVER) and CurTime() > (self.NextNotifyTime or 0) then
			self.Owner:NotifyLocalized("targetFullHealth")
			self.NextNotifyTime = CurTime() + 2
		end
		return
	end

	self:DispatchEffect("vortigaunt_charge_token")

	if (SERVER) then
		self.Owner:ForceSequence("heal_cycle")
		self.Owner:EmitSound( "npc/vort/health_charge.wav", 100, 150, 1, CHAN_AUTO )
		self.Owner:Freeze(true)
	end

	timer.Simple(2, function() 
		if (!IsValid(self) or !IsValid(self.Owner) or !self.Owner:Alive()) then return end
		
		if (SERVER) then
			self.Owner:StopSound("npc/vort/health_charge.wav") 
			self.Owner:Freeze(false)
			self.Owner:StopParticles()

			if IsValid(target) and target:GetPos():Distance(self.Owner:GetShootPos()) <= 105 then
				if (target:IsPlayer() and target:Alive()) then
					local randomNum = math.random(ix.config.Get("VortHealMin", 5), ix.config.Get("VortHealMax", 20))
					target:SetHealth(math.Clamp(target:Health() + randomNum, 0, target:GetMaxHealth()))
					
					self.Owner:ConsumeStamina(20)
				elseif (bIsRagdoll and IsValid(ply) and !ply:Alive()) then
					-- Revive logic
					local pos = target:GetPos()
					local angles = target:GetAngles()

					target.ixIsReviving = true
					ply.ixIsReviving = true
					ply:Spawn()

					timer.Simple(0, function()
						if (IsValid(ply)) then
							local revivePos = pos
							local playerMins = ply:OBBMins()
							local playerMaxs = ply:OBBMaxs()

							local function IsSafe(checkPos)
								local trace = {
									start = checkPos,
									endpos = checkPos,
									filter = {ply, target},
									mins = playerMins,
									maxs = playerMaxs,
									mask = MASK_PLAYERSOLID
								}
								return !util.TraceEntity(trace, ply).StartSolid
							end

							if (!IsSafe(revivePos)) then
								local found = false
								for i = 1, 3 do
									local distance = i * 32
									for j = 0, 7 do
										local ang = j * 45
										local rad = math.rad(ang)
										local offset = Vector(math.cos(rad) * distance, math.sin(rad) * distance, 8)
										local testPos = pos + offset

										if (IsSafe(testPos)) then
											revivePos = testPos
											found = true
											break
										end
									end
									if (found) then break end
								end
							else
								revivePos = revivePos + Vector(0, 0, 8)
							end

							ply:SetPos(revivePos)
							ply:SetEyeAngles(Angle(0, angles.y, 0))
							ply:SetHealth(25)

							if (target:GetNetVar("ixRestricted")) then
								ply:SetRestricted(true)
							end
						end
					end)

					self.Owner:ConsumeStamina(40) -- Revive costs more stamina

					target:Remove()
				end
			end	
		end
	end)
	self:SetNextPrimaryFire( CurTime() + 3 )

end;


function SWEP:SecondaryAttack()
	return false
end