AddCSLuaFile()

-- ============================================================
-- Shared
-- ============================================================

SWEP.PrintName       = "Cigarette"
SWEP.Author          = "AeroMatix | Ported by Frosty"
SWEP.Category        = "HL2 RP"
SWEP.Slot            = 1
SWEP.SlotPos         = 0
SWEP.BounceWeaponIcon = false

SWEP.ViewModelFOV    = 62
SWEP.ViewModel       = "models/oldcigshib.mdl"
SWEP.WorldModel      = "models/oldcigshib.mdl"
SWEP.Spawnable       = true
SWEP.AdminOnly       = false

SWEP.Primary.Clipsize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = true
SWEP.Primary.Ammo        = "none"

SWEP.Secondary.Clipsize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

SWEP.DrawAmmo    = false
SWEP.HoldType    = "slam"
SWEP.cigaID      = 1

function SWEP:Deploy()
	self:SetHoldType("slam")
end

function SWEP:SecondaryAttack() end

function SWEP:Initialize()
	if not self.CigaInitialized then
		self.CigaInitialized = true
		self.VElements = {
			["ciga"] = {
				type = "Model", model = self.ViewModel,
				bone = "ValveBiped.Bip01_Spine4", rel = "",
				pos = Vector(-7.1, -2.401, 23.377),
				angle = Angle(111.039, 10.519, 0),
				size = Vector(1, 1, 1), color = Color(255, 255, 255, 255),
				surpresslightning = false, material = "", skin = 0, bodygroup = {}
			}
		}
		self.OldCigaModel    = self.ViewModel
		self.ViewModel       = "models/weapons/c_slam.mdl"
		self.UseHands        = true
		self.ViewModelFlip   = true
		self.ShowViewModel   = true
		self.ShowWorldModel  = true
		self.ViewModelBoneMods = {
			["ValveBiped.Bip01_L_Finger1"]   = { scale = Vector(1,1,1), pos = Vector(0,0,0), angle = Angle(-23.334,-12.223,-32.223) },
			["ValveBiped.Bip01_L_Finger12"]  = { scale = Vector(1,1,1), pos = Vector(0,0,0), angle = Angle(0,-21.112,0) },
			["ValveBiped.Bip01_L_Finger4"]   = { scale = Vector(1,1,1), pos = Vector(0,0,0), angle = Angle(0,-65.556,0) },
			["ValveBiped.Bip01_R_UpperArm"]  = { scale = Vector(1,1,1), pos = Vector(0,0,0), angle = Angle(0,72.222,-41.112) },
			["ValveBiped.Bip01_L_Finger0"]   = { scale = Vector(1,1,1), pos = Vector(0,0,0), angle = Angle(10,1.11,-1.111) },
			["Detonator"]                    = { scale = Vector(0.009,0.009,0.009), pos = Vector(0,0,0), angle = Angle(0,0,0) },
			["ValveBiped.Bip01_L_Hand"]      = { scale = Vector(1,1,1), pos = Vector(0,0,0), angle = Angle(-27.778,1.11,-7.778) },
			["Slam_panel"]                   = { scale = Vector(0.009,0.009,0.009), pos = Vector(0,0,0), angle = Angle(0,0,0) },
			["ValveBiped.Bip01_L_Finger2"]   = { scale = Vector(1,1,1), pos = Vector(0,0,0), angle = Angle(0,-47.778,0) },
			["ValveBiped.Bip01_L_Finger3"]   = { scale = Vector(1,1,1), pos = Vector(0,0,0), angle = Angle(0,-43.334,0) },
			["Slam_base"]                    = { scale = Vector(0.009,0.009,0.009), pos = Vector(0,0,0), angle = Angle(0,0,0) },
			["ValveBiped.Bip01_R_Hand"]      = { scale = Vector(0.009,0.009,0.009), pos = Vector(0,0,0), angle = Angle(0,0,0) },
		}
	end

	if CLIENT then
		self.VElements          = table.FullCopy(self.VElements)
		self.WElements          = table.FullCopy(self.WElements)
		self.ViewModelBoneMods  = table.FullCopy(self.ViewModelBoneMods)

		self:CreateModels(self.VElements)
		self:CreateModels(self.WElements)

		if IsValid(self.Owner) then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
				if self.ShowViewModel == nil or self.ShowViewModel then
					vm:SetColor(Color(255,255,255,255))
				else
					vm:SetColor(Color(255,255,255,1))
					vm:SetMaterial("Debug/hsv")
				end
			end
		end
	end

	if self.Initialize2 then self:Initialize2() end
end

function SWEP:PrimaryAttack()
	if SERVER then
		cigaUpdate(self.Owner, self.cigaID)
	end
	self.Weapon:SetNextPrimaryFire(CurTime() + 0.1)
end

function SWEP:Reload() end

function SWEP:Holster()
	if SERVER and IsValid(self.Owner) then
		Releaseciga(self.Owner)
	end
	if CLIENT and IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then self:ResetBonePositions(vm) end
	end
	return true
end

SWEP.OnDrop   = SWEP.Holster
SWEP.OnRemove = SWEP.Holster

-- ============================================================
-- Server
-- ============================================================

if SERVER then
	util.AddNetworkString("ciga")
	util.AddNetworkString("cigaArm")
	util.AddNetworkString("cigaTalking")

	function cigaUpdate(ply, cigaID)
		if not ply.cigaCount then ply.cigaCount = 0 end
		if not ply.cantStartciga then ply.cantStartciga = false end
		if ply.cigaCount == 0 and ply.cantStartciga then return end

		ply.cigaID    = cigaID
		ply.cigaCount = ply.cigaCount + 1

		if ply.cigaCount == 1 then
			ply.cigaArm = true
			net.Start("cigaArm")
			net.WriteEntity(ply)
			net.WriteBool(true)
			net.Broadcast()
		end

		if ply.cigaCount >= 50 then
			ply.cantStartciga = true
			Releaseciga(ply)
		end
	end

	hook.Add("KeyRelease", "DocigaHook", function(ply, key)
		if key == IN_ATTACK then
			Releaseciga(ply)
			ply.cantStartciga = false
		end
	end)

	function Releaseciga(ply)
		if not ply.cigaCount then ply.cigaCount = 0 end
		if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass():sub(1,11) == "ix_cigarette" then
			if ply.cigaCount >= 5 then
				net.Start("ciga")
				net.WriteEntity(ply)
				net.WriteInt(ply.cigaCount, 8)
				net.WriteInt(ply.cigaID + (ply:GetActiveWeapon().juiceID or 0), 8)
				net.Broadcast()
			end
		end
		if ply.cigaArm then
			ply.cigaArm = false
			net.Start("cigaArm")
			net.WriteEntity(ply)
			net.WriteBool(false)
			net.Broadcast()
		end
		ply.cigaCount = 0
	end
end

-- ============================================================
-- Client
-- ============================================================

if CLIENT then

	if not cigaParticleEmitter then
		cigaParticleEmitter = ParticleEmitter(Vector(0,0,0))
	end

	-- --------------------------------------------------------
	-- World model: attach cigarette to hand or head bone
	-- --------------------------------------------------------
	function SWEP:DrawWorldModel()
		local ply = self:GetOwner()
		local cigaScale = self.cigaScale or 1
		self:SetModelScale(cigaScale, 0)
		self:SetSubMaterial()

		if IsValid(ply) then
			local bn = "ValveBiped.Bip01_R_Hand"
			if ply.cigaArmFullyUp then bn = "ValveBiped.Bip01_Head1" end
			local bon = ply:LookupBone(bn) or 0

			local opos = self:GetPos()
			local oang = self:GetAngles()
			local bp, ba = ply:GetBonePosition(bon)
			if bp then opos = bp end
			if ba then oang = ba end

			if ply.cigaArmFullyUp then
				-- head position
				opos = opos + (oang:Forward()*0.95) + (oang:Right()*7) + (oang:Up()*0.035)
				oang:RotateAroundAxis(oang:Forward(), -100)
				oang:RotateAroundAxis(oang:Up(), 100)
				opos = opos + (oang:Up()*(cigaScale-1)*-10.25)
			else
				-- hand position
				oang:RotateAroundAxis(oang:Forward(), 50)
				oang:RotateAroundAxis(oang:Right(), 90)
				opos = opos + (oang:Forward()*2) + (oang:Up()*-4.5) + (oang:Right()*-2)
				oang:RotateAroundAxis(oang:Forward(), 90)
				oang:RotateAroundAxis(oang:Up(), 10)
				opos = opos + (oang:Up()*(cigaScale-1)*-10.25)
				opos = opos + (oang:Up()*2)
				opos = opos + (oang:Right()*0.5)
				opos = opos + (oang:Forward()*-1.5)
			end

			self:SetupBones()
			local mrt = self:GetBoneMatrix(0)
			if mrt then
				mrt:SetTranslation(opos)
				mrt:SetAngles(oang)
				self:SetBoneMatrix(0, mrt)
			end
		end
		self:DrawModel()
	end

	-- --------------------------------------------------------
	-- View model: animate toward mouth when inhaling
	-- --------------------------------------------------------
	function SWEP:GetViewModelPosition(pos, ang)
		local vmpos1 = self.cigaVMPos1 or Vector(18.5,-3.4,-3.25)
		local vmang1 = self.cigaVMAng1 or Vector(170,-180,20)
		local vmpos2 = self.cigaVMPos2 or Vector(24,-8,-11.2)
		local vmang2 = self.cigaVMAng2 or Vector(120,-180,150)

		if not LocalPlayer().cigaArmTime then LocalPlayer().cigaArmTime = 0 end
		local lerp = math.Clamp((os.clock()-LocalPlayer().cigaArmTime)*3, 0, 1)
		if LocalPlayer().cigaArm then lerp = 1-lerp end

		local difvec  = Vector(-10,-3.5,-12)
		local orig    = Vector(0,0,0)
		local topos   = orig+difvec
		local difang  = Vector(-30,0,0)
		local origang = Vector(0,0,0)
		local toang   = origang+difang

		local newpos = LerpVector(lerp, topos, orig)
		local newang = LerpVector(lerp, toang, origang)
		newang = Angle(newang.x, newang.y, newang.z)
		pos, ang = LocalToWorld(newpos, newang, pos, ang)
		return pos, ang
	end

	-- --------------------------------------------------------
	-- Dynamic 2-bone IK: automatically aims the right arm toward
	-- the character's mouth regardless of model or animation pose.
	--
	-- Steps:
	--   1. Reset bone manipulations to sample natural rest positions.
	--   2. Locate the mouth from the head bone (forward+down offset).
	--   3. Solve shoulder→elbow→mouth with law-of-cosines IK.
	--   4. Convert the desired world-space bone directions into
	--      ManipulateBoneAngles deltas (target − natural), lerped by mult.
	-- --------------------------------------------------------
	function ciga_interpolate_arm(ply, mult, mouth_delay)
		if not IsValid(ply) then return end

		if mouth_delay > 0 then
			timer.Simple(mouth_delay, function()
				if IsValid(ply) then ply.cigaMouthOpenAmt = mult end
			end)
		else
			ply.cigaMouthOpenAmt = mult
		end

		local b_upper = ply:LookupBone("ValveBiped.Bip01_R_UpperArm")
		local b_fore  = ply:LookupBone("ValveBiped.Bip01_R_Forearm")
		if not b_upper or not b_fore then return end

		if mult == 0 then
			ply:ManipulateBoneAngles(b_upper, Angle(0,0,0))
			ply:ManipulateBoneAngles(b_fore,  Angle(0,0,0))
			ply.cigaArmFullyUp = false
			return
		end

		ply.cigaArmFullyUp = (mult == 1)

		-- Reset to sample the animation's natural bone positions
		ply:ManipulateBoneAngles(b_upper, Angle(0,0,0))
		ply:ManipulateBoneAngles(b_fore,  Angle(0,0,0))

		local b_head = ply:LookupBone("ValveBiped.Bip01_Head1")
		local b_hand = ply:LookupBone("ValveBiped.Bip01_R_Hand")
		if not b_head then return end

		local matU = ply:GetBoneMatrix(b_upper)
		local matF = ply:GetBoneMatrix(b_fore)
		local matH = ply:GetBoneMatrix(b_head)
		if not matU or not matF or not matH then return end

		local shoulderPos    = matU:GetTranslation()
		local elbowPos       = matF:GetTranslation()
		local headPos        = matH:GetTranslation()
		local headAng        = matH:GetAngles()
		local naturalUpperAng = matU:GetAngles()
		local naturalForeAng  = matF:GetAngles()

		-- Bone segment lengths (constant per model)
		local upperLen = (elbowPos - shoulderPos):Length()
		local foreLen
		if b_hand then
			local matHand = ply:GetBoneMatrix(b_hand)
			foreLen = matHand and (matHand:GetTranslation() - elbowPos):Length() or upperLen * 0.9
		else
			foreLen = upperLen * 0.9
		end

		-- Mouth position: forward and down from the head bone center
		-- headAng:Forward() = direction face looks; Right() = character's right
		local mouthPos = headPos
			+ headAng:Forward() * 5
			+ headAng:Right()   * 2
			+ headAng:Up()      * -4

		-- Vector from shoulder to mouth
		local toMouth = mouthPos - shoulderPos
		local dist    = math.Clamp(toMouth:Length(),
			math.abs(upperLen - foreLen) + 0.1,
			upperLen + foreLen - 0.1)
		local toMouthDir = toMouth:GetNormalized()

		-- Law of cosines: angle at shoulder between (shoulder→mouth) and (shoulder→elbow)
		local cosUpper = math.Clamp(
			(upperLen^2 + dist^2 - foreLen^2) / (2 * upperLen * dist), -1, 1)
		local elbowBendAngle = math.deg(math.acos(cosUpper))

		-- Elbow hint: bend the elbow outward (away from body, right arm = player right)
		local plyRight = ply:GetAngles():Right()
		local hintVec  = plyRight - toMouthDir * plyRight:Dot(toMouthDir)
		if hintVec:LengthSqr() < 0.001 then
			local up = ply:GetAngles():Up()
			hintVec = up - toMouthDir * up:Dot(toMouthDir)
		end
		hintVec:Normalize()

		-- Rodrigues rotation: rotate toMouthDir by elbowBendAngle around hintVec
		local cosA = math.cos(math.rad(elbowBendAngle))
		local sinA = math.sin(math.rad(elbowBendAngle))
		local elbowDir = toMouthDir * cosA
			+ hintVec:Cross(toMouthDir) * sinA
			+ hintVec * (hintVec:Dot(toMouthDir) * (1 - cosA))
		elbowDir:Normalize()

		-- Target world-space angles for upper arm (preserve natural roll)
		local targetUpperAng   = elbowDir:Angle()
		targetUpperAng.r       = naturalUpperAng.r

		-- Angle delta, lerped by mult
		local deltaUpper = Angle(
			(targetUpperAng.p - naturalUpperAng.p) * mult,
			(targetUpperAng.y - naturalUpperAng.y) * mult,
			0)
		ply:ManipulateBoneAngles(b_upper, deltaUpper)

		-- Forearm: point from IK elbow toward mouth
		local targetElbowPos = shoulderPos + elbowDir * upperLen
		local foreDir        = (mouthPos - targetElbowPos):GetNormalized()
		local targetForeAng  = foreDir:Angle()
		targetForeAng.r      = naturalForeAng.r

		local deltaFore = Angle(
			(targetForeAng.p - naturalForeAng.p) * mult,
			(targetForeAng.y - naturalForeAng.y) * mult,
			0)
		ply:ManipulateBoneAngles(b_fore, deltaFore)
	end

	-- --------------------------------------------------------
	-- Sound
	-- --------------------------------------------------------
	sound.Add({
		name    = "ciga_inhale",
		channel = CHAN_WEAPON,
		volume  = 0.24,
		level   = 60,
		pitch   = { 95 },
		sound   = "cigainhale.wav",
	})

	-- --------------------------------------------------------
	-- Net receivers
	-- --------------------------------------------------------
	net.Receive("ciga", function()
		local ply = net.ReadEntity()
		local amt = net.ReadInt(8)
		local fx  = net.ReadInt(8)
		if not IsValid(ply) then return end

		if amt >= 50 then
			ply:EmitSound("cigacough1.wav", 90)
			for i = 1, 200 do
				local d = i+10
				if i > 140 then d = d+150 end
				timer.Simple((d-1)*0.003, function() ciga_do_pulse(ply, 1, 100, fx) end)
			end
			return
		elseif amt >= 35 then
			ply:EmitSound("cigabreath2.wav", 75, 100, 0.7)
		elseif amt >= 10 then
			ply:EmitSound("cigabreath1.wav", 70, 130-math.min(100,amt*2), 0.4+(amt*0.005))
		end

		for i = 1, amt*2 do
			timer.Simple((i-1)*0.02, function()
				ciga_do_pulse(ply, math.floor(((amt*2)-i)/10), fx==2 and 100 or 0, fx)
			end)
		end
	end)

	net.Receive("cigaArm", function()
		local ply = net.ReadEntity()
		local z   = net.ReadBool()
		if not IsValid(ply) then return end
		if ply.cigaArm != z then
			if z then
				timer.Simple(0.3, function()
					if not IsValid(ply) then return end
					if ply.cigaArm then ply:EmitSound("ciga_inhale") end
				end)
			else
				ply:StopSound("ciga_inhale")
			end
			ply.cigaArm     = z
			ply.cigaArmTime = os.clock()
			local m = z and 1 or 0

			for i = 0, 9 do
				timer.Simple(i/30, function()
					ciga_interpolate_arm(ply, math.abs(m-((9-i)/10)), z and 0 or 0.2)
				end)
			end
		end
	end)

	net.Receive("cigaTalking", function()
		local ply = net.ReadEntity()
		if IsValid(ply) then ply.cigaTalkingEndtime = net.ReadFloat() end
	end)

	-- --------------------------------------------------------
	-- Mouth animation hook (non-destructive patch)
	-- --------------------------------------------------------
	hook.Add("InitPostEntity", "cigaMouthMoveSetup", function()
		timer.Simple(1, function()
			if ciga_OriginalMouthMove ~= nil then return end
			ciga_OriginalMouthMove = GAMEMODE.MouthMoveAnimation

			function GAMEMODE:MouthMoveAnimation(ply)
				if ((ply.cigaMouthOpenAmt or 0) == 0) and ((ply.cigaTalkingEndtime or 0) < CurTime()) then
					return ciga_OriginalMouthMove(GAMEMODE, ply)
				end
				local FlexNum = ply:GetFlexNum() - 1
				if FlexNum <= 0 then return end
				for i = 0, FlexNum-1 do
					local Name = ply:GetFlexName(i)
					if Name=="jaw_drop" or Name=="right_part" or Name=="left_part"
					or Name=="right_mouth_drop" or Name=="left_mouth_drop" then
						ply:SetFlexWeight(i, math.max(
							((ply.cigaMouthOpenAmt or 0)*0.5),
							math.Clamp(((ply.cigaTalkingEndtime or 0)-CurTime())*3.0,0,1)*math.Rand(0.1,0.8)
						))
					end
				end
			end
		end)
	end)

	-- --------------------------------------------------------
	-- Smoke particles
	-- --------------------------------------------------------
	function ciga_do_pulse(ply, amt, spreadadd, fx)
		if not IsValid(ply) then return end
		if ply:WaterLevel() == 3 then return end
		if not spreadadd then spreadadd = 0 end

		local attachid = ply:LookupAttachment("eyes")
		cigaParticleEmitter:SetPos(LocalPlayer():GetPos())

		local angpos = ply:GetAttachment(attachid) or {Ang=Angle(0,0,0), Pos=Vector(0,0,0)}
		local fwd, pos

		if ply != LocalPlayer() then
			fwd = (angpos.Ang:Forward()-angpos.Ang:Up()):GetNormalized()
			pos = angpos.Pos + (fwd*3.5)
		else
			fwd = ply:GetAimVector():GetNormalized()
			pos = ply:GetShootPos() + fwd*1.5 + gui.ScreenToVector(ScrW()/2, ScrH())*5
		end
		fwd = ply:GetAimVector():GetNormalized()

		for i = 1, amt do
			if not IsValid(ply) then return end
			local particle = cigaParticleEmitter:Add(
				string.format("particle/smokesprites_00%02d", math.random(7,16)), pos)
			if particle then
				local dir = VectorRand():GetNormalized() * ((amt+5)/10)
				ciga_do_particle(particle,
					(ply:GetVelocity()*0.25) + (((fwd*9)+dir):GetNormalized() * math.Rand(50,80) * (amt+1) * 0.2),
					fx)
			end
		end
	end

	function ciga_do_particle(particle, vel, fx)
		particle:SetColor(255,255,255,255)
		if fx == 3 then particle:SetColor(100,100,100,100) end
		if fx >= 4 then
			local c = JuicycigaJuices and JuicycigaJuices[fx-3] and JuicycigaJuices[fx-3].color
			if not c then c = HSVToColor(math.random(0,359),1,1) end
			particle:SetColor(c.r, c.g, c.b, 255)
		end

		local mega = (fx == 2) and 4 or 1
		mega = mega * 0.3

		particle:SetVelocity(vel*mega)
		particle:SetGravity(Vector(0,0,1.5))
		particle:SetLifeTime(0)
		particle:SetDieTime(math.Rand(80,100)*0.11*mega)
		particle:SetStartSize(3*mega)
		particle:SetEndSize(40*mega*mega)
		particle:SetStartAlpha(150)
		particle:SetEndAlpha(0)
		particle:SetCollide(true)
		particle:SetBounce(0.25)
		particle:SetRoll(math.Rand(0,360))
		particle:SetRollDelta(0.01*math.Rand(-40,40))
		particle:SetAirResistance(50)
	end

	-- --------------------------------------------------------
	-- SWEP Construction Kit rendering helpers
	-- --------------------------------------------------------

	SWEP.vRenderOrder = nil

	function SWEP:ViewModelDrawn()
		local vm = self.Owner:GetViewModel()
		if not IsValid(vm) then return end
		if not self.VElements then return end

		self:UpdateBonePositions(vm)

		if not self.vRenderOrder then
			self.vRenderOrder = {}
			for k, v in pairs(self.VElements) do
				if v.type == "Model" then
					table.insert(self.vRenderOrder, 1, k)
				elseif v.type == "Sprite" or v.type == "Quad" then
					table.insert(self.vRenderOrder, k)
				end
			end
		end

		for _, name in ipairs(self.vRenderOrder) do
			local v = self.VElements[name]
			if not v then self.vRenderOrder = nil break end
			if v.hide then continue end

			local model  = v.modelEnt
			local sprite = v.spriteMaterial
			if not v.bone then continue end

			local pos, ang = self:GetBoneOrientation(self.VElements, v, vm)
			if not pos then continue end

			if v.type == "Model" and IsValid(model) then
				model:SetPos(pos + ang:Forward()*v.pos.x + ang:Right()*v.pos.y + ang:Up()*v.pos.z)
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				model:SetAngles(ang)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix("RenderMultiply", matrix)
				if v.material == "" then
					model:SetMaterial("")
				elseif model:GetMaterial() != v.material then
					model:SetMaterial(v.material)
				end
				if v.skin and v.skin != model:GetSkin() then model:SetSkin(v.skin) end
				if v.bodygroup then
					for bk, bv in pairs(v.bodygroup) do
						if model:GetBodygroup(bk) != bv then model:SetBodygroup(bk, bv) end
					end
				end
				if v.surpresslightning then render.SuppressEngineLighting(true) end
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1,1,1)
				if v.surpresslightning then render.SuppressEngineLighting(false) end

			elseif v.type == "Sprite" and sprite then
				local drawpos = pos + ang:Forward()*v.pos.x + ang:Right()*v.pos.y + ang:Up()*v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)

			elseif v.type == "Quad" and v.draw_func then
				local drawpos = pos + ang:Forward()*v.pos.x + ang:Right()*v.pos.y + ang:Up()*v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func(self)
				cam.End3D2D()
			end
		end
	end

	function SWEP:GetBoneOrientation(basetab, tab, ent, bone_override)
		local pos, ang
		if tab.rel and tab.rel != "" then
			local v = basetab[tab.rel]
			if not v then return end
			pos, ang = self:GetBoneOrientation(basetab, v, ent)
			if not pos then return end
			pos = pos + ang:Forward()*v.pos.x + ang:Right()*v.pos.y + ang:Up()*v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
		else
			local bone = ent:LookupBone(bone_override or tab.bone)
			if not bone then return end
			pos, ang = Vector(0,0,0), Angle(0,0,0)
			local m = ent:GetBoneMatrix(bone)
			if m then pos, ang = m:GetTranslation(), m:GetAngles() end
			if IsValid(self.Owner) and self.Owner:IsPlayer()
			and ent == self.Owner:GetViewModel() and self.ViewModelFlip then
				ang.r = -ang.r
			end
		end
		return pos, ang
	end

	function SWEP:CreateModels(tab)
		if not tab then return end
		for _, v in pairs(tab) do
			if v.type == "Model" and v.model and v.model != ""
			and (not IsValid(v.modelEnt) or v.createdModel != v.model)
			and string.find(v.model, ".mdl") and file.Exists(v.model, "GAME") then
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if IsValid(v.modelEnt) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else
					v.modelEnt = nil
				end
			elseif v.type == "Sprite" and v.sprite and v.sprite != ""
			and (not v.spriteMaterial or v.createdSprite != v.sprite)
			and file.Exists("materials/"..v.sprite..".vmt", "GAME") then
				local name   = v.sprite.."-"
				local params = { ["$basetexture"] = v.sprite }
				for _, j in pairs({"nocull","additive","vertexalpha","vertexcolor","ignorez"}) do
					if v[j] then params["$"..j] = 1; name = name.."1"
					else name = name.."0" end
				end
				v.createdSprite  = v.sprite
				v.spriteMaterial = CreateMaterial(name, "UnlitGeneric", params)
			end
		end
	end

	local allbones
	local hasGarryFixedBoneScalingYet = false

	function SWEP:UpdateBonePositions(vm)
		if not self.ViewModelBoneMods then self:ResetBonePositions(vm) return end
		if not vm:GetBoneCount() then return end

		local loopthrough = self.ViewModelBoneMods
		if not hasGarryFixedBoneScalingYet then
			allbones = {}
			for i = 0, vm:GetBoneCount() do
				local bonename = vm:GetBoneName(i)
				allbones[bonename] = self.ViewModelBoneMods[bonename]
					or { scale=Vector(1,1,1), pos=Vector(0,0,0), angle=Angle(0,0,0) }
			end
			loopthrough = allbones
		end

		for k, v in pairs(loopthrough) do
			local bone = vm:LookupBone(k)
			if not bone then continue end
			local s  = Vector(v.scale.x, v.scale.y, v.scale.z)
			local p  = Vector(v.pos.x, v.pos.y, v.pos.z)
			local ms = Vector(1,1,1)
			if not hasGarryFixedBoneScalingYet then
				local cur = vm:GetBoneParent(bone)
				while cur >= 0 do
					local pscale = loopthrough[vm:GetBoneName(cur)].scale
					ms  = ms * pscale
					cur = vm:GetBoneParent(cur)
				end
			end
			s = s * ms
			if vm:GetManipulateBoneScale(bone) != s then vm:ManipulateBoneScale(bone, s) end
			if vm:GetManipulateBoneAngles(bone) != v.angle then vm:ManipulateBoneAngles(bone, v.angle) end
			if vm:GetManipulateBonePosition(bone) != p then vm:ManipulateBonePosition(bone, p) end
		end
	end

	function SWEP:ResetBonePositions(vm)
		if not vm:GetBoneCount() then return end
		for i = 0, vm:GetBoneCount() do
			vm:ManipulateBoneScale(i, Vector(1,1,1))
			vm:ManipulateBoneAngles(i, Angle(0,0,0))
			vm:ManipulateBonePosition(i, Vector(0,0,0))
		end
	end

	-- table.FullCopy utility (safe re-definition)
	if not table.FullCopy then
		function table.FullCopy(tab)
			if not tab then return nil end
			local res = {}
			for k, v in pairs(tab) do
				if type(v) == "table" then
					res[k] = table.FullCopy(v)
				elseif type(v) == "Vector" then
					res[k] = Vector(v.x, v.y, v.z)
				elseif type(v) == "Angle" then
					res[k] = Angle(v.p, v.y, v.r)
				else
					res[k] = v
				end
			end
			return res
		end
	end

end -- CLIENT
