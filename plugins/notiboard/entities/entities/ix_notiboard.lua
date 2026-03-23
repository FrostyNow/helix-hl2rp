--[[
	© 2020 Black Tea
	Ported to Helix by Frosty
--]]

ENT.Type = "anim"
ENT.PrintName = "Noti-Board"
ENT.Author = "Black Tea"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Category = "Helix"
ENT.RenderGroup = RENDERGROUP_BOTH

if (CLIENT) then
	surface.CreateFont("ix_NotiBoardFont", {
		font = "Inter" or "ixGenericFont",
		size = 27,
		weight = 500,
		antialias = true,
	})

	surface.CreateFont("ix_NotiBoardFont2", {
		font = "Inter" or "ixGenericFont",
		size = 27,
		weight = 500,
		antialias = true,
		blursize = 2
	})

	surface.CreateFont("ix_NotiBoardTitle", {
		font = "Inter" or "ixGenericFont",
		size = 33,
		weight = 1000,
		antialias = true
	})

	surface.CreateFont("ix_NotiBoardTitle2", {
		font = "Inter" or "ixGenericFont",
		size = 33,
		weight = 1000,
		antialias = true,
		blursize = 2
	})

	local SCREEN_OVERLAY = Material("effects/combine_binocoverlay")
	SCREEN_OVERLAY:SetFloat("$alpha", "0.7")
	SCREEN_OVERLAY:Recompute()

	function ENT:Draw()
		self:DrawModel()
	end

	local scale = 0.5
	local sx, sy = 95 * 4, 95
	local distance = 1000

	function ENT:DrawTranslucent()
		local pos, ang = self:GetPos(), self:GetAngles()
		pos = pos + self:GetUp() * 2
		ang:RotateAroundAxis(self:GetUp(), 90)

		local up = self:GetUp()
		local right = self:GetRight()
		local dist = LocalPlayer():GetPos():Distance(pos)

		if (dist > distance) then return end

		local distalpha = math.Clamp(distance - dist, 0, 255)
		local ch = up * sy * 0.5 * scale
		local cw = right * sx * 0.5 * scale

		local text = self:GetNetVar("text", "This Noti-Board is not assigned yet.")
		local title = self:GetNetVar("title", "A Noti-Board")

		render.PushCustomClipPlane(up, up:Dot(pos - ch))
		render.PushCustomClipPlane(-up, (-up):Dot(pos + ch))
		render.PushCustomClipPlane(right, right:Dot(pos - cw))
		render.PushCustomClipPlane(-right, (-right):Dot(pos + cw))
		render.EnableClipping(true)

		cam.Start3D2D(pos, ang, scale)
			surface.SetDrawColor(22, 22, 22, distalpha)
			surface.DrawRect(-sx / 2, -sy / 2, sx, sy)

			-- Draw Title
			surface.SetFont("ix_NotiBoardTitle")
			local tx1, ty1 = surface.GetTextSize(title)
			local tposx1, tposy1 = -tx1 / 2, -ty1 / 2 - 19
			
			surface.SetTextColor(222, 222, 222, distalpha)
			surface.SetTextPos(tposx1, tposy1)
			surface.DrawText(title)

			surface.SetFont("ix_NotiBoardTitle2")
			surface.SetTextPos(tposx1, tposy1)
			surface.DrawText(title)

			-- Draw Text (Scrolling)
			surface.SetFont("ix_NotiBoardFont")
			local tx2, ty2 = surface.GetTextSize(text)
			local tposx2, tposy2 = sx / 2 - ((RealTime() * 100) % (tx2 + sx)), -ty2 / 2 + 23
			
			surface.SetTextPos(tposx2, tposy2)
			surface.DrawText(text)

			surface.SetFont("ix_NotiBoardFont2")
			surface.SetTextPos(tposx2, tposy2)
			surface.DrawText(text)

			-- Overlay
			surface.SetDrawColor(255, 255, 255, math.Clamp(distalpha, 0, 50))
			surface.SetMaterial(SCREEN_OVERLAY)
			surface.DrawTexturedRect(-sx / 2, -sy / 2, sx, sy)
		cam.End3D2D()

		render.PopCustomClipPlane()
		render.PopCustomClipPlane()
		render.PopCustomClipPlane()
		render.PopCustomClipPlane()
		render.EnableClipping(false)
	end

	netstream.Hook("ix_ShowNotiMenu", function(entity)
		local menu = DermaMenu()

		menu:AddOption(L("notiSetTitle"), function()
			Derma_StringRequest(L("notiSetTitle"), L("notiEnterTitle"), entity:GetNetVar("title", ""), function(text)
				netstream.Start("ix_NotiRequest", "title", tostring(text), entity)
			end, nil, L("submit"), L("cancel"))
		end):SetImage("icon16/page_edit.png")

		menu:AddOption(L("notiSetText"), function()
			Derma_StringRequest(L("notiSetText"), L("notiEnterText"), entity:GetNetVar("text", ""), function(text)
				netstream.Start("ix_NotiRequest", "text", tostring(text), entity)
			end, nil, L("submit"), L("cancel"))
		end):SetImage("icon16/page_white_edit.png")

		menu:Open()
		menu:Center()
	end)
else
	function ENT:Initialize()
		self:SetModel("models/hunter/plates/plate1x4.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:SetColor(Color(0, 0, 0))

		local physicsObject = self:GetPhysicsObject()
		if (IsValid(physicsObject)) then
			physicsObject:Wake()
		end
	end

	function ENT:Use(client)
		if (client:IsAdmin()) then
			netstream.Start(client, "ix_ShowNotiMenu", self)
		end
	end

	netstream.Hook("ix_NotiRequest", function(client, key, value, entity)
		if (!client:IsAdmin() or !IsValid(entity) or entity:GetClass() != "ix_notiboard") then
			return
		end

		if (key == "title" or key == "text") then
			entity:SetNetVar(key, value)
		end
	end)
end