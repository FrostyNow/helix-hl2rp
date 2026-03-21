local PLUGIN = PLUGIN

PLUGIN.name = "More Hurt Effects"
PLUGIN.author = "Pokernut | Reworked by Frosty"
PLUGIN.description = "Add more hurt effects."

PLUGIN.lowHealthAddonCVar = "etb_healtheffect_system"
PLUGIN.lowHealthAddonEnforcedValue = "0"
PLUGIN.heartbeatSound = "lowhp/hbeat.wav"
PLUGIN.vignetteMaterialPath = "vgui/vignette_w"
PLUGIN.hurtFadeDelay = 0.33

ix.config.Add("hurtEffectEnabled", true, "Enable the low-health effect system.", nil, {
	category = "More Hurt Effects"
})

ix.config.Add("hurtEffectThreshold", 25, "Health threshold where low-health effects reach full strength.", nil, {
	data = {min = 5, max = 100},
	category = "More Hurt Effects"
})

ix.config.Add("hurtEffectMuffleThreshold", 10, "Health threshold where sounds become muffled.", nil, {
	data = {min = 1, max = 100},
	category = "More Hurt Effects"
})

ix.config.Add("hurtEffectHeartbeat", true, "Play heartbeat sounds at low health.", nil, {
	category = "More Hurt Effects"
})

ix.config.Add("hurtEffectVignette", true, "Draw a vignette overlay at low health.", nil, {
	category = "More Hurt Effects"
})

ix.config.Add("hurtEffectRedFlash", true, "Draw a red pulse overlay at low health.", nil, {
	category = "More Hurt Effects"
})

ix.config.Add("hurtEffectMuffle", true, "Apply low-health DSP muffling.", nil, {
	category = "More Hurt Effects"
})

local function IsLowHealthSuppressed(client)
	return client:IsAdmin() and client:GetMoveType() == MOVETYPE_NOCLIP
end

local function GetCharacterEndurance(client)
	local character = client.GetCharacter and client:GetCharacter()

	if not character then
		return 0
	end

	return character:GetAttribute("end", 0)
end

function PLUGIN:EnforceAddonConVars()
	local cvar = GetConVar(self.lowHealthAddonCVar)

	if (cvar and cvar:GetString() != self.lowHealthAddonEnforcedValue) then
		RunConsoleCommand(self.lowHealthAddonCVar, self.lowHealthAddonEnforcedValue)
	end
end

if (SERVER) then
	resource.AddWorkshop("652896605")

	function PLUGIN:InitializedPlugins()
		local cvar = GetConVar(self.lowHealthAddonCVar)

		if (cvar and cvar:GetString() != self.lowHealthAddonEnforcedValue) then
			game.ConsoleCommand(string.format("%s %s\n", self.lowHealthAddonCVar, self.lowHealthAddonEnforcedValue))
		end
	end

	function PLUGIN:PlayerInitialSpawn(client)
		timer.Simple(2, function()
			if (IsValid(client)) then
				client:ConCommand(self.lowHealthAddonCVar .. " " .. self.lowHealthAddonEnforcedValue)
			end
		end)
	end

	function PLUGIN:PlayerHurt(client, attacker, health, damage)
		if (IsLowHealthSuppressed(client)) then
			return false
		end

		if ((client.ixNextHurtEffect or 0) >= CurTime()) then
			return
		end

		client.ixNextHurtEffect = CurTime() + self.hurtFadeDelay

		if (damage > 10 and client:Armor() == 0) then
			local endurance = GetCharacterEndurance(client)
			local maxAttr = ix.config.Get("maxAttributes", 100)
			local effectiveDamage = damage - (endurance / maxAttr * 50)

			if (effectiveDamage <= 10) then
				client:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 235), 2.5, 0)
				client:ViewPunch(Angle(-1.3, 1.8, 0))
			end
		end
	end
else
	local MUFFLE_DSP = 14
	local NORMAL_DSP = 0
	local colorModify = {
		["$pp_colour_addr"] = 0,
		["$pp_colour_addg"] = 0,
		["$pp_colour_addb"] = 0,
		["$pp_colour_brightness"] = -0.02,
		["$pp_colour_contrast"] = 1,
		["$pp_colour_colour"] = 1,
		["$pp_colour_mulr"] = 0,
		["$pp_colour_mulg"] = 0,
		["$pp_colour_mulb"] = 0
	}

	local intensity = 0
	local pulseAlpha = 0
	local nextHeartbeat = 0
	local vignette = Material(PLUGIN.vignetteMaterialPath, "smooth")

	local enforcedConVars = {
		etb_healtheffect_system = "0"
	}

	local function IsEffectBlocked(client)
		if not IsValid(client) then
			return true
		end

		if not client:Alive() then
			return true
		end

		if IsLowHealthSuppressed(client) then
			return true
		end

		if not client:GetCharacter() then
			return true
		end

		return not ix.config.Get("hurtEffectEnabled", true)
	end

	local function GetLowHealthFraction(client)
		local threshold = math.max(ix.config.Get("hurtEffectThreshold", 25), 1)
		local health = math.max(client:Health(), 0)

		return math.Clamp(1 - math.Clamp(health / threshold, 0, 1), 0, 1)
	end

	local function ResetDSP(client)
		if (client.ixLowHealthDSPApplied) then
			client:SetDSP(NORMAL_DSP)
			client.ixLowHealthDSPApplied = nil
		end
	end

	function PLUGIN:InitializedPlugins()
		self:EnforceAddonConVars()
	end

	function PLUGIN:Think()
		self:EnforceAddonConVars()

		local client = LocalPlayer()

		if IsEffectBlocked(client) then
			intensity = math.Approach(intensity, 0, FrameTime() * 3)
			pulseAlpha = math.Approach(pulseAlpha, 0, FrameTime() * 6)

			if (IsValid(client)) then
				ResetDSP(client)
			end

			return
		end

		local frameTime = FrameTime()
		local healthFraction = GetLowHealthFraction(client)
		local muffleThreshold = ix.config.Get("hurtEffectMuffleThreshold", 10)

		intensity = math.Approach(intensity, healthFraction, frameTime * 3)

		if (ix.config.Get("hurtEffectMuffle", true) and client:Health() <= muffleThreshold) then
			if not client.ixLowHealthDSPApplied then
				client:SetDSP(MUFFLE_DSP)
				client.ixLowHealthDSPApplied = true
			end
		else
			ResetDSP(client)
		end

		if (ix.config.Get("hurtEffectHeartbeat", true) and intensity > 0.05 and CurTime() >= nextHeartbeat) then
			local delay = Lerp(intensity, 1.3, 0.45)
			local pitch = Lerp(intensity, 100, 118)
			local volume = Lerp(intensity, 0.2, 0.75)

			client:EmitSound(PLUGIN.heartbeatSound, 45, pitch, volume)
			nextHeartbeat = CurTime() + delay
		end

		local pulseTarget = 0.3 + math.abs(math.sin(CurTime() * Lerp(intensity, 1, 3.5))) * 0.7
		pulseAlpha = math.Approach(pulseAlpha, pulseTarget, frameTime * 8)
	end

	function PLUGIN:RenderScreenspaceEffects()
		local client = LocalPlayer()

		if IsEffectBlocked(client) then
			return
		end

		if (intensity <= 0.01) then
			return
		end

		colorModify["$pp_colour_colour"] = 1 - (0.45 * intensity)
		colorModify["$pp_colour_brightness"] = -0.02 - (0.035 * intensity)
		colorModify["$pp_colour_contrast"] = 1 + (0.15 * intensity)
		colorModify["$pp_colour_addg"] = -0.005 * intensity
		colorModify["$pp_colour_addb"] = -0.01 * intensity

		DrawColorModify(colorModify)
	end

	function PLUGIN:HUDPaint()
		local client = LocalPlayer()

		if IsEffectBlocked(client) or intensity <= 0.01 then
			return
		end

		local width, height = ScrW(), ScrH()

		if (ix.config.Get("hurtEffectVignette", true)) then
			surface.SetMaterial(vignette)
			surface.SetDrawColor(0, 0, 0, math.floor(210 * intensity))
			surface.DrawTexturedRect(0, 0, width, height)
		end

		if (ix.config.Get("hurtEffectRedFlash", true)) then
			local alpha = math.floor(65 * intensity * pulseAlpha)

			surface.SetDrawColor(180, 15, 15, alpha)
			surface.DrawRect(0, 0, width, height)
		end
	end

	function PLUGIN:PlayerDeath()
		local client = LocalPlayer()

		if (IsValid(client)) then
			ResetDSP(client)
		end

		intensity = 0
		pulseAlpha = 0
		nextHeartbeat = 0
	end

	function PLUGIN:OnReloaded()
		timer.Simple(0, function()
			local client = LocalPlayer()

			if (IsValid(client)) then
				ResetDSP(client)
			end

			self:EnforceAddonConVars()
		end)
	end

	for cvarName, enforcedValue in pairs(enforcedConVars) do
		cvars.AddChangeCallback(cvarName, function(_, _, newValue)
			if (newValue != enforcedValue) then
				timer.Simple(0, function()
					RunConsoleCommand(cvarName, enforcedValue)
				end)
			end
		end, "ixHurtEffectLock_" .. cvarName)
	end
end
