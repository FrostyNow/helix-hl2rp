
local PLUGIN = PLUGIN

ENT.Type = "anim"
ENT.PrintName = "Base Station"
ENT.Category = "Helix"
ENT.Spawnable = false
ENT.AdminOnly = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "StationID")

	if (SERVER) then
		self:NetworkVarNotify("StationID", self.OnVarChanged)
	end
end

if (SERVER) then
	util.AddNetworkString("ixStationOpen")

	function ENT:Initialize()
		if (!self.uniqueID) then
			local class = self:GetClass()
			if (class:sub(1, 11) == "ix_station_") then
				self.uniqueID = class:sub(12)
			end
		end

		if (!self.uniqueID and self:GetClass() != "ix_station") then
			print("[Helix] Error: Station spawned without uniqueID! (" .. self:GetClass() .. ")")
			self:Remove()

			return
		end

		if (self.uniqueID) then
			self:SetStationID(self.uniqueID)
			
			local stationTable = self:GetStationTable()
			if (!stationTable) then
				for k, v in pairs(PLUGIN.craft.stations) do
					if (k:lower() == self.uniqueID:lower()) then
						stationTable = v
						self:SetStationID(k)
						break
					end
				end
			end

			if (stationTable) then
				self:SetModel(stationTable:GetModel())
			end
		end

		if (self:GetModel() == "" or self:GetModel() == "models/error.mdl") then
			self:SetModel("models/props_junk/watermelon01.mdl")
		end

		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
		
		if (!self:PhysicsInit(SOLID_VPHYSICS)) then
			self:PhysicsInitStatic(SOLID_VPHYSICS)
		end

		self:SetUseType(SIMPLE_USE)

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(false)
			physObj:Sleep()
		end
	end

	function ENT:Use(activator, caller)
		if (!IsValid(activator) or !activator:IsPlayer()) then return end

		local character = activator:GetCharacter()
		if (!character) then return end

		local stationID = self:GetStationID()
		if (!stationID or stationID == "") then return end

		-- Store current station on the player for server-side validation
		activator.ixCurrentStation = stationID
		activator.ixCurrentStationEnt = self

		net.Start("ixStationOpen")
			net.WriteString(stationID)
			net.WriteUInt(self:EntIndex(), 16)
		net.Send(activator)
	end

	function ENT:OnVarChanged(name, oldID, newID)
		local stationTable = PLUGIN.craft.stations[newID]

		if (stationTable) then
			self:SetModel(stationTable:GetModel())
		end
	end

	function ENT:UpdateTransmitState()
		return TRANSMIT_PVS
	end
else
	ENT.PopulateEntityInfo = true

	function ENT:OnPopulateEntityInfo(tooltip)
		local stationTable = self:GetStationTable()

		if (stationTable) then
			PLUGIN:PopulateStationTooltip(tooltip, stationTable)
		end
	end

	function ENT:Draw()
		self:DrawModel()
	end
end

function ENT:GetStationTable()
	return PLUGIN.craft.stations[self:GetStationID()]
end
