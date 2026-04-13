local PLUGIN = PLUGIN

PLUGIN.name = "Combine Barricades"
PLUGIN.author = "Frosty"
PLUGIN.description = "Deployable barricades for Combine forces with specialized destruction logic."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

PLUGIN.BarricadeList = {
	{model = "models/props_combine/combine_barricade_short01a.mdl", price = 200},
	{model = "models/props_combine/combine_barricade_short02a.mdl", price = 200},
	{model = "models/props_combine/combine_barricade_short03a.mdl", price = 200},
}

PLUGIN.EmplacementList = {
	{class = "ent_mannable_ar3", model = "models/props_combine/combine_cannon001.mdl", price = 500},
	{class = "ent_mannable_airboatgun", model = "models/props_combine/combine_airboatgun.mdl", price = 600},
	{class = "ent_mannable_combinesniper", model = "models/props_combine/combine_sniper_turret.mdl", price = 700},
	{class = "ent_mannable_combinecannon", model = "models/props_combine/combine_cannon001.mdl", price = 700},
}

-- Configs
ix.config.Add("barricadeLimit", 5, "Maximum number of barricades a character can place.", nil, {
	data = {min = 1, max = 20},
	category = "Combine Barricades"
})

ix.config.Add("emplacementLimit", 1, "Maximum number of emplacements a character can place.", nil, {
	data = {min = 1, max = 5},
	category = "Combine Barricades"
})

ix.command.Add("Barricade", {
	description = "@barricadeDesc",
	OnRun = function(self, client)
		local char = client:GetCharacter()
		if (!char:IsCombine()) then
			return "@barricadeNoCombine"
		end

		net.Start("ixBarricadeOpenMenu")
		net.Send(client)
	end
})

ix.command.Add("Emplacement", {
	description = "@emplacementDesc",
	OnRun = function(self, client)
		local char = client:GetCharacter()
		if (!char:IsCombine()) then
			return "@barricadeNoCombine"
		end

		net.Start("ixEmplacementOpenMenu")
		net.Send(client)
	end
})

ix.command.Add("BarricadeRemove", {
	description = "@barricadeRemoveDesc",
	OnRun = function(self, client)
		local trace = client:GetEyeTrace()
		local entity = trace.Entity

		if (IsValid(entity) and entity:GetClass() == "ix_combine_barricade") then
			local char = client:GetCharacter()
			
			if (char:GetID() == entity:GetOwnerCID() or client:IsAdmin()) then
				local barricadeID = tonumber(entity:GetBarricadeID())
				local barricadeData = PLUGIN.BarricadeList[barricadeID]
				
				local refund = 0
				if (barricadeData) then
					refund = math.floor(barricadeData.price * 0.5)
				end

				char:GiveMoney(refund)
				entity:Remove()
				client:NotifyLocalized("barricadeRemovedRefund", ix.currency.Get(refund, client))
			else
				client:NotifyLocalized("barricadeNotOwner")
			end
		else
			client:NotifyLocalized("barricadeNotLooking")
		end
	end
})

ix.command.Add("BarricadeRepair", {
	description = "@barricadeRepairDesc",
	OnRun = function(self, client)
		local trace = client:GetEyeTrace()
		local entity = trace.Entity

		if (IsValid(entity) and entity:GetClass() == "ix_combine_barricade") then
			local char = client:GetCharacter()
			local hp = entity:Health()
			local maxHP = entity:GetMaxHealth()
			
			if (hp >= maxHP) then
				return "@barricadeAlreadyFullHP"
			end

			local barricadeID = tonumber(entity:GetBarricadeID())
			local barricadeData = PLUGIN.BarricadeList[barricadeID]
			if (!barricadeData) then return end

			local missingHP = maxHP - hp
			local repairCost = math.ceil((missingHP / maxHP) * barricadeData.price * 0.5)

			if (!char:HasMoney(repairCost)) then
				return L("barricadeNoMoneyRepair", client, ix.currency.Get(repairCost, client))
			end

			char:TakeMoney(repairCost)
			entity:SetHealth(maxHP)
			
			client:NotifyLocalized("barricadeRepaired", ix.currency.Get(repairCost, client))
			entity:EmitSound("physics/metal/metal_box_impact_soft" .. math.random(1, 3) .. ".wav")
		else
			return "@barricadeNotLooking"
		end
	end
})

if (SERVER) then
	util.AddNetworkString("ixBarricadeOpenMenu")
	util.AddNetworkString("ixBarricadePlace")
	util.AddNetworkString("ixEmplacementOpenMenu")
	util.AddNetworkString("ixEmplacementPlace")

	function PLUGIN:SaveData()
		local data = {}

		for _, v in ipairs(ents.FindByClass("ix_combine_barricade")) do
			data[#data + 1] = {
				class = v:GetClass(),
				pos = v:GetPos(),
				ang = v:GetAngles(),
				model = v:GetModel(),
				barricadeID = v:GetBarricadeID(),
				owner = v:GetOwnerCID(),
				ownerName = v:GetOwnerName(),
				health = v:Health()
			}
		end

		for _, emplacement in ipairs(PLUGIN.EmplacementList) do
			for _, v in ipairs(ents.FindByClass(emplacement.class)) do
				if (v.ixIsEmplacement) then
					data[#data + 1] = {
						class = v:GetClass(),
						pos = v:GetPos(),
						ang = v:GetAngles(),
						model = v:GetModel(),
						owner = v:GetOwnerCID(),
						ownerName = v:GetOwnerName(),
						health = v:Health(),
						bEmplacement = true
					}
				end
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
				entity:SetAngles(v.ang)
				if (v.model) then entity:SetModel(v.model) end
				entity:Spawn()
				
				if (v.bEmplacement) then
					entity.ixIsEmplacement = true
					entity:SetNWBool("ixIsEmplacement", true)
				else
					entity:SetBarricadeID(v.barricadeID)
				end

				entity:SetOwnerCID(v.owner)
				entity:SetOwnerName(v.ownerName or "Unknown")
				entity:SetHealth(v.health or 100)
				
				local phys = entity:GetPhysicsObject()
				if (IsValid(phys)) then
					phys:EnableMotion(false)
				end
			end
		end
	end

	function PLUGIN:EntityTakeDamage(target, damage)
		if (target.ixIsEmplacement) then
			if (!damage:IsDamageType(DMG_BLAST)) then
				damage:SetDamage(0)
				return
			end
		end
	end

	function PLUGIN:PostEntityTakeDamage(target, damage, bTook)
		if (target.ixIsEmplacement and bTook) then
			if (target:Health() <= 0) then
				target:Remove()
			end
		end
	end

	net.Receive("ixBarricadePlace", function(len, client)
		local char = client:GetCharacter()
		if (!char or !char:IsCombine()) then return end

		-- Check Count Limit
		local count = 0
		for _, v in ipairs(ents.FindByClass("ix_combine_barricade")) do
			if (v:GetOwnerCID() == char:GetID()) then
				count = count + 1
			end
		end

		local limit = ix.config.Get("barricadeLimit", 5)
		if (count >= limit) then
			client:NotifyLocalized("barricadeLimitReached", limit)
			return
		end

		local barricadeIndex = net.ReadUInt(8)
		local pos = net.ReadVector()
		local ang = net.ReadAngle()

		local barricadeData = PLUGIN.BarricadeList[barricadeIndex]
		if (!barricadeData or !char:HasMoney(barricadeData.price)) then return end

		if (client:GetPos():DistToSqr(pos) > 150000) then return end

		char:TakeMoney(barricadeData.price)

		local entity = ents.Create("ix_combine_barricade")
		entity:SetPos(pos)
		entity:SetAngles(ang)
		entity:SetModel(barricadeData.model)
		entity:Spawn()
		
		entity:SetBarricadeID(tostring(barricadeIndex))
		entity:SetOwnerCID(char:GetID())
		entity:SetOwnerName(char:GetName())

		local phys = entity:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:EnableMotion(false)
		end

		client:NotifyLocalized("barricadeDeployed")
	end)

	net.Receive("ixEmplacementPlace", function(len, client)
		local char = client:GetCharacter()
		if (!char or !char:IsCombine()) then return end

		local emplacementIndex = net.ReadUInt(8)
		local pos = net.ReadVector()
		local ang = net.ReadAngle()

		local emplacementData = PLUGIN.EmplacementList[emplacementIndex]
		if (!emplacementData or !char:HasMoney(emplacementData.price)) then return end

		-- Existence check
		if (!scripted_ents.Get(emplacementData.class)) then
			client:Notify("This weapon type is not available on the server.")
			return
		end

		-- Check Count Limit
		local count = 0
		for _, emplacement in ipairs(PLUGIN.EmplacementList) do
			for _, v in ipairs(ents.FindByClass(emplacement.class)) do
				if (v.ixIsEmplacement and v:GetOwnerCID() == char:GetID()) then
					count = count + 1
				end
			end
		end

		local limit = ix.config.Get("emplacementLimit", 1)
		if (count >= limit) then
			client:NotifyLocalized("emplacementLimitReached", limit)
			return
		end

		char:TakeMoney(emplacementData.price)

		local entity = ents.Create(emplacementData.class)
		entity:SetPos(pos)
		entity:SetAngles(ang)
		entity:Spawn()
		
		entity.ixIsEmplacement = true
		entity:SetNWBool("ixIsEmplacement", true)
		entity:SetOwnerCID(char:GetID())
		entity:SetOwnerName(char:GetName())
		
		entity:SetMaxHealth(100)
		entity:SetHealth(100)

		local phys = entity:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:EnableMotion(false)
		end

		client:NotifyLocalized("emplacementDeployed")
	end)
end

if (CLIENT) then
	net.Receive("ixBarricadeOpenMenu", function()
		if (IsValid(ix.gui.barricadeMenu)) then
			ix.gui.barricadeMenu:Remove()
		end

		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"barricadeMenuTitle")
		frame:SetSize(500, 400)
		frame:Center()
		frame:MakePopup()
		ix.gui.barricadeMenu = frame

		local scroll = frame:Add("DScrollPanel")
		scroll:Dock(FILL)

		local grid = scroll:Add("DIconLayout")
		grid:Dock(TOP)
		grid:SetSpaceX(5)
		grid:SetSpaceY(5)

		for k, v in ipairs(PLUGIN.BarricadeList) do
			local icon = grid:Add("SpawnIcon")
			icon:SetSize(64, 64)
			icon:SetModel(v.model)
			icon:SetTooltip(ix.currency.Get(v.price, LocalPlayer()))
			
			local label = icon:Add("DLabel")
			label:SetText(ix.currency.Get(v.price, LocalPlayer()))
			label:SetFont("ixSmallFont")
			label:Dock(BOTTOM)
			label:SetContentAlignment(5)
			label:SetTall(20)
			label.Paint = function(s, w, h)
				surface.SetDrawColor(0, 0, 0, 180)
				surface.DrawRect(0, 0, w, h)
			end

			icon.DoClick = function()
				if (!LocalPlayer():GetCharacter():HasMoney(v.price)) then
					LocalPlayer():NotifyLocalized("barricadeNoMoney")
					return
				end

				frame:Remove()

				if (IsValid(ix.gui.barricadeGhost)) then ix.gui.barricadeGhost:Remove() end

				local ghost = ents.CreateClientProp(v.model)
				ghost:SetSolid(SOLID_VPHYSICS)
				ghost:SetRenderMode(RENDERMODE_TRANSALPHA)
				ghost.barricadeIndex = k
				ghost.angle = LocalPlayer():EyeAngles().y + 180
				ix.gui.barricadeGhost = ghost

				LocalPlayer():NotifyLocalized("barricadePlacementHelp")
			end
		end
	end)

	net.Receive("ixEmplacementOpenMenu", function()
		if (IsValid(ix.gui.barricadeMenu)) then
			ix.gui.barricadeMenu:Remove()
		end

		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"emplacementMenuTitle")
		frame:SetSize(400, 300)
		frame:Center()
		frame:MakePopup()
		ix.gui.barricadeMenu = frame

		local scroll = frame:Add("DScrollPanel")
		scroll:Dock(FILL)

		local grid = scroll:Add("DIconLayout")
		grid:Dock(TOP)
		grid:SetSpaceX(5)
		grid:SetSpaceY(5)

		for k, v in ipairs(PLUGIN.EmplacementList) do
			-- Existence check on client
			if (!scripted_ents.Get(v.class)) then continue end

			local icon = grid:Add("SpawnIcon")
			icon:SetSize(64, 64)
			icon:SetModel(v.model)
			icon:SetTooltip(ix.currency.Get(v.price, LocalPlayer()))
			
			local label = icon:Add("DLabel")
			label:SetText(ix.currency.Get(v.price, LocalPlayer()))
			label:SetFont("ixSmallFont")
			label:Dock(BOTTOM)
			label:SetContentAlignment(5)
			label:SetTall(20)
			label.Paint = function(s, w, h)
				surface.SetDrawColor(0, 0, 0, 180)
				surface.DrawRect(0, 0, w, h)
			end

			icon.DoClick = function()
				if (!LocalPlayer():GetCharacter():HasMoney(v.price)) then
					LocalPlayer():NotifyLocalized("barricadeNoMoney")
					return
				end

				frame:Remove()

				if (IsValid(ix.gui.barricadeGhost)) then ix.gui.barricadeGhost:Remove() end

				local ghost = ents.CreateClientProp(v.model)
				ghost:SetSolid(SOLID_VPHYSICS)
				ghost:SetRenderMode(RENDERMODE_TRANSALPHA)
				ghost.emplacementIndex = k
				ghost.angle = LocalPlayer():EyeAngles().y + 180
				ix.gui.barricadeGhost = ghost

				LocalPlayer():NotifyLocalized("barricadePlacementHelp")
			end
		end
	end)

	function PLUGIN:Think()
		local ghost = ix.gui.barricadeGhost
		if (IsValid(ghost)) then
			local client = LocalPlayer()
			local trace = util.TraceLine({
				start = client:EyePos(),
				endpos = client:EyePos() + client:GetAimVector() * 250,
				filter = {client, ghost}
			})

			local pos = trace.HitPos
			local ang = ghost.angle

			ghost:SetAngles(Angle(0, ang, 0))

			local mins, _ = ghost:GetModelBounds()
			local center = ghost:OBBCenter()
			local offset = ghost:LocalToWorld(Vector(center.x, center.y, mins.z)) - ghost:GetPos()
			ghost:SetPos(pos - offset)

			-- Valid if it's a flat surface OR it's hitting a barricade
			local bOnBarricade = (IsValid(trace.Entity) and trace.Entity:GetClass() == "ix_combine_barricade")
			local bValidSurface = (trace.HitNormal.z > 0.6) or bOnBarricade

			if (!bValidSurface) then
				ghost:SetColor(Color(255, 0, 0, 150))
				ghost.canPlace = false
			else
				ghost:SetColor(Color(0, 255, 0, 150))
				ghost.canPlace = true
			end
		end
	end

	function PLUGIN:PlayerBindPress(client, bind, pressed)
		local ghost = ix.gui.barricadeGhost
		if (IsValid(ghost) and pressed) then
			if (bind:find("attack2")) then
				ghost:Remove()
				surface.PlaySound("buttons/button10.wav")
				return true
			elseif (bind:find("attack")) then
				if (ghost.canPlace) then
					if (ghost.emplacementIndex) then
						net.Start("ixEmplacementPlace")
							net.WriteUInt(ghost.emplacementIndex, 8)
							net.WriteVector(ghost:GetPos())
							net.WriteAngle(ghost:GetAngles())
						net.SendToServer()
					else
						net.Start("ixBarricadePlace")
							net.WriteUInt(ghost.barricadeIndex, 8)
							net.WriteVector(ghost:GetPos())
							net.WriteAngle(ghost:GetAngles())
						net.SendToServer()
					end

					ghost:Remove()
					surface.PlaySound("physics/metal/metal_box_impact_soft1.wav")
				else
					surface.PlaySound("buttons/button10.wav")
				end
				return true
			elseif (bind:find("invprev") or bind:find("invnext")) then
				local multiplier = bind:find("invprev") and 1 or -1
				ghost.angle = ghost.angle + (15 * multiplier)
				return true
			end
		end
	end

	function PLUGIN:HUDPaint()
		local client = LocalPlayer()
		local entity = client:GetEyeTrace().Entity

		local bBarricade = IsValid(entity) and entity:GetClass() == "ix_combine_barricade"
		local bEmplacement = IsValid(entity) and entity:GetNWBool("ixIsEmplacement", false)

		if (bBarricade or bEmplacement) then
			local w, h = ScrW(), ScrH()
			local x, y = w / 2, h - 100
			local alpha = 80
			
			draw.SimpleText(L("barricadeOwner", entity:GetOwnerName()), "ixSmallFont", x, y, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			
			local barW, barH = 150, 4
			local health = math.Clamp(entity:Health() / entity:GetMaxHealth(), 0, 1)
			
			surface.SetDrawColor(0, 0, 0, 50)
			surface.DrawRect(x - barW / 2, y + 12, barW, barH)
			
			local color = Color(100, 150, 255, alpha) -- Combine biological blue-ish or standard blue
			if (health <= 0.25) then
				color = Color(200, 50, 50, alpha)
			elseif (health <= 0.5) then
				color = Color(200, 150, 50, alpha)
			end
			
			surface.SetDrawColor(color)
			surface.DrawRect(x - barW / 2, y + 12, barW * health, barH)
		end
	end
end
