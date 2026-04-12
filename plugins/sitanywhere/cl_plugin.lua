local PLUGIN = PLUGIN
local SitAnywhere = PLUGIN

local TAG = "SitAny_"
local function ShouldSit(ply)
	return hook.Run("ShouldSit", ply)
end

local arrow, drawScale, traceDist = Material("widgets/arrow.png"), 0.1, 20
local traceScaled = traceDist / drawScale

local function StartSit(trace)
	local wantedAng = nil
	local cancelled = false
	local start = CurTime()
	local ply = LocalPlayer()

	hook.Add("PostDrawOpaqueRenderables", TAG .. "PostDrawOpaqueRenderables", function(depth, skybox)
		if CurTime() - start <= 0.25 then return end
		if trace.StartPos:Distance(ply:GetShootPos()) > 128 then
			cancelled, wantedAng = true, nil
			hook.Remove("PostDrawOpaqueRenderables", TAG .. "PostDrawOpaqueRenderables")
			return
		end

		local vec = util.IntersectRayWithPlane(ply:GetShootPos(), ply:EyeAngles():Forward(), trace.HitPos, Vector(0, 0, 1))
		
		if vec then
			local posOnPlane = WorldToLocal(vec, Angle(0, 90, 0), trace.HitPos, Angle(0, 0, 0))
			
			if posOnPlane:Length() >= 2 then
				local currentAng = (trace.HitPos - vec):Angle()
				wantedAng = currentAng
			end
		end

		if wantedAng then
			local goodSit = SitAnywhere.CheckValidAngForSit(trace.HitPos, trace.HitNormal:Angle(), wantedAng.y)
			local testVec = WorldToLocal(trace.HitPos - wantedAng:Forward() * traceDist, Angle(0, 90, 0), trace.HitPos, Angle(0, 0, 0))
			
			cam.Start3D2D(trace.HitPos + Vector(0, 0, 1), Angle(0, 0, 0), drawScale)
				surface.SetDrawColor(goodSit and Color(255, 255, 255, 255) or Color(255, 0, 0, 255))
				surface.SetMaterial(arrow)
				surface.DrawTexturedRectRotated(testVec.x * 0.5, testVec.y * -0.5, 2 / drawScale, traceScaled, wantedAng.y + 90)
			cam.End3D2D()
		end
	end)

	return function()
		hook.Remove("PostDrawOpaqueRenderables", TAG .. "PostDrawOpaqueRenderables")
		if cancelled then return end

		if CurTime() - start < 0.25 then
			RunConsoleCommand("sit")
			return
		end

		if wantedAng then
			net.Start("SitAnywhere")
				net.WriteInt(SitAnywhere.NET.SitWantedAng, 4)
				net.WriteFloat(wantedAng.y)
				net.WriteVector(trace.StartPos)
				net.WriteVector(trace.Normal)
			net.SendToServer()
			wantedAng = nil
		end
	end
end

local function DoSit(trace)
	if not trace.Hit then return end

	local surfaceAng = trace.HitNormal:Angle() + Angle(-270, 0, 0)

	local playerTrace = not trace.HitWorld and IsValid(trace.Entity) and trace.Entity:IsPlayer()

	local goodSit = SitAnywhere.GetAreaProfile(trace.HitPos + Vector(0, 0, 0.1), 24, true)
	if math.abs(surfaceAng.pitch) >= 15 or playerTrace then
		RunConsoleCommand"sit"
		return
	end

	local valid = SitAnywhere.ValidSitTrace(LocalPlayer(), trace)
	if not valid then
		return
	end

	return StartSit(trace)
end

local currSit
concommand.Add("+sit", function(ply, cmd, args)
	if currSit then return end
	if not IsValid(ply) or not ply.GetEyeTrace then return end
	currSit = DoSit(ply:GetEyeTrace())
end)

concommand.Add("-sit", function(ply, cmd, args)
	if currSit then
		currSit()
		currSit = nil
	end
end)


hook.Add("KeyPress", TAG .. "KeyPress", function(ply, key)
	if not IsFirstTimePredicted() and not game.SinglePlayer() then return end
	if currSit then return end

	if key ~= IN_USE then return end
	local good = not ix.option.Get("sittingUseWalk", true)
	local alwaysSit = ShouldSit(ply)

	if ix.option.Get("sittingForceLeftAlt", false) then
		if ix.option.Get("sittingUseWalk", true) and input.IsKeyDown(KEY_LALT) then
			good = true
		end
	else
		if ix.option.Get("sittingUseWalk", true) and (ply:KeyDown(IN_WALK) or input.IsKeyDown(KEY_LALT)) then
			good = true
		end
	end

	if ix.config.Get("sittingForceNoWalk", false) then
		good = true
	end

	if alwaysSit == true then
		good = true
	elseif alwaysSit == false then
		good = false
	end

	if not good then return end
	local trace = LocalPlayer():GetEyeTrace()

	if trace.Hit then
		currSit = DoSit(trace)
		hook.Add("KeyRelease", TAG .. "KeyRelease", function(releasePly, releaseKey)
			if not IsFirstTimePredicted() and not game.SinglePlayer() then return end
			if ply ~= releasePly or releaseKey ~= IN_USE then return end
			hook.Remove("KeyRelease", TAG .. "KeyRelease")
			if not currSit then return end

			currSit()
			currSit = nil
		end)
	end
end)