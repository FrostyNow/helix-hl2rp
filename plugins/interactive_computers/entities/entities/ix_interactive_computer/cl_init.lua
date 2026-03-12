include("shared.lua")

local SCREEN_SCALE = 0.03
local ACTIVE_COLOR = Color(110, 255, 110, 240)
local DIM_COLOR = Color(25, 70, 25, 220)

function ENT:Draw()
	self:DrawModel()

	-- World-space screen rendering is temporarily disabled.
	-- local position = self:GetPos()
	-- local angles = self:GetAngles()
	-- local powered = self:GetNetVar("powered", false)
	-- local combineTerminal = self:GetNetVar("combineTerminal", false)
	--
	-- angles:RotateAroundAxis(angles:Up(), 90)
	-- angles:RotateAroundAxis(angles:Forward(), 90)
	--
	-- cam.Start3D2D(position + self:GetUp() * 9.4 + self:GetForward() * 7.7 + self:GetRight() * -5.55, angles, SCREEN_SCALE)
	-- 	surface.SetDrawColor(5, 15, 5, 245)
	-- 	surface.DrawRect(-170, -118, 340, 236)
	--
	-- 	surface.SetDrawColor(35, 255, 35, 16)
	-- 	for y = -118, 118, 4 do
	-- 		surface.DrawRect(-170, y, 340, 1)
	-- 	end
	--
	-- 	surface.SetDrawColor(55, 255, 55, 45)
	-- 	surface.DrawOutlinedRect(-170, -118, 340, 236, 1)
	--
	-- 	draw.SimpleText(combineTerminal and "OVERWATCH NODE" or (powered and "DOS JOURNAL OS" or "NO SIGNAL"), "ixComputerDOSBody", -152, -96, ACTIVE_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	-- 	draw.SimpleText(powered and "STATUS: ONLINE" or "STATUS: OFFLINE", "ixComputerDOSTiny", -152, -70, powered and ACTIVE_COLOR or DIM_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	--
	-- 	if (powered) then
	-- 		if (combineTerminal) then
	-- 			draw.SimpleText("CMB:\\> LOAD OBJECTIVES", "ixComputerDOSTiny", -152, -24, ACTIVE_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	-- 			draw.SimpleText("CMB:\\> LOAD CIVIL DATA", "ixComputerDOSTiny", -152, -2, ACTIVE_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	-- 			draw.SimpleText("CMB:\\> AUTHORIZE", "ixComputerDOSTiny", -152, 20, ACTIVE_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	-- 		else
	-- 			draw.SimpleText("C:\\> OPEN JOURNAL.EXE", "ixComputerDOSTiny", -152, -24, ACTIVE_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	-- 			draw.SimpleText("C:\\> EDIT LOGS", "ixComputerDOSTiny", -152, -2, ACTIVE_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	-- 			draw.SimpleText("C:\\> SAVE", "ixComputerDOSTiny", -152, 20, ACTIVE_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	-- 		end
	-- 	else
	-- 		draw.SimpleText("PRESS USE TO BOOT", "ixComputerDOSTiny", -152, -24, DIM_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	-- 	end
	-- cam.End3D2D()
end

function ENT:OnPopulateEntityInfo(container)
	local plugin = ix.plugin.Get("interactive_computers")
	local displayName = plugin and plugin:GetDisplayName(self:GetClass()) or L("interactiveComputer")
	local isInteractive = plugin and plugin:IsInteractiveComputer(self)
	local definition = plugin and plugin:GetComputerDefinition(self:GetClass())

	local name = container:AddRow("name")
	name:SetImportant()
	name:SetText(displayName)
	name:SizeToContents()

	local description = container:AddRow("description")
	description:SetText(L(isInteractive and "interactiveComputerDesc" or "interactiveComputerSupportDesc"))
	description:SizeToContents()

	if (isInteractive) then
		local action = container:AddRow("action")
		action:SetText(L("interactiveComputerUse"))
		action:SetBackgroundColor(Color(85, 127, 242, 50))
		action:SizeToContents()
	end
end
