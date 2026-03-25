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

ix.config.Add("waterDrainTime", 180, "How often crops need water. Default: 6 in-game hours", nil, {
	data = {min = 1, max = 720},
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

	util.AddNetworkString("ixFarmboxStartPlace")
	util.AddNetworkString("ixFarmboxPlace")

	net.Receive("ixFarmboxPlace", function(len, client)
		local pos = net.ReadVector()
		local ang = net.ReadAngle()

		local nextTime = client:GetCharacter():GetData("nextFarmboxTime", 0)
		if (nextTime > os.time()) then
			client:NotifyLocalized("farmboxCooldown", math.ceil((nextTime - os.time()) / 60))
			return
		end

		if (client:GetPos():DistToSqr(pos) > 40000) then return end

		local entity = ents.Create("ix_farmbox")
		entity:SetPos(pos)
		entity:SetAngles(ang)
		entity:Spawn()

		local phys = entity:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:EnableMotion(false)
		end

		client:GetCharacter():SetData("nextFarmboxTime", os.time() + 60)
		client:NotifyLocalized("farmboxPlaced")
	end)
end

if (CLIENT) then
	net.Receive("ixFarmboxStartPlace", function()
		if (IsValid(ix.gui.farmboxGhost)) then return end

		local farmboxGhost = ents.CreateClientProp("models/noble/limelight/farmbox.mdl")
		farmboxGhost:SetSolid(SOLID_VPHYSICS)
		farmboxGhost:SetRenderMode(RENDERMODE_TRANSALPHA)
		ix.gui.farmboxGhost = farmboxGhost
	end)

	function PLUGIN:Think()
		if (IsValid(ix.gui.farmboxGhost)) then
			local client = LocalPlayer()
			local character = client:GetCharacter()
			
			if (!character or !character:GetInventory():HasItem("shovel") or client:GetMoveType() == MOVETYPE_NOCLIP or !client:IsOnGround()) then
				ix.gui.farmboxGhost:Remove()
				return
			end

			local trace = util.TraceLine({
				start = client:EyePos(),
				endpos = client:EyePos() + client:GetAimVector() * 200,
				filter = {client, ix.gui.farmboxGhost}
			})

			local pos = trace.HitPos
			local ang = Angle(0, client:EyeAngles().y + 180, 0)
			
			ix.gui.farmboxGhost:SetPos(pos)
			ix.gui.farmboxGhost:SetAngles(ang)

			local mins, maxs = ix.gui.farmboxGhost:GetModelBounds()
			
			local tr = util.TraceHull({
				start = pos + Vector(0, 0, 5),
				endpos = pos + Vector(0, 0, 5),
				mins = mins + Vector(2, 2, 2),
				maxs = maxs - Vector(2, 2, 2),
				filter = {client, ix.gui.farmboxGhost}
			})

			if ((tr.Hit and not tr.HitWorld) or not trace.HitWorld or trace.HitNormal.z < 0.8) then
				ix.gui.farmboxGhost:SetColor(Color(255, 0, 0, 150))
				ix.gui.farmboxGhost.canPlace = false
			else
				ix.gui.farmboxGhost:SetColor(Color(0, 255, 0, 150))
				ix.gui.farmboxGhost.canPlace = true
			end
		end
	end

	function PLUGIN:PlayerBindPress(client, bind, pressed)
		if (IsValid(ix.gui.farmboxGhost) and pressed) then
			if (bind:find("attack2")) then
				ix.gui.farmboxGhost:Remove()
				surface.PlaySound("buttons/button10.wav")
				return true
			elseif (bind:find("attack")) then
				if (ix.gui.farmboxGhost.canPlace) then
					net.Start("ixFarmboxPlace")
					net.WriteVector(ix.gui.farmboxGhost:GetPos())
					net.WriteAngle(ix.gui.farmboxGhost:GetAngles())
					net.SendToServer()

					ix.gui.farmboxGhost:Remove()
					surface.PlaySound("buttons/button14.wav")
				else
					surface.PlaySound("buttons/button10.wav")
				end
				return true
			end
		end
	end
end
