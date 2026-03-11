
local PLUGIN = PLUGIN

PLUGIN.spawner = PLUGIN.spawner or {}
PLUGIN.spawner.positions = PLUGIN.spawner.positions or {}

net.Receive("ixItemSpawnerManager", function()
	PLUGIN.spawner.positions = net.ReadTable()
	if (IsValid(ix.gui.itemSpawnerManager)) then
		ix.gui.itemSpawnerManager:Remove()
	end
	ix.gui.itemSpawnerManager = vgui.Create("ixItemSpawnerManager")
	ix.gui.itemSpawnerManager:Populate(PLUGIN.spawner.positions)
end)

net.Receive("ixItemSpawnerESP", function()
	PLUGIN.spawner.positions = net.ReadTable()
	
	if (IsValid(ix.gui.itemSpawnerManager)) then
		ix.gui.itemSpawnerManager:Populate(PLUGIN.spawner.positions)
	end
end)

function PLUGIN:HUDPaint()
	local client = LocalPlayer()
	
	if (!ix.option.Get("spawnerESP", false)) then return end
	if (client:GetMoveType() != MOVETYPE_NOCLIP) then return end
	if (client:InVehicle()) then return end
	if (!CAMI.PlayerHasAccess(client, "Helix - Item Spawner", nil)) then return end
	
	if (!PLUGIN.spawner.positions) then return end
	
	for _, v in ipairs(PLUGIN.spawner.positions) do
		if (v.position:DistToSqr(client:GetPos()) > 8388608) then continue end

		local pos = v.position:ToScreen()

		if (pos.visible) then
			draw.SimpleText(L("spawnerESPTitle", v.title), "BudgetLabel", pos.x, pos.y, Color(207, 142, 56), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			if (v.position:DistToSqr(client:GetPos()) <= 440000) then
				draw.SimpleText(L("spawnerESPInfo", v.delay, v.rarity), "BudgetLabel", pos.x, pos.y + 15, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end
end
