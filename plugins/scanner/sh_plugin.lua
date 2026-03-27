local PLUGIN = PLUGIN

PLUGIN.name = "Player Scanners Util"
PLUGIN.description = "Adds functions that allow players to control scanners."
PLUGIN.author = "Chessnut, Riggs | Modified by Frosty"
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright 2022 Riggs Mackay

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

ix.lang.AddTable("english", {
	cmdPhotoCache = "Opens the scanner photo cache.",
	combineOnly = "Only Combine Players can view the scanner photo cache!",
	noScannerPlugin = "The server is missing the 'scanner' plugin.",
	scannerAlreadyOperating = "You are already operating a scanner.",
	scannerName = "Combine Scanner",
	scannerNameClaw = "Shield Scanner",
	scannerDesc = "A remotely operated surveillance unit used by the Combine.",
	scannerPilot = "Operated by: %s",
	scanning = "Scanning",
})
ix.lang.AddTable("korean", {
	cmdPhotoCache = "저장된 스캐너 사진을 확인합니다.",
	cacheCmbOnly = "콤바인 플레이어만 저장된 스캐너 사진을 확인할 수 있습니다!",
	noScannerPlugin = "이 서버에 'scanner' 플러그인이 없습니다.",
	scannerAlreadyOperating = "이미 조종 중인 스캐너가 있습니다.",
	scannerName = "콤바인 스캐너",
	scannerNameClaw = "실드 스캐너",
	scannerDesc = "콤바인에서 사용하는 원격 감시 유닛입니다.",
	scannerPilot = "조종자: %s",
	scanning = "스캐너 조종 중",
})

PLUGIN.callsigns = {
	"GHOST", "REAPER", "NOMAD", "HURRICANE", "PHANTOM", "JUDGE", "SHADOW", 
	"SLAM", "STINGER", "STORM", "VAMP", "WINDER", "STAR"
}

-- Unique Scanner names
function PLUGIN:GenerateUniqueScannerName(isClaw)
	local prefix = isClaw and "OTA.SHIELD-" or "c17:MPF-SCN."
	local callsign = table.Random(self.callsigns)
	local digit = math.random(1, 9)
	local name = prefix .. callsign .. ":" .. digit

	-- Prevent duplicated name
	if (SERVER) then
		local bUnique = false
		local attempts = 0
		while (!bUnique and attempts < 20) do
			bUnique = true
			for _, v in ipairs(ents.FindByClass("ix_scanner")) do
				if (v:GetNetVar("ixScannerName") == name) then
					bUnique = false
					callsign = table.Random(self.callsigns)
					digit = math.random(0, 9)
					name = prefix .. callsign .. ":" .. digit
					break
				end
			end
			attempts = attempts + 1
		end
	end

	return name
end

if ( CLIENT ) then
	PLUGIN.PICTURE_WIDTH = 700
	PLUGIN.PICTURE_HEIGHT = 525
end

ix.util.Include("sv_photos.lua")
ix.util.Include("cl_photos.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_hooks.lua")

ix.command.Add("PhotoCache", {
	description = "@cmdPhotoCache",
	OnRun = function(self, ply)
		if (ply:IsCombine() and Schema:CanPlayerSeeCombineOverlay(ply)) then
			ply:ConCommand("ix_scanner_photocache")
			return
		end

		for _, v in ipairs(ents.FindByClass("ix_ctocameraterminal")) do
			if (v:GetPos():DistToSqr(ply:GetPos()) <= 80 * 80) then
				ply:ConCommand("ix_scanner_photocache")
				return
			end
		end

		return "@cacheCmbOnly"
	end
})

-- Context menu property
properties.Add("ixScannerOperate", {
	MenuLabel = "Operate Scanner",
	Order = 500,
	MenuIcon = "icon16/eye.png",

	Filter = function(self, entity, ply)
		if not IsValid(entity) then return false end
		if entity:GetClass() ~= "ix_scanner" then return false end
		if not IsValid(ply) then return false end
		if not ply:IsAdmin() then return false end
		if not entity:canOperate(ply) then return false end
		if IsValid(entity:GetPilot()) then return false end
		return true
	end,

	Action = function(self, entity)
		self:MsgStart()
			net.WriteEntity(entity)
		self:MsgEnd()
	end,

	Receive = function(self, length, ply)
		if not ply:IsAdmin() then return end
		local entity = net.ReadEntity()
		if not IsValid(entity) or entity:GetClass() ~= "ix_scanner" then return end
		if IsValid(entity:GetPilot()) then return end

		entity.spawn = ply:GetPos()
		entity:setPilot(ply)
		ply.ixScn = entity
	end,
})

function PLUGIN:GetCharacterName(ply, chatType)
	local scanner = ply:GetNetVar("ixScn")
	if (IsValid(scanner) and (chatType == "ic" or chatType == "me" or chatType == "it" or chatType == "y" or chatType == "w" or chatType == "yell" or chatType == "whisper")) then
		return scanner:GetNetVar("ixScannerName", "Combine Scanner")
	end
end

function PLUGIN:GetCharacterColor(ply)
	local scanner = ply:GetNetVar("ixScn")

	if (IsValid(scanner)) then
		return Color(43, 64, 116)
	end
end

function PLUGIN:SetupMove(ply, mv, cmd)
	if (IsValid(ply:GetNetVar("ixScn"))) then
		mv:SetForwardSpeed(0)
		mv:SetSideSpeed(0)
		mv:SetVelocity(vector_origin)
	end
end

function PLUGIN:CalcMainActivity(ply, velocity)
	if (IsValid(ply:GetNetVar("ixScn"))) then
		return ply:GetSequenceActivity(ply:LookupSequence("idle_all_01") or 0), -1
	end
end

function PLUGIN:UpdateAnimation(ply, velocity, maxSeqGroundSpeed)
	if (IsValid(ply:GetNetVar("ixScn"))) then
		ply:SetPoseParameter("move_x", 0)
		ply:SetPoseParameter("move_y", 0)
		ply:SetPoseParameter("aim_yaw", 0)
		ply:SetPoseParameter("aim_pitch", 0)
		ply:SetPoseParameter("head_yaw", 0)
		ply:SetPoseParameter("head_pitch", 0)
		ply:SetPoseParameter("body_yaw", 0)
		ply:SetPoseParameter("spine_yaw", 0)
		ply:SetIK(false)

		return true
	end
end

function PLUGIN:CanPlayerRaiseWeapon(ply)
	if (IsValid(ply:GetNetVar("ixScn"))) then
		return false
	end
end

function PLUGIN:InitializedChatClasses()
	local proximityClasses = {"ic", "me", "it", "w", "y", "looc", "roll"}

	for _, id in ipairs(proximityClasses) do
		local class = ix.chat.classes[id]
		if (class) then
			class.CanHear = function(this, speaker, listener)
				local speakerScanner = speaker:GetNetVar("ixScn")
				local listenerScanner = listener:GetNetVar("ixScn")

				local speakPos = IsValid(speakerScanner) and speakerScanner:GetPos() or speaker:GetPos()
				local listenPos = IsValid(listenerScanner) and listenerScanner:GetPos() or listener:GetPos()
				local range = isnumber(this.range) and this.range or (ix.config.Get("chatRange", 280) ^ 2)

				return (speakPos - listenPos):LengthSqr() <= range
			end
		end
	end
end