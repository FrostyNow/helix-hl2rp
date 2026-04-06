
local PLUGIN = PLUGIN

function PLUGIN:OnLoaded()
	for _, path in ipairs(self.paths or {}) do
		self.craft.LoadFromDir(path.."/recipes", "recipe")
		self.craft.LoadFromDir(path.."/stations", "station")
	end
end

if SERVER then
	function PLUGIN:SaveData()
		local data = {}

		for _, v in ents.Iterator() do
			local class = v:GetClass()

			if (class == "ix_station" or string.match(class, "^ix_station_")) then
				local phys = v:GetPhysicsObject()

				data[#data + 1] = {
					class = class,
					pos = v:GetPos(),
					angles = v:GetAngles(),
					stationID = v:GetStationID(),
					isFrozen = (phys:IsValid() and !phys:IsMoveable())
				}
			end
		end

		self:SetData(data)
	end

	function PLUGIN:LoadData()
		local data = self:GetData()

		if (data) then
			for _, v in ipairs(data) do
				local entity = ents.Create(v.class)
				
				if (IsValid(entity)) then
					entity:SetPos(v.pos)
					entity:SetAngles(v.angles)
					entity:Spawn()

					if (v.stationID and v.stationID != "") then
						entity:SetStationID(v.stationID)
					end

					if (v.isFrozen) then
						local phys = entity:GetPhysicsObject()

						if (phys:IsValid()) then
							phys:EnableMotion(false)
						end
					end
				end
			end
		end
	end
end