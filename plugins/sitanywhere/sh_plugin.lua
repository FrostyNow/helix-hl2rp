local PLUGIN = PLUGIN
PLUGIN.name = "Sit Anywhere"
PLUGIN.author = "Frosty"
PLUGIN.description = "Allows players to sit anywhere. Ported and modified from Sit Anywhere addon by Xerasin."

ix.util.Include("sv_plugin.lua", "server")
ix.util.Include("cl_plugin.lua", "client")

local SitAnywhere = PLUGIN

SitAnywhere.NET = {
	["SitWantedAng"] = 0,
	["SitRequestExit"] = 1,
}

SitAnywhere.ClassBlacklist = {
	["gmod_wire_keyboard"] = true,
	["prop_combine_ball"] = true
}

SitAnywhere.DoNotParent = {
	["yava_chunk"] = true
}
SitAnywhere.ModelBlacklist = {
}

local EMETA = FindMetaTable("Entity")

function SitAnywhere.GetAreaProfile(pos, resolution, simple)
	local filter = player.GetAll()
	local dists = {}
	local distsang = {}
	local ang_smallest_hori = nil
	local smallest_hori = 90000
	local angPerIt = (360 / resolution)
	for I = 0, 360, angPerIt do
		local rad = math.rad(I)
		local dir = Vector(math.cos(rad), math.sin(rad), 0)
		local trace = util.QuickTrace(pos + dir * 20 + Vector(0,0,5), Vector(0,0,-15000), filter)
		trace.HorizontalTrace = util.QuickTrace(pos + Vector(0,0,5), dir * 1000, filter)
		trace.Distance  =  trace.StartPos:Distance(trace.HitPos)
		trace.Distance2 = trace.HorizontalTrace.StartPos:Distance(trace.HorizontalTrace.HitPos)
		trace.ang = I

		if (not trace.Hit or trace.Distance > 14) and (not trace.HorizontalTrace.Hit or trace.Distance2 > 20) then
			if simple then return true end
			table.insert(dists, trace)
		end
		if trace.Distance2 < smallest_hori and (not trace.HorizontalTrace.Hit or trace.Distance2 > 3) then
			smallest_hori = trace.Distance2
			ang_smallest_hori = I
		end
		distsang[I] = trace
	end

	if simple then return false end
	return dists, distsang, ang_smallest_hori, smallest_hori
end

function SitAnywhere.CheckValidAngForSit(pos, surfaceAng, ang)
	local rad = math.rad(ang)
	local dir = Vector(math.cos(rad), math.sin(rad), 0)
	local trace2 = util.TraceLine({
		start = pos - dir * (20 - .5) + surfaceAng:Forward() * 5,
		endpos = pos - dir * (20 - .5) + surfaceAng:Forward() * -160,
		filter = player.GetAll()
	})

	local hor_trace = util.TraceLine({
		start = pos + Vector(0, 0, 5),
		endpos = pos + Vector(0, 0, 5) - dir * 1600,
		filter = player.GetAll()
	})

	return hor_trace.StartPos:Distance(hor_trace.HitPos) > 20 and trace2.StartPos:Distance(trace2.HitPos) > 14
end

ix.config.Add("sittingEntMode", 3, "Which entities players are allowed to sit on.\n0 = No entities\n1 = World entities only\n2 = Self-Owned, World, Unowned\n3 = Any Entity", nil, {
	data = {min = 0, max = 3},
	category = "sitAnywhere"
})
ix.config.Add("sittingCanSitOnPlayers", false, "Allows players to sit on SitAnywhere sitting players", nil, {
	category = "sitAnywhere"
})
ix.config.Add("sittingCanSitOnPlayerEnt", false, "Allows players to sit on actual player entities", nil, {
	category = "sitAnywhere"
})
ix.config.Add("sittingCanDamagePlayersSitting", true, "Allows damaging sitting players", nil, {
	category = "sitAnywhere"
})
ix.config.Add("sittingAdminOnly", false, "Locks sitting to admins only", nil, {
	category = "sitAnywhere"
})
ix.config.Add("sittingAntiPropSurf", true, "Disables the use of the physgun on contraptions with someone sitting on them", nil, {
	category = "sitAnywhere"
})
ix.config.Add("sittingAntiToolAbuse", true, "Disables the use of the toolgun on contraptions with someone sitting on them", nil, {
	category = "sitAnywhere"
})
ix.config.Add("sittingAllowTightPlaces", false, "Allows sitting in places where a player cannot physically stand", nil, {
	category = "sitAnywhere"
})
ix.config.Add("sittingForceNoWalk", false, "Disables the need for using walk to sit anywhere", nil, {
	category = "sitAnywhere"
})
ix.config.Add("sittingAllowGroundSit", true, "Allows people to sit on the ground", nil, {
	category = "sitAnywhere"
})

ix.option.Add("sittingGroundSit", ix.type.bool, true, {
	category = "sitAnywhere",
	default = true,
	bNetworked = true
})
ix.option.Add("sittingUseWalk", ix.type.bool, true, {
	category = "sitAnywhere",
	default = true
})
ix.option.Add("sittingForceLeftAlt", ix.type.bool, false, {
	category = "sitAnywhere",
	default = false
})
ix.option.Add("sittingAllowOnMe", ix.type.bool, true, {
	category = "sitAnywhere",
	default = true,
	bNetworked = true
})

if (SERVER) then
	-- Fix for ply:GetInfoNum compatibility with new options if called in sv_plugin
	util.AddNetworkString("ix_sitanywhere_dummy")
end

ix.lang.AddTable("english", {
	optSittingGroundSit = "Enable Ground Sit",
	optdSittingGroundSit = "Toggles the ability for you to sit on the ground.",
	optSittingUseWalk = "Require Walk to Sit",
	optdSittingUseWalk = "Makes sitting require the use of the walk key. Disable to sit with 'USE' only.",
	optSittingForceLeftAlt = "Force Left Alt",
	optdSittingForceLeftAlt = "Forces Left Alt to always act as a walk key for sitting.",
	optSittingAllowOnMe = "Allow Sitting on Me",
	optdSittingAllowOnMe = "Allows other people to sit on you."
})

ix.lang.AddTable("korean", {
	["sitAnywhere"] = "어디에나 앉기",
	optSittingGroundSit = "바닥에 앉기 활성화",
	optdSittingGroundSit = "바닥에 앉는 기능을 사용할지 켜고 끕니다.",
	optSittingUseWalk = "앉을 때 걷기 키 필요",
	optdSittingUseWalk = "앉으려면 걷기 키를 누른 채 상호작용해야 합니다. 체크 해제 시 'USE'키만으로도 바로 앉습니다.",
	optSittingForceLeftAlt = "왼쪽 Alt 강제",
	optdSittingForceLeftAlt = "왼쪽 Alt 키를 앉기용 걷기 키로 항상 강제로 사용합니다.",
	optSittingAllowOnMe = "내 위에 앉기 허용",
	optdSittingAllowOnMe = "다른 플레이어가 내 캐릭터 위에 앉는 것을 허용합니다."
})

local blacklist = SitAnywhere.ClassBlacklist
local model_blacklist = SitAnywhere.ModelBlacklist
function SitAnywhere.ValidSitTrace(ply, EyeTrace)
	if not EyeTrace.Hit then return false end
	if EyeTrace.HitPos:Distance(EyeTrace.StartPos) > 160 then return false end
	local t = hook.Run("CheckValidSit", ply, EyeTrace)

	if t == false or t == true then
		return t
	end

	if not EyeTrace.HitWorld and ix.config.Get("sittingEntMode", 3) == 0 then return false end
	if not EyeTrace.HitWorld and blacklist[string.lower(EyeTrace.Entity:GetClass())] then return false end
	if not EyeTrace.HitWorld and EyeTrace.Entity:GetModel() and model_blacklist[string.lower(EyeTrace.Entity:GetModel())] then return false end

	if EMETA.CPPIGetOwner and ix.config.Get("sittingEntMode", 3) >= 1 then
		if ix.config.Get("sittingEntMode", 3) == 1 then
			if not EyeTrace.HitWorld then
				local owner = EyeTrace.Entity:CPPIGetOwner()
				if type(owner) == "Player" and owner ~= nil and owner:IsValid() and owner:IsPlayer() then
					return false
				end
			end
		elseif ix.config.Get("sittingEntMode", 3) == 2 then
			if not EyeTrace.HitWorld then
				local owner = EyeTrace.Entity:CPPIGetOwner()
				if type(owner) == "Player" and owner ~= nil and owner:IsValid() and owner:IsPlayer() and owner ~= ply then
					return false
				end
			end
		end
	end
	return true
end

local seatClass = "prop_vehicle_prisoner_pod"
local PMETA = FindMetaTable("Player")

function PMETA:GetSitters()
	local seats, holders = {}, {}

	local function processSeat(seat, depth)
		depth = (depth or 0) + 1
		if IsValid(seat:GetDriver()) and seat:GetDriver() ~= self then
			table.insert(seats, seat)
		end
		for _, v in pairs(seat:GetChildren()) do
			if IsValid(v) and v:GetClass() == seatClass and IsValid(v:GetDriver()) and #v:GetChildren() > 0 and depth <= 128 then
				processSeat(v, depth)
			end
		end
	end

	local plyVehicle = self:GetVehicle()
	if IsValid(plyVehicle) and plyVehicle:GetClass() == seatClass then
		processSeat(plyVehicle)
	end

	for _, v in pairs(self:GetChildren()) do
		if IsValid(v) and v:GetClass() == seatClass then
			processSeat(v)
		end
	end

	for _, v in pairs(ents.FindByClass("sit_holder")) do
		if v.GetTargetPlayer and v:GetTargetPlayer() == self then
			table.insert(holders, v)
			if v.GetSeat and IsValid(v:GetSeat()) then
				processSeat(v:GetSeat())
			end
		end
	end
	return seats, holders
end

function PMETA:IsPlayerSittingOn(ply)
	local seats = ply:GetSitters()
	for _,v in pairs(seats) do
		if IsValid(v:GetDriver()) and v:GetDriver() == self then return true end
	end
	return false
end

function PMETA:GetSitting()
	if not IsValid(self:GetVehicle()) then return false end
	local veh = self:GetVehicle()
	if veh:GetNWBool("playerdynseat", false) then
		local parent = veh:GetParent()
		if IsValid(parent) and parent:GetClass() == "sit_holder" then
			return veh, parent
		else
			return veh
		end
	end
	return false
end

function PMETA:ExitSit()
	if CLIENT then
		if self ~= LocalPlayer() then return end
		net.Start("SitAnywhere")
			net.WriteInt(SitAnywhere.NET.SitRequestExit, 4)
		net.SendToServer()
	else
		local seat, holder = self:GetSitting()
		SafeRemoveEntity(seat)
		SafeRemoveEntity(holder)

		if SitAnywhere.GroundSit and self:GetNWBool("SitGroundSitting", false) then
			self:SetNWBool("SitGroundSitting", false)
		end
	end
end

function EMETA:IsSitAnywhereSeat()
	if self:GetClass() ~= "prop_vehicle_prisoner_pod" then return false end
	if SERVER and self.playerdynseat then return true end
	return self:GetNWBool("playerdynseat", false)
end

-- Ground Sit Logic
SitAnywhere.GroundSit = true
local TAG = "SitAnyG_"

hook.Add("SetupMove", TAG .. "SetupMove", function(ply, mv)
	local butts = mv:GetButtons()

	if not ply:GetNWBool(TAG) then
		return
	end

	local getUp = bit.band(butts, IN_JUMP) == IN_JUMP or ply:GetMoveType() ~= MOVETYPE_WALK or ply:InVehicle() or not ply:Alive()

	if getUp then
		ply:SetNWBool(TAG, false)
	end

	local move = bit.band(butts, IN_DUCK) == IN_DUCK

	butts = bit.bxor(bit.bor(butts, bit.bor(IN_JUMP, IN_DUCK)), IN_JUMP)

	if move then
		butts =  bit.bxor(bit.bor(bit.bor(butts, IN_WALK), IN_SPEED), IN_SPEED)

		mv:SetButtons(butts)
		return
	end

	mv:SetButtons(butts)
	mv:SetSideSpeed(0)
	mv:SetForwardSpeed(0)
	mv:SetUpSpeed(0)
end)

hook.Add("CalcMainActivity", TAG .. "CalcMainActivity", function(ply, vel)
	local seq = ply:LookupSequence("pose_ducking_02")
	if ply:GetNWBool(TAG) and seq and vel:Length2DSqr() < 1 then
		return ACT_MP_SWIM, seq
	else
		return
	end
end)

-- Fix for Chair Sitting Animation (The Porting Request Requirement)
hook.Add("CalcMainActivity", "SitAnywhere_ChairFix", function(ply, velocity)
	local veh = ply:GetVehicle()
	if IsValid(veh) and veh.playerdynseat then
		-- Force chair sit animation instead of prison pod animation.
		return ACT_GMOD_SIT_ROLLERCOASTER, -1
	end
end)

if SERVER then
	hook.Add("HandleSit", "GroundSit", function(ply, dists, EyeTrace)
		if #dists == 0 and ix.option.Get(ply, "sittingGroundSit", true) and ix.config.Get("sittingAllowGroundSit", true) and ply:EyeAngles().p > 80 then
			local t = hook.Run("OnGroundSit", ply, EyeTrace)
			if t == false then
				return
			end

			if not ply:GetNWBool(TAG) then
				ply:SetNWBool(TAG, true)
				ply.LastSit = CurTime() + 1
				return true
			end
		end
	end)

	concommand.Add("ground_sit", function(ply)
		if ix.config.Get("sittingAllowGroundSit", true) and (not ply.LastSit or ply.LastSit < CurTime()) then
			ply:SetNWBool(TAG, not ply:GetNWBool(TAG))
			ply.LastSit = CurTime() + 1
		end
	end)
end
