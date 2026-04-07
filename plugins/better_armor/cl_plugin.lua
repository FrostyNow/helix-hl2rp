local PLUGIN = PLUGIN

local DEFAULT_GASMASK_BIND = "NONE"

local INVALID_BIND_CODES = {
	[KEY_ESCAPE] = true,
	[KEY_TAB] = true
}

local BIND_ALIASES = {
	[""] = "NONE",
	OFF = "NONE",
	DISABLE = "NONE",
	DISABLED = "NONE",
	ESC = "ESCAPE",
	RETURN = "ENTER"
}

local function resolveBindCode(bindText)
	local normalized = string.upper(string.Trim(tostring(bindText or "")))
	normalized = normalized:gsub("^KEY_", "")
	normalized = normalized:gsub("[%s%-]+", "_")
	normalized = BIND_ALIASES[normalized] or normalized

	if (normalized == "NONE") then
		return KEY_NONE, normalized
	end

	local keyCode = input.GetKeyCode and input.GetKeyCode(normalized) or nil

	if (isnumber(keyCode) and keyCode != KEY_NONE) then
		return keyCode, normalized
	end

	keyCode = _G[normalized]

	if (isnumber(keyCode)) then
		return keyCode, normalized
	end

	keyCode = _G["KEY_" .. normalized]

	if (isnumber(keyCode)) then
		return keyCode, normalized
	end
end

local function normalizeBindText(bindText)
	local keyCode, normalized = resolveBindCode(bindText)

	if (!isnumber(keyCode) or INVALID_BIND_CODES[keyCode]) then
		return nil
	end

	if (keyCode == KEY_NONE) then
		return "NONE", keyCode
	end

	local keyName = input.GetKeyName and input.GetKeyName(keyCode) or normalized

	if (!isstring(keyName) or keyName == "") then
		keyName = normalized
	end

	return string.upper(keyName), keyCode
end

local function getGasmaskBindCode()
	local _, keyCode = normalizeBindText(ix.option.Get("gasmaskKey", DEFAULT_GASMASK_BIND))

	if (isnumber(keyCode)) then
		return keyCode
	end

	return KEY_NONE
end

ix.option.Add("gasmaskKey", ix.type.string, DEFAULT_GASMASK_BIND, {
	name = "optGasmaskKey",
	category = "Better Armor",
	description = "optGasmaskKeyDesc",
	OnChanged = function(oldValue, value)
		local normalized = normalizeBindText(value)
		local nextValue = normalized or DEFAULT_GASMASK_BIND

		if (nextValue != value) then
			ix.option.Set("gasmaskKey", nextValue)
		end
	end
})

function PLUGIN:RenderScreenspaceEffects()
	local Warning = {"avoxgaming/gas_mask/gas_mask_light/gas_mask_light_breath1.wav", "avoxgaming/gas_mask/gas_mask_light/gas_mask_light_breath2.wav", "avoxgaming/gas_mask/gas_mask_light/gas_mask_light_breath3.wav", "avoxgaming/gas_mask/gas_mask_light/gas_mask_light_breath4.wav", "avoxgaming/gas_mask/gas_mask_light/gas_mask_light_breath5.wav"}
	local ran = math.random(1,table.getn(Warning))
	local Warning1 = {"avoxgaming/gas_mask/gas_mask_middle/gas_mask_middle_breath1.wav", "avoxgaming/gas_mask/gas_mask_middle/gas_mask_middle_breath2.wav", "avoxgaming/gas_mask/gas_mask_middle/gas_mask_middle_breath3.wav", "avoxgaming/gas_mask/gas_mask_middle/gas_mask_middle_breath4.wav", "avoxgaming/gas_mask/gas_mask_middle/gas_mask_middle_breath5.wav"}
	local ran1 = math.random(1,table.getn(Warning1))

	if (LocalPlayer():GetNetVar("gasmask") == true) then
		local colorModify = {}
		colorModify["$pp_colour_colour"] = 0.77

		if (system.IsWindows()) then
			colorModify["$pp_colour_brightness"] = -0.08
		end

		DrawColorModify(colorModify)

		local character = LocalPlayer():GetCharacter()
		local inventory = character:GetInventory()
		local items = inventory:GetItems()
		local armorHealth = 100
		for k, v in pairs(items) do
			if (v.base == "base_armor" and v:GetData("equip")) then
				armorHealth = v:GetData("Durability", 100)
			end
		end
		DrawMaterialOverlay( "nco/cinover", 0.1 )
		if (armorHealth <= 10) then
			DrawMaterialOverlay( "morganicism/metroredux/gasmask/metromask6", 0.5 )
		elseif (armorHealth <= 20) then
			DrawMaterialOverlay( "morganicism/metroredux/gasmask/metromask5", 0.5 )
		elseif (armorHealth <= 40) then
			DrawMaterialOverlay( "morganicism/metroredux/gasmask/metromask4", 0.5 )
		elseif (armorHealth < 60) then
			DrawMaterialOverlay( "morganicism/metroredux/gasmask/metromask3", 0.5 )
		elseif (armorHealth < 80) then
			DrawMaterialOverlay( "morganicism/metroredux/gasmask/metromask2", 0.5 )
		else
			DrawMaterialOverlay( "morganicism/metroredux/gasmask/metromask1", 0.5 )
		end

		if !LocalPlayer().enresp then
			LocalPlayer().enresp = true
			local duration = 3.5
			if LocalPlayer():KeyDown(IN_BULLRUSH) then
				surface.PlaySound( Warning1[ran1] )
				local duration = 2.5
			else
				surface.PlaySound( Warning[ran] )
				local duration = 3.5
			end
			timer.Simple(duration,function() LocalPlayer().enresp = false end)
		end
	else
		LocalPlayer().enresp = false
	end
end

local gasmaskKeyStart = 0

function PLUGIN:PlayerButtonDown(client, button)
	local bindCode = getGasmaskBindCode()

	if (CLIENT and !gui.IsGameUIVisible() and !gui.IsConsoleVisible() and !vgui.GetKeyboardFocus() and bindCode != KEY_NONE and button == bindCode) then
		gasmaskKeyStart = CurTime()
	end
end

function PLUGIN:PlayerButtonUp(client, button)
	local bindCode = getGasmaskBindCode()

	if (CLIENT and bindCode != KEY_NONE and button == bindCode and gasmaskKeyStart > 0) then
		local duration = CurTime() - gasmaskKeyStart
		gasmaskKeyStart = 0

		if (duration >= 2) then
			ix.command.Send("FilterSwap")
		elseif (!gui.IsGameUIVisible() and !gui.IsConsoleVisible() and !vgui.GetKeyboardFocus()) then
			ix.command.Send("Gasmask")
		end
	end
end