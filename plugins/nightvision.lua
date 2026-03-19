PLUGIN.name = "Night Vision - Helix"
PLUGIN.author = "Black Tea | Modified by Frosty"
PLUGIN.description = "Standalone night vision implementation for Helix."

if (SERVER) then
	resource.AddWorkshop("224378049")

	function PLUGIN:PlayerSpawn(client)
		client:SetLocalVar("nv_mode", "off")
		netstream.Start(client, "ixNVToggle", false)
		netstream.Start(client, "ixFLIRToggle", false)
	end

	function PLUGIN:PlayerLoadedCharacter(client, character, oldCharacter)
		client:SetLocalVar("nv_mode", "off")
		netstream.Start(client, "ixNVToggle", false)
		netstream.Start(client, "ixFLIRToggle", false)
	end
end

ix.command.Add("NightVision", {
	alias = "NV",
	description = "@cmdNightVision",
	arguments = bit.bor(ix.type.string, ix.type.optional),
	OnCanRun = function(self, client)
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

local NV_Status = false
local NV_NIGHTTYPE = 1
local NV_Vector = 0
local NV_TimeToVector = 0
local ISIBIntensity = 1
local reg = debug.getregistry()
local Length = reg.Vector.Length

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
CreateClientConVar("nv_fx_goggle_overlay_status", 1, true, false)
CreateClientConVar("nv_fx_bloom_status", 0, true, false)
CreateClientConVar("nv_fx_goggle_status", 0, true, false)
CreateClientConVar("nv_fx_noise_status", 0, true, false)
CreateClientConVar("nv_fx_noise_variety", 20, true, false)
CreateClientConVar("nv_type", 1, true, false)

local function disableLegacyNVScript()
	hook.Remove("InitPostEntity", "NV_InitPostEntity")
	hook.Remove("RenderScreenspaceEffects", "NV_FX")
	hook.Remove("PostDrawOpaqueRenderables", "FLIRFX")
	hook.Remove("Think", "NV_MonitorIllumination")
	hook.Remove("HUDPaint", "NV_HUDPaint")
	hook.Remove("PostDrawViewModel", "NV_PostDrawViewModel")
end

local IsBrighter = false
local IsMade = false
local ply, Brightness, IlluminationArea, ISIBSensitivity, dlight, trace, BlurIntensity, GenInProgress
local tr = {}

local Color_Brightness = 0.8
local Color_Contrast = 1.1
local Color_AddGreen = -0.35
local Color_MultiplyGreen = 0.028

local Bloom_Darken = 0.75
local Bloom_Multiply = 1

local Color_Tab = {
	["$pp_colour_addr"] = -1,
	["$pp_colour_addg"] = Color_AddGreen,
	["$pp_colour_addb"] = -1,
	["$pp_colour_brightness"] = Color_Brightness,
	["$pp_colour_contrast"] = Color_Contrast,
	["$pp_colour_colour"] = 0,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = Color_MultiplyGreen,
	["$pp_colour_mulb"] = 0
}

local Clr_FLIR = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = -0.65,
	["$pp_colour_contrast"] = 2.2,
	["$pp_colour_colour"] = 0,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

local Clr_FLIR_Ents = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = 0.6,
	["$pp_colour_contrast"] = 1,
	["$pp_colour_colour"] = 0,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

local CurScale = 0
local sndOn = Sound("items/nvg_on.wav")
local sndOff = Sound("items/nvg_off.wav")

local BloomStrength = 0
local OverlayTexture = surface.GetTextureID("effects/nv_overlaytex.vmt")
local Grain = surface.GetTextureID("effects/grain.vmt")
local GrainMat = Material("effects/grain")
local Line = surface.GetTextureID("effects/nvline.vmt")
local LineMat = Material("effects/nvline")
local utrace, rect, trect, text, CLR, rand = util.TraceLine, surface.DrawRect, surface.DrawTexturedRect, surface.SetTexture, surface.SetDrawColor, math.random
local clr, CT, Output, w, h, FT, OldRT
local AlphaPass = surface.GetTextureID("effects/nightvision.vmt")
local GrainTable = {}
local SetViewPort, Clear, SetRenderTarget, Start2D, End2D = render.SetViewPort, render.Clear, render.SetRenderTarget, cam.Start2D, cam.End2D

local function generateGrainTextures()
	CT = SysTime()
	GrainTable = {cur = 1, wait = 0}

	OldRT = render.GetRenderTarget()
	w, h = ScrW(), ScrH()

	for i = 1, GetConVarNumber("nv_fx_noise_variety") do
		Output = GetRenderTarget("ixNVGrain" .. i, w / 4, h / 4, true)

		SetRenderTarget(Output)
		SetViewPort(0, 0, w / 4, h / 4)
		Clear(0, 0, 0, 0)

		Start2D()
			for y = 1, h / 4 do
				for _ = 1, 40 do
					SetViewPort(rand(0, w / 4), y * 2, 1, 1)
					Clear(0, 0, 0, rand(100, 150))
				end
			end
		End2D()

		GrainTable[i] = Output
		GrainTable.last = i
	end

	SetViewPort(0, 0, w, h)
	SetRenderTarget(OldRT)
end

local function generateLineTexture()
	OldRT = render.GetRenderTarget()
	w, h = ScrW(), ScrH()

	Output = GetRenderTarget("ixNVLine", w, h, true)

	SetRenderTarget(Output)
	Clear(0, 0, 0, 0)
	SetViewPort(0, 0, w, h)

	Start2D()
		for y = 1, h / 4 do
			SetViewPort(0, y * 4, w, 2)
			Clear(255, 255, 255, 200)
		end
	End2D()

	SetViewPort(0, 0, w, h)
	SetRenderTarget(OldRT)
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
		if (NV_Status) then
			surface.PlaySound(sndOff)
		end

		NV_Status = false
		CurScale = 0
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
	NV_NIGHTTYPE = nightType or 1

	if (!NV_Status) then
		CurScale = 0.2
		surface.PlaySound(sndOn)
	end

	NV_Status = true
	hook.Add("RenderScreenspaceEffects", "ixNV_FX", function()
		ply = LocalPlayer()

		if (!IsValid(ply)) then
			return
		end

		if (ply:Alive() and NV_Status == true) then
			w, h = ScrW(), ScrH()
			FT = FrameTime()
			CurScale = Lerp(FT * (30 * GetConVarNumber("nv_toggspeed")), CurScale, 1)

			if (GetConVarNumber("nv_type") <= 1) then
				if (GetConVarNumber("nv_fx_bloom_status") > 0) then
					Bloom_Multiply = Lerp(0.025, Bloom_Multiply, 3)
					Bloom_Darken = Lerp(0.1, Bloom_Darken, 0.75 - BloomStrength)
					DrawBloom(Bloom_Darken, Bloom_Multiply, 9, 9, 1, 1, 1, 1, 1)
				end

				CLR(255, 255, 255, 255)
				text(AlphaPass)

				for i = 1, GetConVarNumber("nv_fx_alphapass") do
					trect(0, 0, w, h)
				end

				text(Line)
				CLR(25, 50, 25, 255)
				trect(0, 0, w, h)

				if (GetConVarNumber("nv_fx_noise_status") > 0 and GrainTable.cur and GrainTable[GrainTable.cur]) then
					GrainMat:SetTexture("$basetexture", GrainTable[GrainTable.cur])
					text(Grain)
					CLR(0, 0, 0, 255)
					trect(0, 0, w, h)

					CT = SysTime()
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

				if (GetConVarNumber("nv_fx_distort_status") > 0) then
					DrawMaterialOverlay("models/shadertest/shader3.vmt", 0.0001)
				end

				if (GetConVarNumber("nv_fx_goggle_status") > 0) then
					DrawMaterialOverlay("models/props_c17/fisheyelens.vmt", -0.03)
				end

				BlurIntensity = GetConVarNumber("nv_fx_blur_intensity")
				if (GetConVarNumber("nv_fx_blur_status") > 0) then
					DrawMotionBlur(0.05 * BlurIntensity, 0.2 * BlurIntensity, 0.023 * BlurIntensity)
				end

				if (GetConVarNumber("nv_fx_colormod_status") > 0) then
					Color_Tab["$pp_colour_brightness"] = CurScale * Color_Brightness
					Color_Tab["$pp_colour_contrast"] = CurScale * Color_Contrast
					DrawColorModify(Color_Tab)
				end
			else
				DrawColorModify(Clr_FLIR)
			end
		elseif (!ply:Alive()) then
			surface.PlaySound(sndOff)
			NV_Status = false
			removeOurEffects()
		end
	end)

	hook.Add("PostDrawOpaqueRenderables", "ixNV_FLIRFX", function()
		if (GetConVarNumber("nv_type") < 2 or !NV_Status) then
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

		FT = FrameTime()

		for _, ent in pairs(ents.GetAll()) do
			if (IsValid(ent)) then
				if (ent:IsNPC() or ent:IsPlayer()) then
					if (!ent:IsEffectActive(EF_NODRAW)) then
						render.SuppressEngineLighting(true)
						ent:DrawModel()
						render.SuppressEngineLighting(false)
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

	hook.Add("Think", "ixNV_MonitorIllumination", function()
		ply = LocalPlayer()
		if (!IsValid(ply) or !ply:Alive()) then
			return
		end

		local EP, EA = ply:EyePos(), ply:EyeAngles():Forward()
		CT = CurTime()
		clr = Length((render.ComputeLighting(EP, Vector(0, 0, -1)) - render.ComputeDynamicLighting(EP, Vector(0, 0, -1)))) * 33

		if (NV_Status) then
			Brightness = GetConVarNumber("nv_illum_bright")
			IlluminationArea = GetConVarNumber("nv_illum_area")
			ISIBSensitivity = GetConVarNumber("nv_isib_sensitivity")
			dlight = DynamicLight(ply:EntIndex())

			if (dlight) then
				FT = FrameTime()
				aim = GetConVarNumber("nv_aim_status")

				if (aim > 0) then
					tr.start = EP
					tr.endpos = tr.start + EA * GetConVarNumber("nv_aim_range")
					tr.filter = ply
					trace = utrace(tr)

					if (!trace.Hit) then
						if (CT > NV_TimeToVector) then
							NV_Vector = math.Clamp(NV_Vector + 1, 0, 20)
							NV_TimeToVector = CT + 0.005
						end

						dlight.Pos = trace.HitPos + Vector(0, 0, NV_Vector)
					else
						if (CT > NV_TimeToVector) then
							NV_Vector = math.Clamp(NV_Vector - 1, 0, 20)
							NV_TimeToVector = CT + 0.005
						end

						dlight.Pos = trace.HitPos + Vector(0, 0, NV_Vector)
					end
				else
					dlight.Pos = ply:GetShootPos()
				end

				dlight.r = 125 * Brightness
				dlight.g = 255 * Brightness
				dlight.b = 125 * Brightness
				dlight.Brightness = 1

				if (GetConVarNumber("nv_isib_status") < 1) then
					dlight.Size = IlluminationArea * CurScale
					dlight.Decay = IlluminationArea * CurScale
				else
					if (aim > 0) then
						clr = Length((render.ComputeLighting(trace.HitPos, Vector(0, 0, -1)) - render.ComputeDynamicLighting(trace.HitPos, Vector(0, 0, -1)))) * 33
					end

					ISIBIntensity = Lerp(FT * 10, ISIBIntensity, clr * ISIBSensitivity)
					dlight.Size = math.Clamp((IlluminationArea * CurScale) / ISIBIntensity, 0, IlluminationArea)
					dlight.Decay = math.Clamp((IlluminationArea * CurScale) / ISIBIntensity, 0, IlluminationArea)
				end

				dlight.DieTime = CT + FT * 3
			end
		end

		if (GetConVarNumber("nv_id_status") > 0) then
			if (!IsBrighter) then
				if (clr < GetConVarNumber("nv_id_sens_darkness")) then
					if (!IsMade) then
						timer.Create("ixNightVisionMonitorIllum", GetConVarNumber("nv_id_reaction_time"), 1, function()
							if (clr < GetConVarNumber("nv_id_sens_darkness")) then
								if (!NV_Status) then
									RunConsoleCommand("nv_togg")
								end
							else
								if (NV_Status) then
									RunConsoleCommand("nv_togg")
								end
							end

							IsMade = false
						end)

						IsMade = true
					end
				elseif (timer.Exists("ixNightVisionMonitorIllum")) then
					timer.Start("ixNightVisionMonitorIllum")
				end
			end

			if (GetConVarNumber("nv_etisd_status") > 0) then
				tr.start = EP
				tr.endpos = tr.start + EA * GetConVarNumber("nv_etisd_sensitivity_range")
				tr.filter = ply
				trace = utrace(tr)
				clr = Length((render.ComputeLighting(trace.HitPos, Vector(0, 0, -1)) - render.ComputeDynamicLighting(trace.HitPos, Vector(0, 0, -1)))) * 33

				if (clr > GetConVarNumber("nv_id_sens_darkness")) then
					if (!IsBrighter) then
						if (NV_Status) then
							RunConsoleCommand("nv_togg")
						end

						IsBrighter = true
						if (timer.Exists("ixNightVisionMonitorIllum")) then
							timer.Stop("ixNightVisionMonitorIllum")
						end
					elseif (timer.Exists("ixNightVisionMonitorIllum")) then
						timer.Start("ixNightVisionMonitorIllum")
					end
				else
					IsBrighter = false
				end
			end
		end
	end)

	hook.Add("HUDPaint", "ixNV_HUDPaint", function()
		ply = LocalPlayer()
		if (!IsValid(ply) or !ply:Alive() or !NV_Status) then
			return
		end

		if (GetConVarNumber("nv_fx_goggle_overlay_status") > 0) then
			CLR(255, 255, 255, 255)
			text(OverlayTexture)
			trect(0, 0, ScrW(), ScrH())
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
	if (GenInProgress) then
		return
	end

	GenInProgress = true
	timer.Simple(2, function()
		generateGrainTextures()
		GenInProgress = false
	end)
end)

concommand.Add("nv_reset_everything", function()
	RunConsoleCommand("nv_fx_blur_status", "1")
	RunConsoleCommand("nv_fx_distort_status", "0")
	RunConsoleCommand("nv_fx_colormod_status", "1")
	RunConsoleCommand("nv_fx_goggle_overlay_status", "1")
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
