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
	{class = "ent_mannable_ar3", model = "models/props_combine/bunker_gun01.mdl", price = 500},
	{class = "ent_mannable_airboatgun", model = "models/airboatgun.mdl", price = 600},
	{class = "ent_mannable_combinesniper", model = "models/weapons/w_combine_sniper.mdl", price = 700},
	{class = "ent_mannable_combinecannon", model = "models/combine_turrets/combine_cannon_gun.mdl", price = 700},
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
		if (!char:IsCombine() and !client:IsAdmin()) then
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
		if (!char:IsCombine() and !client:IsAdmin()) then
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
				health = v:Health(),
				hideOwner = v:GetNWBool("ixHideOwner", false)
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
						owner = v.ixOwnerCID or 0,
						ownerName = v:GetNWString("ixOwnerName", "Unknown"),
						health = v.ixHealth or 100,
						bEmplacement = true,
						hideOwner = v:GetNWBool("ixHideOwner", false)
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
					entity.ixOwnerCID = v.owner or 0
					entity:SetNWBool("ixIsEmplacement", true)
					entity:SetNWInt("ixOwnerCID", entity.ixOwnerCID)
					entity:SetNWString("ixOwnerName", v.ownerName or "Unknown")
					entity.ixHealth = v.health or 100
					entity:SetNWInt("ixHealth", entity.ixHealth)
					entity:SetMoveType(MOVETYPE_NONE)
				else
					entity:SetBarricadeID(v.barricadeID)
					if (entity.SetOwnerCID) then entity:SetOwnerCID(v.owner) end
					if (entity.SetOwnerName) then entity:SetOwnerName(v.ownerName or "Unknown") end
					entity:SetHealth(v.health or 100)
				end

				if (v.hideOwner) then
					entity:SetNWBool("ixHideOwner", true)
				end

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

			-- Manually track HP since mannable entities ignore SetHealth
			target.ixHealth = (target.ixHealth or 100) - damage:GetDamage()
			target:SetNWInt("ixHealth", math.max(0, target.ixHealth))
			damage:SetDamage(0) -- prevent double-processing by the entity itself

			if (target.ixHealth <= 0) then
				target:Remove()
			end
		end
	end

	net.Receive("ixBarricadePlace", function(len, client)
		local char = client:GetCharacter()
		if (!char or (!char:IsCombine() and !client:IsAdmin())) then return end

		-- Check Count Limit
		if (!client:IsAdmin()) then
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
		end

		local barricadeIndex = net.ReadUInt(8)
		local pos = net.ReadVector()
		local ang = net.ReadAngle()

		local barricadeData = PLUGIN.BarricadeList[barricadeIndex]
		if (!barricadeData or !char:HasMoney(barricadeData.price)) then return end

		if (client:GetPos():DistToSqr(pos) > 17000) then return end

		char:TakeMoney(barricadeData.price)

		local entity = ents.Create("ix_combine_barricade")
		entity:SetPos(pos)
		entity:SetAngles(ang)
		entity:SetModel(barricadeData.model)
		entity:Spawn()
		
		entity:SetBarricadeID(tostring(barricadeIndex))
		entity:SetOwnerCID(char:GetID())

		if (char:IsCombine()) then
			entity:SetOwnerName(char:GetName())
		else
			entity:SetOwnerName("")
			entity:SetNWBool("ixHideOwner", true)
		end

		local phys = entity:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:EnableMotion(false)
		end

		client:NotifyLocalized("barricadeDeployed")
	end)

	net.Receive("ixEmplacementPlace", function(len, client)
		local char = client:GetCharacter()
		if (!char or (!char:IsCombine() and !client:IsAdmin())) then return end

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
		if (!client:IsAdmin()) then
			local count = 0
			for _, emplacement in ipairs(PLUGIN.EmplacementList) do
				for _, v in ipairs(ents.FindByClass(emplacement.class)) do
					if (v.ixIsEmplacement and v.ixOwnerCID == char:GetID()) then
						count = count + 1
					end
				end
			end

			local limit = ix.config.Get("emplacementLimit", 1)
			if (count >= limit) then
				client:NotifyLocalized("emplacementLimitReached", limit)
				return
			end
		end

		char:TakeMoney(emplacementData.price)

		local entity = ents.Create(emplacementData.class)
		entity:SetPos(pos)
		entity:SetAngles(ang)
		entity:Spawn()
		
		entity.ixIsEmplacement = true
		entity.ixOwnerCID = char:GetID()
		entity:SetNWBool("ixIsEmplacement", true)
		entity:SetNWInt("ixOwnerCID", char:GetID())

		if (char:IsCombine()) then
			entity:SetNWString("ixOwnerName", char:GetName())
			if (entity.SetOwnerName) then entity:SetOwnerName(char:GetName()) end
		else
			entity:SetNWString("ixOwnerName", "")
			entity:SetNWBool("ixHideOwner", true)
		end

		if (entity.SetOwnerCID) then entity:SetOwnerCID(char:GetID()) end

		entity.ixHealth = 100
		entity:SetNWInt("ixHealth", 100)

		entity:SetMoveType(MOVETYPE_NONE)
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
		frame:SetTitle("")
		frame:SetSize(ScrW() * 0.45, ScrH() * 0.5)
		frame:Center()
		frame:MakePopup()
		frame:ShowCloseButton(false)
		ix.gui.barricadeMenu = frame

		frame.Paint = function(s, w, h)
			surface.SetDrawColor(25, 25, 30, 240)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(40, 40, 45, 255)
			surface.DrawRect(0, 0, w, 40)
			draw.SimpleText(L("barricadeMenuTitle"):upper(), "ixMediumFont", 15, 20, Color(255, 255, 255, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			surface.SetDrawColor(60, 60, 70, 255)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		local close = frame:Add("DButton")
		close:SetSize(40, 40)
		close:SetPos(frame:GetWide() - 40, 0)
		close:SetText("✕")
		close:SetFont("ixMediumFont")
		close:SetTextColor(Color(200, 200, 200))
		close.Paint = function(s, w, h)
			if (s:IsHovered()) then
				surface.SetDrawColor(200, 50, 50, 150)
				surface.DrawRect(0, 0, w, h)
			end
		end
		close.DoClick = function()
			frame:Remove()
		end

		local scroll = frame:Add("DScrollPanel")
		scroll:Dock(FILL)

		local iconSize = 110
		local iconSpacing = 10
		local frameWide = frame:GetWide() - 40
		local cols = math.floor(frameWide / (iconSize + iconSpacing))
		local totalGridWidth = (cols * iconSize) + ((cols - 1) * iconSpacing)
		local sidePadding = math.max(10, (frameWide - totalGridWidth) / 2)

		scroll:DockMargin(sidePadding, 50, sidePadding, 10)

		local grid = scroll:Add("DIconLayout")
		grid:Dock(TOP)
		grid:SetSpaceX(iconSpacing)
		grid:SetSpaceY(iconSpacing)

		for k, v in ipairs(PLUGIN.BarricadeList) do
			local icon = grid:Add("SpawnIcon")
			icon:SetSize(110, 110)
			icon:SetModel(v.model)
			icon:SetTooltip(ix.currency.Get(v.price, LocalPlayer()))

			icon.PaintOver = function(s, w, h)
				if (s:IsHovered()) then
					surface.SetDrawColor(255, 255, 255, 5)
					surface.DrawRect(0, 0, w, h)
					surface.SetDrawColor(100, 200, 255, 200)
					surface.DrawOutlinedRect(0, 0, w, h)
				end
			end

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
				local client = LocalPlayer()
				local char = client:GetCharacter()

				if (!char:HasMoney(v.price)) then
					client:NotifyLocalized("barricadeNoMoney")
					return
				end

				if (!client:IsAdmin()) then
					local count = 0
					for _, ent in ipairs(ents.FindByClass("ix_combine_barricade")) do
						if (ent.GetOwnerCID and ent:GetOwnerCID() == char:GetID()) then
							count = count + 1
						end
					end
					local limit = ix.config.Get("barricadeLimit", 5)
					if (count >= limit) then
						client:NotifyLocalized("barricadeLimitReached", limit)
						return
					end
				end

				frame:Remove()

				if (IsValid(ix.gui.barricadeGhost)) then ix.gui.barricadeGhost:Remove() end

				local ghost = ents.CreateClientProp(v.model)
				ghost:SetSolid(SOLID_VPHYSICS)
				ghost:SetRenderMode(RENDERMODE_TRANSALPHA)
				ghost.barricadeIndex = k
				ghost.angle = math.Round(client:EyeAngles().y / 90) * 90
				ix.gui.barricadeGhost = ghost

				client:NotifyLocalized("barricadePlacementHelp")
			end
		end

		grid:InvalidateLayout(true)
	end)

	net.Receive("ixEmplacementOpenMenu", function()
		if (IsValid(ix.gui.barricadeMenu)) then
			ix.gui.barricadeMenu:Remove()
		end

		local frame = vgui.Create("DFrame")
		frame:SetTitle("")
		frame:SetSize(ScrW() * 0.45, ScrH() * 0.5)
		frame:Center()
		frame:MakePopup()
		frame:ShowCloseButton(false)
		ix.gui.barricadeMenu = frame

		frame.Paint = function(s, w, h)
			surface.SetDrawColor(25, 25, 30, 240)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(40, 40, 45, 255)
			surface.DrawRect(0, 0, w, 40)
			draw.SimpleText(L("emplacementMenuTitle"):upper(), "ixMediumFont", 15, 20, Color(255, 255, 255, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			surface.SetDrawColor(60, 60, 70, 255)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		local close = frame:Add("DButton")
		close:SetSize(40, 40)
		close:SetPos(frame:GetWide() - 40, 0)
		close:SetText("✕")
		close:SetFont("ixMediumFont")
		close:SetTextColor(Color(200, 200, 200))
		close.Paint = function(s, w, h)
			if (s:IsHovered()) then
				surface.SetDrawColor(200, 50, 50, 150)
				surface.DrawRect(0, 0, w, h)
			end
		end
		close.DoClick = function()
			frame:Remove()
		end

		local scroll = frame:Add("DScrollPanel")
		scroll:Dock(FILL)

		local iconSize = 110
		local iconSpacing = 10
		local frameWide = frame:GetWide() - 40
		local cols = math.floor(frameWide / (iconSize + iconSpacing))
		local totalGridWidth = (cols * iconSize) + ((cols - 1) * iconSpacing)
		local sidePadding = math.max(10, (frameWide - totalGridWidth) / 2)

		scroll:DockMargin(sidePadding, 50, sidePadding, 10)

		local grid = scroll:Add("DIconLayout")
		grid:Dock(TOP)
		grid:SetSpaceX(iconSpacing)
		grid:SetSpaceY(iconSpacing)

		for k, v in ipairs(PLUGIN.EmplacementList) do
			-- Existence check on client
			if (!scripted_ents.Get(v.class)) then continue end

			local icon = grid:Add("SpawnIcon")
			icon:SetSize(110, 110)
			icon:SetModel(v.model)
			icon:SetTooltip(ix.currency.Get(v.price, LocalPlayer()))

			icon.PaintOver = function(s, w, h)
				if (s:IsHovered()) then
					surface.SetDrawColor(255, 255, 255, 5)
					surface.DrawRect(0, 0, w, h)
					surface.SetDrawColor(100, 200, 255, 200)
					surface.DrawOutlinedRect(0, 0, w, h)
				end
			end

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
				local client = LocalPlayer()
				local char = client:GetCharacter()

				if (!char:HasMoney(v.price)) then
					client:NotifyLocalized("barricadeNoMoney")
					return
				end

				if (!client:IsAdmin()) then
					local count = 0
					for _, emplacement in ipairs(PLUGIN.EmplacementList) do
						for _, ent in ipairs(ents.FindByClass(emplacement.class)) do
							if (ent:GetNWBool("ixIsEmplacement") and ent:GetNWInt("ixOwnerCID") == char:GetID()) then
								count = count + 1
							end
						end
					end
					local limit = ix.config.Get("emplacementLimit", 1)
					if (count >= limit) then
						client:NotifyLocalized("emplacementLimitReached", limit)
						return
					end
				end

				frame:Remove()

				if (IsValid(ix.gui.barricadeGhost)) then ix.gui.barricadeGhost:Remove() end

				local ghost = ents.CreateClientProp(v.model)
				ghost:SetSolid(SOLID_VPHYSICS)
				ghost:SetRenderMode(RENDERMODE_TRANSALPHA)
				ghost.emplacementIndex = k
				ghost.angle = math.Round(client:EyeAngles().y / 90) * 90
				ix.gui.barricadeGhost = ghost

				client:NotifyLocalized("barricadePlacementHelp")
			end
		end

		grid:InvalidateLayout(true)
	end)

	function PLUGIN:Think()
		local ghost = ix.gui.barricadeGhost
		if (IsValid(ghost)) then
			local client = LocalPlayer()
			local eyeTrace = util.TraceLine({
				start = client:EyePos(),
				endpos = client:EyePos() + client:GetAimVector() * 85,
				filter = {client, ghost}
			})

			local hitBarricadeEnt = IsValid(eyeTrace.Entity) and eyeTrace.Entity:GetClass() == "ix_combine_barricade" and eyeTrace.Entity
			local bDirectFloor = eyeTrace.Hit and eyeTrace.HitNormal.z > 0.6

			local pos, bValidSurface

			if (ghost.emplacementIndex and hitBarricadeEnt) then
				-- Emplacement on barricade: use hit pos directly (emplacement origins are at model base)
				pos = eyeTrace.HitPos
				bValidSurface = true
			elseif (bDirectFloor and not hitBarricadeEnt) then
				-- Directly hitting the floor — use as-is
				pos = eyeTrace.HitPos
				bValidSurface = true
			else
				-- Hitting a wall, barricade (for barricade ghost), ceiling, or sky — drop down to find floor below
				local floorTrace = util.TraceLine({
					start = eyeTrace.HitPos + Vector(0, 0, 50),
					endpos = eyeTrace.HitPos - Vector(0, 0, 300),
					filter = {client, ghost}
				})

				if (floorTrace.Hit and floorTrace.HitNormal.z > 0.6) then
					local floorIsBarricade = IsValid(floorTrace.Entity) and floorTrace.Entity:GetClass() == "ix_combine_barricade"
					if (!floorIsBarricade) then
						pos = floorTrace.HitPos
						bValidSurface = true
					else
						pos = eyeTrace.HitPos
						bValidSurface = false
					end
				else
					pos = eyeTrace.HitPos
					bValidSurface = false
				end
			end

			local ang = ghost.angle
			ghost:SetAngles(Angle(0, ang, 0))

			local mins, _ = ghost:GetModelBounds()
			local center = ghost:OBBCenter()
			local offset = ghost:LocalToWorld(Vector(center.x, center.y, mins.z)) - ghost:GetPos()

			if (ghost.emplacementIndex) then
				-- Emplacement model origins sit at the model base — no OBB offset needed
				ghost:SetPos(pos)
			else
				ghost:SetPos(pos - offset)
			end

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
			
			if (!entity:GetNWBool("ixHideOwner", false)) then
				local ownerName = entity.GetOwnerName and entity:GetOwnerName() or entity:GetNWString("ixOwnerName", "Unknown")
				draw.SimpleText(L("barricadeOwner", ownerName), "ixSmallFont", x, y, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			
			local barW, barH = 150, 4
			local health
			if (bEmplacement) then
				health = math.Clamp(entity:GetNWInt("ixHealth", 100) / 100, 0, 1)
			else
				health = math.Clamp(entity:Health() / entity:GetMaxHealth(), 0, 1)
			end
			
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
