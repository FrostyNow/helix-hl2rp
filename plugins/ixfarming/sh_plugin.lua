local PLUGIN = PLUGIN

PLUGIN.name = "Farming"
PLUGIN.author = "Frosty"
PLUGIN.description = "A plugin that allows players to grow crops in a farm box."

-- 3 in-game days = 3 * 24 * 60 * sec-per-min real seconds
local defaultGrowth = 3 * 24 * 60 * (ix.config and ix.config.Get("secondsPerMinute") or 60)

ix.config.Add("cropGrowthTime", defaultGrowth, "How much it takes for crops to fully grow (in seconds). Default: 3 in-game days", nil, {
	data = {min = 1, max = 864000},
	category = "Farming"
})

ix.config.Add("waterDrainTime", 180, "How often crops need water (in seconds). Default: 3 in-game hours", nil, {
	data = {min = 1, max = 48},
	category = "Farming"
})

if (SERVER) then
	function PLUGIN:SaveData()
		local data = {}

		for _, v in ipairs(ents.FindByClass("ix_farmbox")) do
			data[#data + 1] = {
				v:GetPos(),
				v:GetAngles(),
				v:GetCropType(),
				v:GetWaterAmount(),
				v:GetHasFertilizer(),
				v:GetProgress()
			}
		end

		self:SetData(data)
	end

	function PLUGIN:LoadData()
		local data = self:GetData()

		if (data) then
			for _, v in ipairs(data) do
				local entity = ents.Create("ix_farmbox")
				entity:SetPos(v[1])
				entity:SetAngles(v[2])
				entity:Spawn()

				entity:SetCropType(v[3] or "")
				entity:SetWaterAmount(v[4] or 0)
				entity:SetHasFertilizer(v[5] or false)
				entity:SetProgress(v[6] or 0)
				
				local phys = entity:GetPhysicsObject()

				if (IsValid(phys)) then
					phys:EnableMotion(false)
				end
			end
		end
	end
end
