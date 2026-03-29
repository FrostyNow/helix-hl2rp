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
	furniturePlaceMode = "Placing... (Left Click: Place, Right Click: Cancel)",
	furniturePlaced = "The container has been placed."
})

ix.lang.AddTable("korean", {
	furniturePlaceMode = "배치 중... (좌클릭: 배치, 우클릭: 취소)",
	furniturePlaced = "보관함을 배치했습니다."
})

if (SERVER) then
	util.AddNetworkString("ixContainerFurnitureStartPlacement")
	util.AddNetworkString("ixContainerFurniturePlace")

	net.Receive("ixContainerFurniturePlace", function(len, client)
		local itemID = net.ReadUInt(32)
		local pos = net.ReadVector()
		local ang = net.ReadAngle()

		local item = ix.item.instances[itemID]
		if (!item or item:GetOwner() != client) then return end

		if (client:GetPos():DistToSqr(pos) > 100000) then return end

		local model = item.ContainerModel
		local entity = ents.Create("prop_physics")
		entity:SetModel(model)
		entity:SetPos(pos)
		entity:SetAngles(ang)
		entity:Spawn()

		local phys = entity:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:EnableMotion(false)
		end

		hook.Run("PlayerSpawnedProp", client, model, entity)
		
		item:Remove()
		client:NotifyLocalized("furniturePlaced")
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
		ix.gui.containerGhost = ghost

		LocalPlayer():NotifyLocalized("furniturePlaceMode")
	end)

	function PLUGIN:Think()
		local ghost = ix.gui.containerGhost
		if (IsValid(ghost)) then
			local client = LocalPlayer()
			local trace = util.TraceLine({
				start = client:EyePos(),
				endpos = client:EyePos() + client:GetAimVector() * 250,
				filter = {client, ghost}
			})

			local pos = trace.HitPos
			local ang = Angle(0, client:EyeAngles().y + 180, 0)

			-- 모델 바닥 정렬
			local mins, _ = ghost:GetModelBounds()
			local center = ghost:OBBCenter()
			local offset = ghost:LocalToWorld(Vector(center.x, center.y, mins.z)) - ghost:GetPos()

			ghost:SetPos(pos - offset)
			ghost:SetAngles(ang)
			ghost:SetColor(Color(0, 255, 0, 150))
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
				net.Start("ixContainerFurniturePlace")
					net.WriteUInt(ghost.itemID, 32)
					net.WriteVector(ghost:GetPos())
					net.WriteAngle(ghost:GetAngles())
				net.SendToServer()

				ghost:Remove()
				surface.PlaySound("physics/wood/wood_panel_impact_soft1.wav")
				return true
			end
		end
	end
end

