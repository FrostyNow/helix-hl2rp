ITEM.name = "EMP Tool"
ITEM.description = "itemEMPDesc"
ITEM.category = "Utility"
ITEM.model = "models/alyx_emptool_prop.mdl"
ITEM.skin = 0
ITEM.width = 1
ITEM.height = 1
ITEM.price = 160

local ATTEMPTS_KEY = "empAttempts"
local BASE_SUCCESS_CHANCE = 55
local BASE_BREAK_CHANCE = 5
local FAILURE_CHANCE_PER_USE = 4
local BREAK_CHANCE_PER_USE = 2
local MAX_SUCCESS_CHANCE = 92
local MAX_BREAK_CHANCE = 55

local function GetLuckBonus(client)
	local character = IsValid(client) and client:GetCharacter()
	if (!character) then
		return 0
	end

	local luck = character:GetAttribute("lck", 0)
	local maxAttributes = math.max(ix.config.Get("maxAttributes", 100), 1)
	local luckMultiplier = ix.config.Get("luckMultiplier", 1)

	return (luck / maxAttributes) * 35 * luckMultiplier
end

local function GetAttemptCount(itemTable)
	return math.max(tonumber(itemTable:GetData(ATTEMPTS_KEY, 0)) or 0, 0)
end

local function RecordAttempt(itemTable)
	local attempts = GetAttemptCount(itemTable) + 1
	itemTable:SetData(ATTEMPTS_KEY, attempts)

	return attempts
end

local function RollEMPOutcome(itemTable, client)
	local attempts = RecordAttempt(itemTable)
	local luckBonus = GetLuckBonus(client)
	local successChance = math.Clamp(BASE_SUCCESS_CHANCE - (attempts - 1) * FAILURE_CHANCE_PER_USE + luckBonus, 5, MAX_SUCCESS_CHANCE)
	local breakChance = math.Clamp(BASE_BREAK_CHANCE + (attempts - 1) * BREAK_CHANCE_PER_USE - luckBonus * 0.35, 0, MAX_BREAK_CHANCE)
	local succeeded = math.Rand(0, 100) <= successChance
	local broke = math.Rand(0, 100) <= breakChance

	return succeeded, broke, attempts
end

local function FinalizeEMPAttempt(itemTable, client)
	local succeeded, broke = RollEMPOutcome(itemTable, client)

	if (broke) then
		client:NotifyLocalized("empBroken")
	end

	return succeeded, broke
end

ITEM.functions.Use = {
	name = "empUseAction",
	icon = "icon16/lightning.png",
	OnRun = function(itemTable)
		local ply = itemTable.player
		local data = {}
			data.start = ply:GetShootPos()
			data.endpos = data.start + ply:GetAimVector() * 96
			data.filter = ply
		local target = util.TraceLine(data).Entity
		local plugin = ix.plugin.Get("interactive_computers")
		local resolved = plugin and plugin:ResolveComputerEntity(target)
		local useDoor = IsValid(target) and target:IsDoor() and !(target:HasSpawnFlags(256) and target:HasSpawnFlags(1024))
		local useTerminal = plugin and IsValid(resolved) and resolved.IsCombineTerminal and resolved:IsCombineTerminal()

		local useTurret = IsValid(target) and target:GetClass() == "npc_turret_floor" and target:GetSkin() == 0 and !target:GetNWBool("ixHacked")

		if (!useDoor and !useTerminal and !useTurret) then
			ply:NotifyLocalized("empInvalidTarget")
			return false
		end

		ply:EmitSound("ambient/machines/combine_terminal_idle2.wav")
		ply:SetAction("@empOverloading", 3)
		ply:DoStaredAction(target, function()
			if (!IsValid(ply) or (!IsValid(target) and !IsValid(resolved))) then
				return
			end

			local succeeded, broke = FinalizeEMPAttempt(itemTable, ply)

			if (succeeded) then
				if (useDoor and IsValid(target)) then
					if (IsValid(target.ixLock)) then
						target.ixLock:SetLocked(false)
					end

					target:Fire("unlock")
					target:Fire("open")
					ply:EmitSound("buttons/combine_button1.wav")
					ply:NotifyLocalized("empOverloadDoorSucceed")
				elseif (useTerminal and plugin and IsValid(resolved)) then
					plugin:TryBypassSecurity(ply, resolved)
				elseif (useTurret and IsValid(target)) then
					target:SetNWBool("ixHacked", true)

					local factionNPCs = ix.plugin.Get("factionnpcs")
					if (factionNPCs) then
						for _, v in ipairs(player.GetAll()) do
							factionNPCs:HandleNPCRelations(target, v)
						end
					end

					ply:EmitSound("buttons/combine_button1.wav")
					ply:NotifyLocalized("empOverloadTurretSucceed")
				end
			else
				ply:EmitSound("ambient/energy/zap1.wav")
				ply:NotifyLocalized("empFailed")
			end

			if (broke) then
				itemTable:Remove()
			end
		end, 3, function()
			if (IsValid(ply)) then
				ply:SetAction()
			end
		end)

		return false
	end
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local attempts = GetAttemptCount(self)

		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()

		local wear = tooltip:AddRow("empWear")
		wear:SetText(string.format("%s: %d", L("empInstabilityLevel"), attempts))
		wear:SizeToContents()
	end
end
