PLUGIN.name = "ContainerFurniture"
PLUGIN.author = "Akiran (DD:AkiranSWFS#5376)"
PLUGIN.description = "Adds the ability to spawn Containers via an item, ideal if you don't want to give flags to your player."

--[[
		Don't forget to register your container in helix/plugins/containers/sh_definitions.lua

	ix.container.Register(model, {
		name = "Crate",
		description = "A simple wooden create.",
		width = 4,
		height = 4,
		locksound = "",
		opensound = ""
	})
]]--

ix.lang.AddTable("english", {
	containerFurniturePlaceMode = "Placing... (Left Click: Place, Right Click: Cancel, Scroll: Rotate)",
	containerFurniturePlaced = "The container has been placed.",
	containerFurnitureTooFar = "You are too far away from the placement position!",
	containerFurnitureNoFloor = "You can only place this on the floor!",
	containerFurnitureOverlap = "The container is overlapping with another object!",
})

ix.lang.AddTable("korean", {
	containerFurniturePlaceMode = "배치 중... (좌클릭: 배치, 우클릭: 취소, 휠: 회전)",
	containerFurniturePlaced = "보관함을 배치했습니다.",
	containerFurnitureTooFar = "배치 위치가 너무 멉니다!",
	containerFurnitureNoFloor = "바닥 위에만 설치할 수 있습니다!",
	containerFurnitureOverlap = "다른 물체와 겹쳐서 설치할 수 없습니다!",
})

function PLUGIN:InitializedPlugins()
	local furniturePlugin = ix.plugin.list["ixfurniture"]
	if (furniturePlugin) then
		for k, v in pairs(ix.item.list) do
			if (v.base == "base_containerfurniture") then
				table.insert(furniturePlugin.FurnitureList, {
					model = v.ContainerModel,
					price = v.price or 100,
					class = "prop_physics"
				})
			end
		end
	end
end

if (SERVER) then
	util.AddNetworkString("ixContainerFurnitureStartPlacement")
	util.AddNetworkString("ixContainerFurniturePlace")

	net.Receive("ixContainerFurniturePlace", function(len, client)
		local itemID = net.ReadUInt(32)
		local pos = net.ReadVector()
		local ang = net.ReadAngle()

		local item = ix.item.instances[itemID]
		if (!item or item:GetOwner() != client) then return end

		-- Strictly 100 units distance limit
		if (client:GetPos():DistToSqr(pos) > 10000) then
			client:NotifyLocalized("containerFurnitureTooFar")
			return
		end

		local model = item.ContainerModel
		local ent = ents.Create("prop_physics")
		ent:SetModel(model)
		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:Spawn()

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
			client:NotifyLocalized("containerFurnitureOverlap")
			return
		end

		local phys = ent:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:EnableMotion(false)
		end

		hook.Run("PlayerSpawnedProp", client, model, ent)
		
		item:Remove()
		client:NotifyLocalized("containerFurniturePlaced")
	end)
else
	net.Receive("ixContainerFurnitureStartPlacement", function()
		local itemID = net.ReadUInt(32)
		local model = net.ReadString()

		if (IsValid(ix.gui.containerGhost)) then
			ix.gui.containerGhost:Remove()
		end

		local ghost = ents.CreateClientProp(model)
		ghost:SetSolid(SOLID_VPHYSICS)
		ghost:SetRenderMode(RENDERMODE_TRANSALPHA)
		ghost.itemID = itemID
		ghost.angle = LocalPlayer():EyeAngles().y + 180
		ix.gui.containerGhost = ghost

		LocalPlayer():NotifyLocalized("containerFurniturePlaceMode")
	end)

	function PLUGIN:Think()
		local ghost = ix.gui.containerGhost
		if (IsValid(ghost)) then
			local client = LocalPlayer()
			-- Trace distance slightly larger for better feel, but validation is 100.
			local trace = util.TraceLine({
				start = client:EyePos(),
				endpos = client:EyePos() + client:GetAimVector() * 150,
				filter = {client, ghost}
			})

			local pos = trace.HitPos
			local ang = Angle(0, ghost.angle, 0)

			-- Align bottom to floor
			local mins, maxs = ghost:GetModelBounds()
			local center = ghost:OBBCenter()
			local offset = ghost:LocalToWorld(Vector(center.x, center.y, mins.z)) - ghost:GetPos()

			ghost:SetPos(pos - offset)
			ghost:SetAngles(ang)

			-- Strict Distance/Floor/Overlap Validation
			local bValid = true
			
			-- 1. Distance check (100 units)
			if (client:GetPos():DistToSqr(pos) > 10000) then
				bValid = false
			end

			-- 2. Floor check (Very lenient threshold to avoid displacement/prop floor issues)
			if (trace.HitNormal.z < 0.3) then
				bValid = false
			end

			-- 3. Overlap check (Avoid floor self-collision)
			local hullTrace = util.TraceHull({
				start = ghost:GetPos() + Vector(0, 0, 2), -- Offset from floor
				endpos = ghost:GetPos() + Vector(0, 0, 2),
				mins = mins + Vector(1, 1, 0), -- Slightly narrower to prevent edge overlap
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
		local ghost = ix.gui.containerGhost
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

				net.Start("ixContainerFurniturePlace")
					net.WriteUInt(ghost.itemID, 32)
					net.WriteVector(ghost:GetPos())
					net.WriteAngle(ghost:GetAngles())
				net.SendToServer()

				ghost:Remove()
				surface.PlaySound("physics/wood/wood_panel_impact_soft1.wav")
				return true
			elseif (bind:find("invprev")) then
				ghost.angle = ghost.angle + 10
				return true
			elseif (bind:find("invnext")) then
				ghost.angle = ghost.angle - 10
				return true
			end
		end
	end
end

