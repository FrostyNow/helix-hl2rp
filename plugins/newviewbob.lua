local PLUGIN = PLUGIN
PLUGIN.name = 'ViewBob'
PLUGIN.schema = 'Any'
PLUGIN.version = 1.0

ix.lang.AddTable("english", {
	optCbobIntensity = "ViewBob Intensity",
	optdCbobIntensity = "How much to adjust natural character head bobing intensity.",
	optCbobCompensation = "ViewBob Compensation",
	optdCbobCompensation = "How much to compensate rotation during movement.",
	optEnablevbob = "ViewBob 활성화",
	optdEnablevbob = "일인칭 시점의 머리 흔들림 기능을 켭니다."
})

ix.lang.AddTable("korean", {
	["ViewBob"] = "머리 흔들림",
	optCbobIntensity = "머리 흔들림 강도",
	optdCbobIntensity = "일인칭 시점에서 머리 흔들림의 강도를 조절합니다.",
	optCbobCompensation = "머리 흔들림 보정",
	optdCbobCompensation = "움직임 중 회전 보정 정도를 조절합니다.",
	optEnablevbob = "머리 흔들림 활성화",
	optdEnablevbob = "일인칭 시점의 머리 흔들림 기능을 켭니다."
})

if CLIENT then
	local ViewBobTime = 0
	local ViewBobIntensity = 1
	local BobEyeFocus = 512
	local rateScaleFac = math.pi
	local rate_up = 4 * rateScaleFac
	local scale_up = 0.3
	local rate_right = 2 * rateScaleFac
	local scale_right = 0.3
	local LastCalcViewBob = 0
	local sv_cheats_cv = GetConVar("sv_cheats")
	local host_timescale_cv = GetConVar("host_timescale")
	local AngularCompensation = 1
	local MinimumFocus = 128

	ix.option.Add("cbobIntensity", ix.type.number, 1, {
		category = "ViewBob", min = 0.1, max = 1, decimals = 1
	})

	ix.option.Add("cbobCompensation", ix.type.number, 1, {
		category = "ViewBob", min = 0.1, max = 1, decimals = 1
	})

	ix.option.Add("enablevbob", ix.type.bool, false, {
		category = "ViewBob"
	})

	local BobbingSpeed = 4.5
	local BobbingAmount = ix.option.Get("cbobIntensity", 0.1)
	local RollSmoothing = ix.option.Get("cbobCompensation", 0.2)

	local rollAngle = 0
	local pitchOffset = 0
	local rollOffset = 0
	local verticalBobbingAmount = 0.1
	local customBobbingSpeed = 1.4

	local function Viewbob(pos, ang, time, intensity)
		local ply = GetViewEntity()
		if not IsValid(ply) then return end
		if not ply:IsPlayer() then return end
		if ply:GetLocalVar("bIsHoldingObject", false) then return end
		--if ix.option.Get("thirdpersonEnabled", false) then return end
		local eang = ply:EyeAngles()
		local up = eang:Up()
		local ri = eang:Right()
		local opos = pos * 1
		local tr = ply:GetEyeTraceNoCursor()
		if not tr then return end
		if not tr.HitPos then return end
		local ldist = tr.HitPos:Distance(pos)
		local delta = math.min(SysTime() - LastCalcViewBob, FrameTime(), 1 / 30)

		if sv_cheats_cv:GetBool() then
			delta = delta * host_timescale_cv:GetFloat()
		end

		delta = delta * game.GetTimeScale()
		LastCalcViewBob = SysTime()

		ldist = math.max(ldist, MinimumFocus)
		pos:Add(up * math.sin((time + 0.5) * rate_up) * scale_up * intensity * -7)
		pos:Add(ri * math.sin((time + 0.5) * rate_right) * scale_right * intensity * -7)

		local walkSpeed = ply:GetVelocity():Length()
		local bobbingOffset = math.sin(CurTime() * BobbingSpeed * customBobbingSpeed) * BobbingAmount
		local verticalBobbingOffset = math.sin(CurTime() * BobbingSpeed * 2 * customBobbingSpeed) * verticalBobbingAmount
		local walking = false

		if walkSpeed > 0 then
			rollAngle = Lerp(RollSmoothing, rollAngle, bobbingOffset * 3) * intensity
			pitchOffset = verticalBobbingOffset * intensity
			local rollDirection = ply:GetVelocity():Dot(ang:Right()) > 0 and 1 or -1
			rollOffset = (math.cos(CurTime() * BobbingSpeed * customBobbingSpeed) * BobbingAmount * rollDirection) * intensity
		else
			rollAngle = rollAngle * intensity
			pitchOffset = pitchOffset * intensity
			rollOffset = rollOffset * intensity
		end

		if walkSpeed < 30 then
			BobbingSpeed = 2
			BobbingAmount = 0.1
			verticalBobbingAmount = 0.1
			customBobbingSpeed = 1.2
		elseif walkSpeed > 100 then -- this shit is like, if your running and your walkspeed is like bigger than 100 just adjust the bobbing amount to make the running effect  
			BobbingSpeed = 4
			BobbingAmount = 0.2
			verticalBobbingAmount = 0.2
			customBobbingSpeed = 1.8
		else
			BobbingSpeed = 4.5
			BobbingAmount = 0.1
			verticalBobbingAmount = 0.1
			customBobbingSpeed = 1.4
		end

		ang.r = ang.r + rollAngle + rollOffset
		ang.p = ang.p + pitchOffset

		return pos, ang
	end

	local function AirWalkScale(ply)
		return ply:IsOnGround() and 1 or 0.2
	end

	function PLUGIN:PreRender()
		local ply = GetViewEntity()
		if not IsValid(ply) then return end
		if not ply:IsPlayer() then return end
		if ply:InVehicle() then return end
		if (IsValid(ix.gui.characterMenu)) then return end
		-- if (IsValid(pace.editorMenu)) then return end
		if (IsValid(ply.ixScanner)) then return end
		if ix.option.Get("thirdpersonEnabled", true) then return end
		if not ix.option.Get("enablevbob", true) then return end
		if ply:GetMoveType() == MOVETYPE_NOCLIP then return end
		local rawVel = ply:GetVelocity()
		local velocity = math.max(rawVel:Length2D() * AirWalkScale(ply) - rawVel.z * 0.5, 0)
		local rate = math.Clamp(math.sqrt(velocity / ply:GetRunSpeed()) * 1.75, 0.15, 2)
		ViewBobTime = ViewBobTime + FrameTime() * rate
		ViewBobIntensity = 0.15 + velocity / ply:GetRunSpeed()
	end

	local ISCALC = false

	function PLUGIN:CalcView(ply, pos, ang, ...)
		if IsValid(ply) and ply:InVehicle() then return end
		if ply:GetMoveType() == MOVETYPE_NOCLIP then return end
		-- if (IsValid(pace.editorMenu)) then return end
		if (IsValid(ply.ixScanner)) then return end
		if ISCALC then return end
		ISCALC = true
		local tmptbl = hook.Run("CalcView", ply, pos, ang, ...) or {}
		ISCALC = false
		tmptbl.origin = tmptbl.origin or pos
		tmptbl.angles = tmptbl.angles or ang
		tmptbl.fov = tmptbl.fov or fov
		tmptbl.origin, tmptbl.angles = Viewbob(tmptbl.origin, tmptbl.angles, ViewBobTime, ViewBobIntensity * ix.option.Get('cbobIntensity', 1))

		return tmptbl
	end

	local ISCALCVM = false

	function PLUGIN:CalcViewModelView(wep, vm, oPos, oAng, pos, ang, ...)
		if ISCALCVM then return end
		ISCALCVM = true
		local tPos, tAng = hook.Run("CalcViewModelView", wep, vm, oPos, oAng, pos, ang, ...)
		ISCALCVM = false
		pos = tPos or pos
		ang = tAng or ang
		pos, ang = Viewbob(pos, ang, ViewBobTime, ViewBobIntensity * ix.option.Get('cbobIntensity', 1))

		return pos, ang
	end
end