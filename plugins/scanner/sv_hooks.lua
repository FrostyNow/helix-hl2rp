local PLUGIN = PLUGIN

local SCANNER_SOUNDS = {
	"npc/scanner/scanner_blip1.wav",
	"npc/scanner/scanner_scan1.wav",
	"npc/scanner/scanner_scan2.wav",
	"npc/scanner/scanner_scan4.wav",
	"npc/scanner/scanner_scan5.wav",
	"npc/scanner/combat_scan1.wav",
	"npc/scanner/combat_scan2.wav",
	"npc/scanner/combat_scan3.wav",
	"npc/scanner/combat_scan4.wav",
	"npc/scanner/combat_scan5.wav",
	"npc/scanner/cbot_servoscared.wav",
	"npc/scanner/cbot_servochatter.wav",
}

function PLUGIN:createScanner(ply, isClawScanner)
	if (IsValid(ply.ixScn)) then
		return
	end

	local entity = ents.Create("ix_scanner")
	if (not IsValid(entity)) then
		return
	end

	entity:SetPos(ply:EyePos() + ply:GetAimVector() * 80)
	entity:SetAngles(ply:GetAngles())
	entity:Spawn()
	entity:Activate()
	entity:SetNetVar("ixPlayer", ply)

	if (isClawScanner) then
		entity:setClawScanner()
	end

	return entity
end

function PLUGIN:PlayerSpawn(ply)
	if (IsValid(ply.ixScn)) then
		ply.ixScn:ejectPilot()
		ply:SetViewEntity(NULL)
	end
end

function PLUGIN:PlayerDeath(ply)
	if (IsValid(ply.ixScn)) then
		ply.ixScn:ejectPilot()
		ply:SetViewEntity(NULL)
	end
end

function PLUGIN:KeyPress(ply, key)
	if not IsValid(ply.ixScn) then return end

	if (key == IN_USE and ply:KeyDown(IN_WALK)) then
		ply.ixScn:ejectPilot()
		return
	end

	if ((ply.ixScnSoundDelay or 0) >= CurTime()) then return end

	local source

	if (key == IN_USE) then
		source = table.Random(SCANNER_SOUNDS)
		ply.ixScnSoundDelay = CurTime() + 1.75
	elseif (key == IN_RELOAD) then
		source = "npc/scanner/scanner_talk"..math.random(1, 2)..".wav"
		ply.ixScnSoundDelay = CurTime() + 8
	elseif (key == IN_DUCK) then
		if (ply:GetViewEntity() == ply.ixScn) then
			ply:SetViewEntity(NULL)
			ply:SetNetVar("ixScanning", false)
		else
			ply:SetViewEntity(ply.ixScn)
			ply:SetNetVar("ixScanning", true)
		end
	end

	if (source) then
		ply.ixScn:EmitSound(source)
	end
end

function PLUGIN:PlayerNoClip(ply)
	if (IsValid(ply.ixScn)) then
		return false
	end
end

function PLUGIN:CanPlayerReceiveScan(ply, photographer)
	return Schema and Schema.CanPlayerSeeCombineOverlay and Schema:CanPlayerSeeCombineOverlay(ply)
end

function PLUGIN:PlayerSwitchFlashlight(ply, enabled)
	local scanner = ply:GetNetVar("ixScn")
	if (not IsValid(scanner)) then return end

	if ((scanner.nextLightToggle or 0) >= CurTime()) then return false end
	scanner.nextLightToggle = CurTime() + 0.5

	local pitch
	if (scanner:isSpotlightOn()) then
		scanner:disableSpotlight()
		pitch = 240
	else
		scanner:enableSpotlight()
		pitch = 250
	end

	scanner:EmitSound("npc/turret_floor/click1.wav", 50, pitch)
	return false
end

function PLUGIN:PlayerCanPickupWeapon(ply, weapon)
	if (IsValid(ply.ixScn)) then
		return false
	end
end

function PLUGIN:PlayerDropItem(ply, item)
	if (IsValid(ply.ixScn)) then
		return false
	end
end

function PLUGIN:PlayerEquipItem(ply, item)
	if (IsValid(ply.ixScn)) then
		return false
	end
end

function PLUGIN:PlayerCanInteractItem(ply, item)
	if (IsValid(ply.ixScn)) then
		return false
	end
end

function PLUGIN:PlayerCanTakeItem(ply, item)
	if (IsValid(ply.ixScn)) then
		return false
	end
end

function PLUGIN:PlayerCanUnequipItem(ply, item)
	if (IsValid(ply.ixScn)) then
		return false
	end
end

function PLUGIN:PlayerFootstep(ply)
	if (IsValid(ply.ixScn)) then
		return true
	end
end

function PLUGIN:CanPlayerSay(ply, chatType, message, anonymous)
	if (IsValid(ply.ixScn)) then
		if (chatType == "w" or chatType == "y" or chatType == "whisper" or chatType == "yell") then
			return false -- Scanners cant yell/whisper!
		end
	end
end

function PLUGIN:GetListeningPos(ply)
	if (IsValid(ply.ixScn)) then
		return ply.ixScn:GetPos()
	end
end

function PLUGIN:SetupPlayerVisibility(ply)
	if (IsValid(ply.ixScn)) then
		AddOriginToPVS(ply.ixScn:GetPos())
	end
end

function PLUGIN:CanPlayerHold(ply, entity)
	if (entity:GetClass() == "ix_scanner") then
		return false
	end
end

if (SERVER) then
	util.AddNetworkString("ixScannerToggleFlashlight")

	net.Receive("ixScannerToggleFlashlight", function(len, ply)
		local scanner = ply:GetNetVar("ixScn")

		if (IsValid(scanner)) then
			if ((scanner.nextLightToggle or 0) >= CurTime()) then return end
			scanner.nextLightToggle = CurTime() + 0.5

			local pitch
			if (scanner:isSpotlightOn()) then
				scanner:disableSpotlight()
				pitch = 240
			else
				scanner:enableSpotlight()
				pitch = 250
			end

			scanner:EmitSound("npc/turret_floor/click1.wav", 50, pitch)
		end
	end)
end

function PLUGIN:PlayerSwitchWeapon(ply, oldWeapon, newWeapon)
	if (IsValid(ply:GetNetVar("ixScn"))) then
		return true
	end
end