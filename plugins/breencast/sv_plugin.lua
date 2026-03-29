local PLUGIN = PLUGIN

function PLUGIN:SaveData()
	local data = {}

	for _, v in ipairs(ents.FindByClass("ix_breencast")) do
		data[#data + 1] = {
			pos = v:GetPos(),
			ang = v:GetAngles(),
			interval = v:GetInterval(),
			looping = v:GetLooping(),
			playing = v:GetPlaying()
		}
	end

	self:SetData(data)
end

function PLUGIN:LoadData()
	local data = self:GetData()

	if (data) then
		for _, v in ipairs(data) do
			local entity = ents.Create("ix_breencast")
			entity:SetPos(v.pos)
			entity:SetAngles(v.ang)
			entity:Spawn()
			
			entity:SetInterval(v.interval or 10)
			entity:SetLooping(v.looping != false)
			
			if (v.playing) then
				entity:SetPlaying(true)
				entity:PlayNextBroadcast()
			end
		end
	end
end

ix.command.Add("BreenCastSet", {
	description = "Designate a Breen model to become a Breen Cast NPC.",
	adminOnly = true,
	OnRun = function(self, client)
		local trace = client:GetEyeTrace()
		local entity = trace.Entity

		if (IsValid(entity)) then
			if (entity:GetModel():find("breen.mdl")) then
				local pos = entity:GetPos()
				local ang = entity:GetAngles()
				
				entity:Remove()

				local newEntity = ents.Create("ix_breencast")
				newEntity:SetPos(pos)
				newEntity:SetAngles(ang)
				newEntity:Spawn()
				
				return "@breenCastSuccess"
			else
				return "@breenCastNoBreen"
			end
		else
			return "@breenCastNoEntity"
		end
	end
})
