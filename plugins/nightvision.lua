PLUGIN.name = "Night Vision - Helix"
PLUGIN.author = "Black Tea | Modified by Frosty"
PLUGIN.description = "Standalone night vision implementation for Helix."

ix.lang.AddTable("english", {
	cmdNightVision = "Toggles the night vision",
})
ix.lang.AddTable("korean", {
	cmdNightVision = "야간 투시를 전환합니다.",
})

if (SERVER) then
	resource.AddWorkshop("224378049")

	function PLUGIN:PlayerSpawn(client)
		if client:GetLocalVar("nv_mode", "off") then
			client:SetLocalVar("nv_mode", "off")
			netstream.Start(client, "ixNVToggle", false)
			netstream.Start(client, "ixFLIRToggle", false)
		end
	end

	function PLUGIN:PlayerDeath(client)
		if client:GetLocalVar("nv_mode", "off") then
			client:SetLocalVar("nv_mode", "off")
			netstream.Start(client, "ixNVToggle", false)
			netstream.Start(client, "ixFLIRToggle", false)
		end
	end

	function PLUGIN:PlayerLoadedCharacter(client, character, oldCharacter)
		if client:GetLocalVar("nv_mode", "off") then
			client:SetLocalVar("nv_mode", "off")
			netstream.Start(client, "ixNVToggle", false)
			netstream.Start(client, "ixFLIRToggle", false)
		end
	end

	function PLUGIN:PlayerDisconnected(client)
		if client:GetLocalVar("nv_mode", "off") then
			client:SetLocalVar("nv_mode", "off")
			netstream.Start(client, "ixNVToggle", false)
			netstream.Start(client, "ixFLIRToggle", false)
		end
	end
end

ix.command.Add("NightVision", {
	alias = "NV",
	description = "@cmdNightVision",
	arguments = bit.bor(ix.type.string, ix.type.optional),
	OnCheckAccess = function(self, client)
		return Schema:CanPlayerSeeCombineOverlay(client) and client:Team() == FACTION_OTA
	end,
	OnRun = function(self, client, mode)
		mode = (mode and mode:lower() == "ir") and "ir" or "nv"

		local currentMode = client:GetLocalVar("nv_mode", "off")
		if (currentMode == mode) then
			mode = "off"
		end

		client:SetLocalVar("nv_mode", mode)

		if (mode == "nv") then
			netstream.Start(client, "ixNVToggle", true)
		elseif (mode == "ir") then
			netstream.Start(client, "ixFLIRToggle", true)
		else
			netstream.Start(client, "ixNVToggle", false)
		end
	end
})

if (!CLIENT) then
	return
end

local state = {
	status = false,
	nightType = 1,
	vector = 0,
	timeToVector = 0,
	isibIntensity = 1,
	isBrighter = false,
	isMade = false,
	ply = nil,
	brightness = 0,
	illumArea = 0,
	isibSens = 0,
	dlight = nil,
	trace = nil,
	blurIntensity = 1,
	genInProgress = false,
	curScale = 0,
	bloomStrength = 0,
	bloomDarken = 0.75,
	bloomMultiply = 1,
	nextLightCheck = 0,
	cachedClr = 0,
	cachedLightPos = 0
}

-- Performance - Cache common globals in upvalues to reduce Lua table lookup overhead
local _LocalPlayer = LocalPlayer
local _FrameTime = FrameTime
local _ScrW = ScrW
local _ScrH = ScrH
local _IsValid = IsValid
local _CurTime = CurTime
local _ents = ents
local _player = player
local _render = render
local _cam = cam
local _surface = surface
local _util = util

CreateClientConVar("nv_toggspeed", 0.09, true, false)
CreateClientConVar("nv_illum_area", 512, true, false)
CreateClientConVar("nv_illum_bright", 1, true, false)
CreateClientConVar("nv_aim_status", 0, true, false)
CreateClientConVar("nv_aim_range", 200, true, false)
CreateClientConVar("nv_etisd_sensitivity_range", 200, true, false)
CreateClientConVar("nv_etisd_status", 0, true, false)
CreateClientConVar("nv_id_sens_darkness", 0.25, true, false)
CreateClientConVar("nv_id_status", 0, true, false)
CreateClientConVar("nv_id_reaction_time", 1, true, false)
CreateClientConVar("nv_isib_sensitivity", 5, true, false)
CreateClientConVar("nv_isib_status", 0, true, false)
CreateClientConVar("nv_fx_alphapass", 5, true, false)
CreateClientConVar("nv_fx_blur_status", 1, true, false)
CreateClientConVar("nv_fx_distort_status", 1, true, false)
CreateClientConVar("nv_fx_colormod_status", 1, true, false)
CreateClientConVar("nv_fx_blur_intensity", 1, true, false)
CreateClientConVar("nv_fx_goggle_overlay_status", 0, true, false)
CreateClientConVar("nv_fx_bloom_status", 0, true, false)
CreateClientConVar("nv_fx_goggle_status", 0, true, false)
CreateClientConVar("nv_fx_noise_status", 0, true, false)
CreateClientConVar("nv_fx_noise_variety", 20, true, false)
CreateClientConVar("nv_type", 1, true, false)

-- Cache the ConVars for performance in a single table to reduce upvalues
local cv = {
	toggspeed = GetConVar("nv_toggspeed"),
	illum_area = GetConVar("nv_illum_area"),
	illum_bright = GetConVar("nv_illum_bright"),
	aim_status = GetConVar("nv_aim_status"),
	aim_range = GetConVar("nv_aim_range"),
	etisd_sensitivity_range = GetConVar("nv_etisd_sensitivity_range"),
	etisd_status = GetConVar("nv_etisd_status"),
	id_sens_darkness = GetConVar("nv_id_sens_darkness"),
	id_status = GetConVar("nv_id_status"),
	id_reaction_time = GetConVar("nv_id_reaction_time"),
	isib_sensitivity = GetConVar("nv_isib_sensitivity"),
	isib_status = GetConVar("nv_isib_status"),
	fx_alphapass = GetConVar("nv_fx_alphapass"),
	fx_blur_status = GetConVar("nv_fx_blur_status"),
	fx_distort_status = GetConVar("nv_fx_distort_status"),
	fx_colormod_status = GetConVar("nv_fx_colormod_status"),
	fx_blur_intensity = GetConVar("nv_fx_blur_intensity"),
	fx_goggle_overlay_status = GetConVar("nv_fx_goggle_overlay_status"),
	fx_bloom_status = GetConVar("nv_fx_bloom_status"),
	fx_goggle_status = GetConVar("nv_fx_goggle_status"),
	fx_noise_status = GetConVar("nv_fx_noise_status"),
	fx_noise_variety = GetConVar("nv_fx_noise_variety"),
	type = GetConVar("nv_type")
}

local function disableLegacyNVScript()
	hook.Remove("InitPostEntity", "NV_InitPostEntity")
	hook.Remove("RenderScreenspaceEffects", "NV_FX")
	hook.Remove("PostDrawOpaqueRenderables", "FLIRFX")
	hook.Remove("Think", "NV_MonitorIllumination")
	hook.Remove("HUDPaint", "NV_HUDPaint")
	hook.Remove("PostDrawViewModel", "NV_PostDrawViewModel")
end

local Color_Brightness = 0.05
local Color_Contrast = 1.3
local Color_AddGreen = 0.15
local Color_MultiplyGreen = 0.08

local Color_Tab = {
	["$pp_colour_addr"] = 0.02,
	["$pp_colour_addg"] = Color_AddGreen,
	["$pp_colour_addb"] = 0.02,
	["$pp_colour_brightness"] = Color_Brightness,
	["$pp_colour_contrast"] = Color_Contrast,
	["$pp_colour_colour"] = 0.2, -- Keep it mostly monochrome-green
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = Color_MultiplyGreen,
	["$pp_colour_mulb"] = 0
}

local Clr_FLIR = {
	["$pp_colour_addr"] = 0.12,
	["$pp_colour_addg"] = 0.12,
	["$pp_colour_addb"] = 0.12,
	["$pp_colour_brightness"] = 0.18,
	["$pp_colour_contrast"] = 1.55,
	["$pp_colour_colour"] = 0,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

local Clr_FLIR_Ents = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = 0.24,
	["$pp_colour_contrast"] = 1.2,
	["$pp_colour_colour"] = 0,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

local sndOn = Sound("items/nvg_on.wav")
local sndOff = Sound("items/nvg_off.wav")

local OverlayTexture = surface.GetTextureID("effects/nv_overlaytex.vmt")
local Grain = surface.GetTextureID("effects/grain.vmt")
local GrainMat = Material("effects/grain")
local Line = surface.GetTextureID("effects/nvline.vmt")
local LineMat = Material("effects/nvline")
local tr = {}
local GrainTable = {}

local function generateGrainTextures()
	GrainTable = {cur = 1, wait = 0}

	local OldRT = render.GetRenderTarget()
	local w, h = ScrW(), ScrH()

	for i = 1, cv.fx_noise_variety:GetInt() do
		local Output = GetRenderTarget("ixNVGrain" .. i, w / 4, h / 4, true)

		render.SetRenderTarget(Output)
		render.SetViewPort(0, 0, w / 4, h / 4)
		render.Clear(0, 0, 0, 0)

		cam.Start2D()
			for y = 1, h / 4 do
				for _ = 1, 40 do
					render.SetViewPort(math.random(0, w / 4), y * 2, 1, 1)
					render.Clear(0, 0, 0, math.random(100, 150))
				end
			end
		cam.End2D()

		GrainTable[i] = Output
		GrainTable.last = i
	end

	render.SetViewPort(0, 0, w, h)
	render.SetRenderTarget(OldRT)
end

local function generateLineTexture()
	local OldRT = render.GetRenderTarget()
	local w, h = ScrW(), ScrH()

	local Output = GetRenderTarget("ixNVLine", w, h, true)

	render.SetRenderTarget(Output)
	render.Clear(0, 0, 0, 0)
	render.SetViewPort(0, 0, w, h)

	cam.Start2D()
		for y = 1, h / 4 do
			render.SetViewPort(0, y * 4, w, 2)
			render.Clear(255, 255, 255, 200)
		end
	cam.End2D()

	render.SetViewPort(0, 0, w, h)
	render.SetRenderTarget(OldRT)
	LineMat:SetTexture("$basetexture", Output)
end

local function refreshGeneratedTextures()
	timer.Simple(2, function()
		if (!IsValid(LocalPlayer())) then
			return
		end

		generateGrainTextures()
		generateLineTexture()
	end)
end

local function removeOurEffects()
	hook.Remove("RenderScreenspaceEffects", "ixNV_FX")
	hook.Remove("PostDrawOpaqueRenderables", "ixNV_FLIRFX")
	hook.Remove("Think", "ixNV_MonitorIllumination")
	hook.Remove("HUDPaint", "ixNV_HUDPaint")
	hook.Remove("PostDrawViewModel", "ixNV_PostDrawViewModel")
end

local function setNightVisionState(enabled, nightType)
	local client = LocalPlayer()
	if (!IsValid(client) or !client:Alive()) then
		return
	end

	if (!enabled) then
		if (state.status) then
			surface.PlaySound(sndOff)
		end

		state.status = false
		state.curScale = 0
		removeOurEffects()

		local defaultColorMod = {
			["$pp_colour_addr"] = 0,
			["$pp_colour_addg"] = 0,
			["$pp_colour_addb"] = 0,
			["$pp_colour_brightness"] = 0,
			["$pp_colour_contrast"] = 1,
			["$pp_colour_colour"] = 1,
			["$pp_colour_mulr"] = 0,
			["$pp_colour_mulg"] = 0,
			["$pp_colour_mulb"] = 0
		}

		hook.Add("RenderScreenspaceEffects", "ixNV_ClearColor", function()
			DrawColorModify(defaultColorMod)
			hook.Remove("RenderScreenspaceEffects", "ixNV_ClearColor")
		end)

		return
	end

	RunConsoleCommand("nv_type", tostring(nightType or 1))
	state.nightType = nightType or 1

	if (!state.status) then
		state.curScale = 0.2
		surface.PlaySound(sndOn)
	end

	state.status = true
	hook.Add("RenderScreenspaceEffects", "ixNV_FX", function()
		state.ply = LocalPlayer()

		if (!IsValid(state.ply)) then
			return
		end

		if (state.ply:Alive() and state.status == true) then
			local w, h = ScrW(), ScrH()
			local FT = FrameTime()
			state.curScale = Lerp(FT * (30 * cv.toggspeed:GetFloat()), state.curScale, 1)

			local nType = cv.type:GetInt()
			if (nType <= 1) then
				if (cv.fx_bloom_status:GetInt() > 0) then
					-- Dynamic Bloom based on ISIB (Eye Strain realism)
					local intensityBoost = math.Clamp((state.isibIntensity or 1), 1, 10)
					state.bloomMultiply = Lerp(0.05, state.bloomMultiply, 2 * intensityBoost)
					state.bloomDarken = Lerp(0.1, state.bloomDarken, 0.75 - intensityBoost * 0.1)
					DrawBloom(state.bloomDarken, state.bloomMultiply, 9, 9, 1, 1, 1, 1, 1)
				end

				surface.SetDrawColor(155, 220, 155, 64)
				surface.SetTexture(surface.GetTextureID("effects/nightvision.vmt"))

				for i = 1, 1 do
					surface.DrawTexturedRect(0, 0, w, h)
				end

				surface.SetTexture(Line)
				surface.SetDrawColor(20, 64, 20, 64)
				surface.DrawTexturedRect(0, 0, w, h)

				if (cv.fx_noise_status:GetInt() > 0 and GrainTable.cur and GrainTable[GrainTable.cur]) then
					GrainMat:SetTexture("$basetexture", GrainTable[GrainTable.cur])
					surface.SetTexture(Grain)
					surface.SetDrawColor(0, 0, 0, 255)
					surface.DrawTexturedRect(0, 0, w, h)

					local CT = SysTime()
					if (CT > GrainTable.wait) then
						if (GrainTable.cur == GrainTable.last) then
							GrainTable.cur = 1
							GrainTable.wait = CT + FT * 2
						else
							GrainTable.cur = GrainTable.cur + 1
							GrainTable.wait = CT + FT * 2
						end
					end
				end

				if (cv.fx_distort_status:GetInt() > 0) then
					DrawMaterialOverlay("models/shadertest/shader3.vmt", 0.0001)
				end

				if (cv.fx_goggle_status:GetInt() > 0) then
					DrawMaterialOverlay("models/props_c17/fisheyelens.vmt", -0.03)
				end

				state.blurIntensity = cv.fx_blur_intensity:GetFloat()
				if (cv.fx_blur_status:GetInt() > 0) then
					DrawMotionBlur(0.05 * state.blurIntensity, 0.2 * state.blurIntensity, 0.023 * state.blurIntensity)
				end

				if (cv.fx_colormod_status:GetInt() > 0) then
					-- Adjust brightness/contrast in real-time
					Color_Tab["$pp_colour_brightness"] = state.curScale * Color_Brightness
					Color_Tab["$pp_colour_contrast"] = state.curScale * Color_Contrast
					DrawColorModify(Color_Tab)
				end
			else
				DrawColorModify(Clr_FLIR)
			end
		elseif (!state.ply:Alive()) then
			surface.PlaySound(sndOff)
			state.status = false
			removeOurEffects()
		end
	end)

	hook.Add("PostDrawOpaqueRenderables", "ixNV_FLIRFX", function()
		if (cv.type:GetInt() < 2 or !state.status) then
			return
		end

		render.ClearStencil()
		render.SetStencilEnable(true)
		render.SetStencilFailOperation(STENCILOPERATION_KEEP)
		render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
		render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
		render.SetStencilReferenceValue(1)
		render.SuppressEngineLighting(true)

		local FT = _FrameTime()

		-- Performance - ents.Iterator() is much faster than pairs(ents.GetAll()) since 2022 GMod update
		for _, ent in _ents.Iterator() do
			if (_IsValid(ent)) then
				if (ent:IsNPC() or ent:IsPlayer()) then
					-- Don't draw the local player's heat signature
					if (ent == _LocalPlayer()) then continue end

					if (!ent:IsEffectActive(EF_NODRAW)) then
						_render.SuppressEngineLighting(true)
						ent:DrawModel()
						_render.SuppressEngineLighting(false)
					end
				elseif (ent:GetClass() == "class C_ClientRagdoll") then
					if (!ent.Int) then
						ent.Int = 1
					else
						ent.Int = math.Clamp(ent.Int - FT * 0.015, 0, 1)
					end

					render.SetColorModulation(ent.Int, ent.Int, ent.Int)
					render.SuppressEngineLighting(true)
					ent:DrawModel()
					render.SuppressEngineLighting(false)
					render.SetColorModulation(1, 1, 1)
				end
			end
		end

		render.SuppressEngineLighting(false)
		render.SetStencilReferenceValue(2)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
		render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
		render.SetStencilReferenceValue(1)
		DrawColorModify(Clr_FLIR_Ents)
		render.SetStencilEnable(false)
	end)

	-- Shared state is already in 'state' table at top level


	hook.Add("Think", "ixNV_MonitorIllumination", function()
		state.ply = LocalPlayer()
		if (!IsValid(state.ply) or !state.ply:Alive() or !state.ply:GetCharacter()) then
			return
		end

		-- Performance - skip heavy lighting computation if not needed
		if (!state.status and cv.id_status:GetInt() < 1) then
			return
		end

		local CT = _CurTime()
		local EP, EA = state.ply:EyePos(), state.ply:EyeAngles():Forward()

		-- Performance - throttle ComputeLighting (super expensive) to 20Hz (0.05s)
		if (state.nextLightCheck < CT) then
			local lights = _render.ComputeLighting(EP, Vector(0, 0, -1)) - _render.ComputeDynamicLighting(EP, Vector(0, 0, -1))
			state.cachedClr = lights:Length() * 33
			state.nextLightCheck = CT + 0.05
		end
		
		local clr = state.cachedClr

		if (state.status) then
			state.brightness = cv.illum_bright:GetFloat()
			state.illumArea = cv.illum_area:GetFloat()
			state.isibSens = cv.isib_sensitivity:GetFloat()
			state.dlight = DynamicLight(state.ply:EntIndex())

			if (state.dlight) then
				local FT = FrameTime()
				local aim = cv.aim_status:GetInt()

				if (aim > 0) then
					tr.start = EP
					tr.endpos = tr.start + EA * cv.aim_range:GetFloat()
					tr.filter = state.ply
					local trace = util.TraceLine(tr)

					if (!trace.Hit) then
						if (CT > state.timeToVector) then
							state.vector = math.Clamp(state.vector + 1, 0, 20)
							state.timeToVector = CT + 0.005
						end

						state.dlight.Pos = trace.HitPos + Vector(0, 0, state.vector)
					else
						if (CT > state.timeToVector) then
							state.vector = math.Clamp(state.vector - 1, 0, 20)
							state.timeToVector = CT + 0.005
						end

						state.dlight.Pos = trace.HitPos + Vector(0, 0, state.vector)
					end
					
					state.trace = trace
				else
					state.dlight.Pos = state.ply:GetShootPos()
				end

				state.dlight.r = 125 * state.brightness
				state.dlight.g = 255 * state.brightness
				state.dlight.b = 125 * state.brightness
				state.dlight.Brightness = 1.25

				if (cv.isib_status:GetInt() < 1) then
					-- Significantly increased size and adjusted decay for a more "ambient" feel
					local size = state.illumArea * state.curScale * 5.0
					state.dlight.Size = size
					state.dlight.Decay = size * 1.5
				else
					if (aim > 0) then
						-- Throttle this as well for aim mode
						if (state.nextLightCheck < CT) then
							local traceLights = _render.ComputeLighting(state.trace.HitPos, Vector(0, 0, -1)) - _render.ComputeDynamicLighting(state.trace.HitPos, Vector(0, 0, -1))
							state.cachedLightPos = traceLights:Length() * 33
						end
						clr = state.cachedLightPos
					end

					-- Realistic Exposure: Increased intensity in dark, reduced in light
					state.isibIntensity = Lerp(FT * 10, state.isibIntensity, clr * state.isibSens)
					local size = math.Clamp((state.illumArea * state.curScale * 4.0) / state.isibIntensity, 0, state.illumArea * 5.0)
					state.dlight.Size = size
					state.dlight.Decay = size * 1.5
				end

				state.dlight.DieTime = CT + FT * 3
			end
		end

		if (cv.id_status:GetInt() > 0) then
			if (!state.isBrighter) then
				if (clr < cv.id_sens_darkness:GetFloat()) then
					if (!state.isMade) then
						timer.Create("ixNightVisionMonitorIllum", cv.id_reaction_time:GetFloat(), 1, function()
							if (clr < cv.id_sens_darkness:GetFloat()) then
								if (!state.status) then
									RunConsoleCommand("nv_togg")
								end
							else
								if (state.status) then
									RunConsoleCommand("nv_togg")
								end
							end

							state.isMade = false
						end)

						state.isMade = true
					end
				elseif (timer.Exists("ixNightVisionMonitorIllum")) then
					timer.Start("ixNightVisionMonitorIllum")
				end
			end

			if (cv.etisd_status:GetInt() > 0) then
				tr.start = EP
				tr.endpos = tr.start + EA * cv.etisd_sensitivity_range:GetFloat()
				tr.filter = state.ply
				local trace = util.TraceLine(tr)
				
				-- Use cached light check here too
				clr = state.cachedLightPos or clr

				if (clr > cv.id_sens_darkness:GetFloat()) then
					if (!state.isBrighter) then
						if (state.status) then
							RunConsoleCommand("nv_togg")
						end

						state.isBrighter = true
						if (timer.Exists("ixNightVisionMonitorIllum")) then
							timer.Stop("ixNightVisionMonitorIllum")
						end
					elseif (timer.Exists("ixNightVisionMonitorIllum")) then
						timer.Start("ixNightVisionMonitorIllum")
					end
				else
					state.isBrighter = false
				end
			end
		end
	end)

	hook.Add("HUDPaint", "ixNV_HUDPaint", function()
		state.ply = LocalPlayer()
		if (!IsValid(state.ply) or !state.ply:Alive() or !state.status) then
			return
		end

		if (cv.fx_goggle_overlay_status:GetInt() > 0) then
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetTexture(OverlayTexture)
			surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
		end
	end)
end

concommand.Add("nv_togg", function()
	if (math.Round(GetConVarNumber("nv_type")) >= 2) then
		ix.command.Send("NightVision", "ir")
	else
		ix.command.Send("NightVision")
	end
end)

concommand.Add("nv_generate_noise_textures", function()
	if (state.genInProgress) then
		return
	end

	state.genInProgress = true
	timer.Simple(2, function()
		generateGrainTextures()
		state.genInProgress = false
	end)
end)

concommand.Add("nv_reset_everything", function()
	RunConsoleCommand("nv_fx_blur_status", "1")
	RunConsoleCommand("nv_fx_distort_status", "0")
	RunConsoleCommand("nv_fx_colormod_status", "1")
	RunConsoleCommand("nv_fx_goggle_overlay_status", "0")
	RunConsoleCommand("nv_fx_goggle_status", "0")
	RunConsoleCommand("nv_fx_noise_status", "1")
	RunConsoleCommand("nv_fx_noise_variety", "20")
	RunConsoleCommand("nv_fx_bloom_status", "0")
	RunConsoleCommand("nv_fx_blur_intensity", "1.0")
	RunConsoleCommand("nv_fx_alphapass", "5")
	RunConsoleCommand("nv_id_status", "0")
	RunConsoleCommand("nv_id_sens_darkness", "0.25")
	RunConsoleCommand("nv_id_reaction_time", "1")
	RunConsoleCommand("nv_etisd_status", "0")
	RunConsoleCommand("nv_etisd_sensitivity_range", "200")
	RunConsoleCommand("nv_isib_status", "0")
	RunConsoleCommand("nv_isib_sensitivity", "5")
	RunConsoleCommand("nv_toggspeed", "0.2")
	RunConsoleCommand("nv_illum_area", "512")
	RunConsoleCommand("nv_illum_bright", "1")
	RunConsoleCommand("nv_aim_status", "1")
	RunConsoleCommand("nv_aim_range", "200")
	RunConsoleCommand("nv_type", "1")

	setNightVisionState(false)
	refreshGeneratedTextures()
end)

netstream.Hook("ixNVToggle", function(isEnabled)
	disableLegacyNVScript()
	setNightVisionState(isEnabled, 1)
end)

netstream.Hook("ixFLIRToggle", function(isEnabled)
	disableLegacyNVScript()
	setNightVisionState(isEnabled, 2)
end)

hook.Add("InitPostEntity", "ixNightVisionInit", function()
	disableLegacyNVScript()
	refreshGeneratedTextures()
	timer.Simple(3, disableLegacyNVScript)
end)
