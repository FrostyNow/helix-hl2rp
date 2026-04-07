PLUGIN.name = "Combine Light"
PLUGIN.author = "robinkooli | Modified by Frosty"
PLUGIN.description = "Portable light sources used to illuminate dark areas in support of Combine operations."

ix.lang.AddTable("english", {
	comlightDesc = "Portable light sources used to illuminate dark areas in support of Combine operations.",
	combineLightPlaceMode = "Placing... (Left Click: Place, Right Click: Cancel)",
	combineLightPlaced = "The light has been placed.",
	combineLightTooFar = "You are too far away from the placement position!",
	combineLightNoFloor = "You can only place this on the floor!",
	combineLightOverlap = "The light is overlapping with another object!",
})

ix.lang.AddTable("korean", {
	["Combine Light"] = "콤바인 조명",
	comlightDesc = "어두운 곳에서 콤바인 작전을 수행할 수 있도록 돕는 이동식 광원입니다.",
	Place = "놓기",
	combineLightPlaceMode = "배치 중... (좌클릭: 배치, 우클릭: 취소, 휠: 회전)",
	combineLightPlaced = "조명을 배치했습니다.",
	combineLightTooFar = "배치 위치가 너무 멉니다!",
	combineLightNoFloor = "바닥 위에만 설치할 수 있습니다!",
	combineLightOverlap = "다른 물체와 겹쳐서 설치할 수 없습니다!",
})

if (SERVER) then
	util.AddNetworkString("ixCombineLightStartPlacement")
	util.AddNetworkString("ixCombineLightPlace")

	net.Receive("ixCombineLightPlace", function(len, client)
		local itemID = net.ReadUInt(32)
		local pos = net.ReadVector()
		local ang = net.ReadAngle()

		local item = ix.item.instances[itemID]
		if (!item or item:GetOwner() != client) then return end

		-- Strictly 100 units distance limit
		if (client:GetPos():DistToSqr(pos) > 10000) then
			client:NotifyLocalized("combineLightTooFar")
			return
		end

		local ent = ents.Create("hl2_combinelight")
		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:Spawn()
		ent:Activate()

		-- Overlap validation (Exclude floor collision for check)
		local boundsMin, boundsMax = ent:GetModelBounds()
		local hullTrace = util.TraceHull({
			start = pos + Vector(0, 0, 2), -- Offset from floor
			endpos = pos + Vector(0, 0, 2),
			mins = boundsMin + Vector(1, 1, 0), -- Slightly narrower to prevent edge overlap
			maxs = boundsMax - Vector(1, 1, 1),
			filter = {client, ent}
		})

		if (hullTrace.Hit) then
			ent:Remove()
			client:NotifyLocalized("combineLightOverlap")
			return
		end

		local phys = ent:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:EnableMotion(false)
		end

		hook.Run("PlayerSpawnedProp", client, item.model, ent)
		
		item:Remove()
		client:NotifyLocalized("combineLightPlaced")
	end)

	function PLUGIN:SaveData()
		local data = {}

		local entities = {
			"hl2_combinelight",
			"hl2_combinelight_wall",
		}

		for _, class in ipairs(entities) do
			for _, v in ipairs(ents.FindByClass(class)) do
				local phys = v:GetPhysicsObject()

				data[#data + 1] = {
					class = class,
					pos = v:GetPos(),
					angles = v:GetAngles(),
					color = v:GetColor(),
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
				entity:SetPos(v.pos)
				entity:SetAngles(v.angles)
				entity:SetColor(v.color)
				entity:Spawn()

				if (v.isFrozen) then
					local phys = entity:GetPhysicsObject()

					if (phys:IsValid()) then
						phys:EnableMotion(false)
					end
				end
			end
		end
	end
else
	net.Receive("ixCombineLightStartPlacement", function()
		local itemID = net.ReadUInt(32)
		local model = net.ReadString()

		if (IsValid(ix.gui.combineLightGhost)) then
			ix.gui.combineLightGhost:Remove()
		end

		local ghost = ents.CreateClientProp(model)
		ghost:SetSolid(SOLID_VPHYSICS)
		ghost:SetRenderMode(RENDERMODE_TRANSALPHA)
		ghost.itemID = itemID
		ix.gui.combineLightGhost = ghost

		LocalPlayer():NotifyLocalized("combineLightPlaceMode")
	end)

	function PLUGIN:Think()
		local ghost = ix.gui.combineLightGhost
		if (IsValid(ghost)) then
			local client = LocalPlayer()
			local trace = util.TraceLine({
				start = client:EyePos(),
				endpos = client:EyePos() + client:GetAimVector() * 150,
				filter = {client, ghost}
			})

			local pos = trace.HitPos
			local ang = Angle(0, client:EyeAngles().y + 180, 0)

			-- Align bottom to floor
			local mins, maxs = ghost:GetModelBounds()
			local center = ghost:OBBCenter()
			local offset = ghost:LocalToWorld(Vector(center.x, center.y, mins.z)) - ghost:GetPos()

			ghost:SetPos(pos - offset)
			ghost:SetAngles(ang)

			local bValid = true
			
			if (client:GetPos():DistToSqr(pos) > 10000) then
				bValid = false
			end

			if (trace.HitNormal.z < 0.3) then
				bValid = false
			end

			local hullTrace = util.TraceHull({
				start = ghost:GetPos() + Vector(0, 0, 2), -- Offset from floor
				endpos = ghost:GetPos() + Vector(0, 0, 2),
				mins = mins + Vector(1, 1, 0),
				maxs = maxs - Vector(1, 1, 1),
				filter = {client, ghost}
			})

			if (hullTrace.Hit) then
				bValid = false
			end

			if (bValid) then
				ghost:SetColor(Color(0, 255, 0, 150))
				ghost.bValidPos = true
			else
				ghost:SetColor(Color(255, 0, 0, 150))
				ghost.bValidPos = false
			end
		end
	end

	function PLUGIN:PlayerBindPress(client, bind, pressed)
		local ghost = ix.gui.combineLightGhost
		if (IsValid(ghost) and pressed) then
			if (bind:find("attack2")) then
				ghost:Remove()
				surface.PlaySound("buttons/button10.wav")
				return true
			elseif (bind:find("attack")) then
				if (!ghost.bValidPos) then
					surface.PlaySound("buttons/button10.wav")
					return true
				end

				net.Start("ixCombineLightPlace")
					net.WriteUInt(ghost.itemID, 32)
					net.WriteVector(ghost:GetPos())
					net.WriteAngle(ghost:GetAngles())
				net.SendToServer()

				ghost:Remove()
				surface.PlaySound("physics/metal/metal_solid_impact_soft1.wav")
				return true
			end
		end
	end
end