-- local PLUGIN = PLUGIN
-- PLUGIN.name = "View Bobbing"
-- PLUGIN.author = "enaruu"

-- ix.lang.AddTable("english", {
-- 	optEnableViewBob = "Enable View Bob",
-- 	optdEnableViewBob = "Wether or not simulate natural character head bobing in first person view.",
-- 	optViewBobSpeed = "View Bob Speed",
-- 	optdViewBobSpeed = "Adjust the speed of natural character head bobing in first person view.",
-- 	optViewBobAmount = "View Bob Amount",
-- 	optdViewBobAmount = "Adjust the amount of natural character head bobing in first person view.",
-- 	optViewBobRollSmoothing = "View Bob Roll Smoothing",
-- 	optdViewBobRollSmoothing = "Adjust the roll smoothing of natural character head bobing in first person view.",
-- })
-- ix.lang.AddTable("korean", {
-- 	["ViewBob"] = "머리 흔들림",
-- 	optEnableViewBob = "머리 흔들림 켜기",
-- 	optdEnableViewBob = "일인칭 시점에서 자연스러운 캐릭터 머리 흔들림을 재현합니다.",
-- 	optViewBobSpeed = "머리 흔들림 속도",
-- 	optdViewBobSpeed = "일인칭 시점에서 자연스러운 캐릭터 머리 흔들림의 속도를 조절합니다.",
-- 	optViewBobAmount = "머리 흔들림 크기",
-- 	optdViewBobAmount = "일인칭 시점에서 자연스러운 캐릭터 머리 흔들림의 크기를 조절합니다.",
-- 	optViewBobRollSmoothing = "머리 흔들림 롤 스무딩",
-- 	optdViewBobRollSmoothing = "일인칭 시점에서 자연스러운 캐릭터 머리 흔들림의 롤 스무딩을 조절합니다.",
-- })

-- if CLIENT then
-- 	ix.option.Add("EnableViewBob", ix.type.bool, true, {
-- 		category = "ViewBob"
-- 	})
-- 	ix.option.Add("ViewBobSpeed", ix.type.number, 4.5, {
-- 		category = "ViewBob", min = 0.1, max = 10, decimals = 1
-- 	})
-- 	ix.option.Add("ViewBobAmount", ix.type.number, 0.1, {
-- 		category = "ViewBob", min = 0.1, max = 1, decimals = 1
-- 	})
-- 	ix.option.Add("ViewBobRollSmoothing", ix.type.number, 0.2, {
-- 		category = "ViewBob", min = 0.1, max = 1, decimals = 1
-- 	})

-- 	local BobbingSpeed = ix.option.Get("ViewBobSpeed", 4.5)
-- 	local BobbingAmount = ix.option.Get("ViewBobAmount", 0.1)
-- 	local RollSmoothing = ix.option.Get("ViewBobRollSmoothing", 0.2)

-- 	local rollAngle = 0
-- 	local pitchOffset = 0
-- 	local rollOffset = 0
-- 	local verticalBobbingAmount = 0.1
-- 	local customBobbingSpeed = 1.4

-- 	function PLUGIN:CalcView(ply, origin, angles, fov)
-- 		local walkSpeed = ply:GetVelocity():Length()
-- 		local bobbingOffset = math.sin(CurTime() * BobbingSpeed * customBobbingSpeed) * BobbingAmount
-- 		local verticalBobbingOffset = math.sin(CurTime() * BobbingSpeed * 2 * customBobbingSpeed) * verticalBobbingAmount

-- 		if (IsValid(ply.ixScn)) then return end

-- 		if (ix.option.Get("EnableViewBob", true) and !ply:InVehicle() and ply:GetMoveType() != MOVETYPE_NOCLIP) then
-- 			if (IsValid(ply.ixScanner)) then return end
-- 			if ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT) then
-- 				rollAngle = Lerp(RollSmoothing, rollAngle, bobbingOffset * 3)

-- 				pitchOffset = verticalBobbingOffset

-- 				local rollDirection = ply:GetVelocity():Dot(angles:Right()) > 0 and 1 or -1
-- 				rollOffset = math.cos(CurTime() * BobbingSpeed * customBobbingSpeed) * BobbingAmount * rollDirection
-- 			else
-- 				rollAngle = 0
-- 				pitchOffset = 0
-- 				rollOffset = 0
-- 			end

-- 			if walkSpeed < 30 then
-- 				BobbingSpeed = 2
-- 				BobbingAmount = 0.1
-- 				verticalBobbingAmount = 0.1
-- 				customBobbingSpeed = 1.2
-- 			elseif walkSpeed > 100 then -- this shit is like, if your running and your walkspeed is like bigger than 100 just adjust the bobbing amount to make the running effect  
-- 				BobbingSpeed = 4
-- 				BobbingAmount = 0.2
-- 				verticalBobbingAmount = 0.2
-- 				customBobbingSpeed = 1.8
-- 			else
-- 				BobbingSpeed = 4.5
-- 				BobbingAmount = 0.1
-- 				verticalBobbingAmount = 0.1
-- 				customBobbingSpeed = 1.4
-- 			end

-- 			angles.roll = angles.roll + rollAngle

-- 			angles.pitch = angles.pitch + pitchOffset

-- 			angles.roll = angles.roll + rollOffset
-- 		end

-- 		return {
-- 			origin = origin,
-- 			angles = angles,
-- 			fov = fov
-- 		}
-- 	end
-- end