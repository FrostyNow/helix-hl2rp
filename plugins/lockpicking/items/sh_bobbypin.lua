ITEM.name = "Bobby pin box"
ITEM.description = "itemBobbyPinDesc"
ITEM.model = "models/props_lab/box01a.mdl"
ITEM.category = "Utility"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 90
ITEM.pinAmount = 10
ITEM.startingPinHealth = 20
ITEM.noBusiness = true

----------------
-- [[ Data ]] --
----------------
local conditions = {
	[0.85] = {"lockpickingExcellent", Color(0, 179, 0)},
	[0.55] = {"lockpickingWell", Color(255, 255, 0)},
	[0.35] = {"lockpickingWeak", Color(255, 140, 26)},
	[0.25] = {"lockpickingBad", Color(255, 51, 0)},
	[0] = {"lockpickingVeryBad", Color(102, 0, 0)}
}

function ITEM:GetCondition()
	local pinHealth = self:GetData("health", self.startingPinHealth)

	for k, v in SortedPairs(conditions, true) do
		if ( pinHealth >= self.startingPinHealth * k ) then
			return v[1], v[2]
		end
	end
end

function ITEM:GetQuantity()
	return self:GetData("quantity", self.pinAmount)
end

------------------
-- [[ Action ]] --
------------------
local function IsDoorLocked(ent)
	return ent:GetSaveTable().m_bLocked or ent.locked or false
end

local function GetDoorLockpicker(door)
	local session = door.LockpickingSession

	if (session) then
		return session.Player
	end
end

ITEM.functions.use = {
	name = "lockpickingPick",
	tip = "useTip",
	icon = "icon16/lock_break.png",
	OnRun = function(item)
		local client = item.player
		local ent = LockpickingPlugin:GetEntityLookedAt(client, ix.config.Get("lockpickMaxLookDistance"))

		if ( IsValid(ent.ixLock) ) then
			client:NotifyLocalized("cannotPickComlock")
			return false
		end

		if ( IsDoorLocked(ent) and not GetDoorLockpicker(ent) ) then
			local session = LockpickingPlugin:StartServerSession(ent, client, item)

			if ( type(session) == "string" ) then
				client:NotifyLocalized(session)
			end
		end
		
		return false
	end,
	OnCanRun = function(item)
		local client
		if ( SERVER ) then 
			client = item.player 
		else 
			client = LocalPlayer() 
		end
		
		local ent = LockpickingPlugin:GetEntityLookedAt(client, ix.config.Get("lockpickMaxLookDistance"))

		if ( IsValid(ent) and ent:IsDoor() ) then
			if ( SERVER ) then
				if ( not IsDoorLocked(ent) ) then
					client:NotifyLocalized("lockpickingNotLocked")
				elseif ( GetDoorLockpicker(ent) ) then
					client:NotifyLocalized("lockpickingAlreadyLocked")
				elseif ( IsValid(ent.ixLock) ) then
					client:NotifyLocalized("cannotPickComlock")
					return false
				end
			end

			return true
		else
			return false
		end
	end
}

function ITEM:PinBreak()
	local oldQuantity = self:GetQuantity()

	if ( oldQuantity == 1 ) then
		self:Remove()
		return false
	else
		self:SetData("health", self.startingPinHealth)
		self:SetData("quantity", oldQuantity - 1)
		return true
	end
end

function ITEM:OnRemoved()
    local session = self.LockpickingSession

	if ( session ) then
		session:Stop()
	end
end

------------------------------
-- [[ In Helix menus ]] --
------------------------------
if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		local quantity = item:GetQuantity()
		draw.SimpleText(
			quantity, "DermaDefault", w - 5, h - 5,
			color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, color_black
		)
	end

	function ITEM:PopulateTooltip(tooltip)
		local condition = tooltip:AddRow("condition")
		local state, color = self:GetCondition()
		local localizedText = L("lockpickingCondition", L(state))

		condition:SetText(localizedText)
		condition:SetBackgroundColor(color)
		condition:SetExpensiveShadow(0.5)
		condition:SizeToContents()
	end
end