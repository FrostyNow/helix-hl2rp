
ITEM.name = "MPF Gear Pack"
ITEM.model = Model("models/hls/alyxports/cardboard_box_1.mdl")
ITEM.description = "cpGearSupplyDesc"
ITEM.category = "Utility"
ITEM.items = {
	"bag",
	"cp_mask",
	"gasmask_filter",
	"cp_vest_mpf",
	"stunstick",
	"pistol",
	"pistolammo",
	"handheld_radio",
	"flashlight",
	"zip_tie",
	"zip_tie",
}
ITEM.price = 400
ITEM.exRender = true
ITEM.iconCam = {
	pos = Vector(356.67, 303.02, 565.94),
	ang = Angle(50.52, 221.21, 0),
	fov = 1.88
}

ITEM.functions.Open = {
	icon = "icon16/email_open.png",
	OnRun = function(itemTable)
		local client = itemTable.player
		local character = client:GetCharacter()
		local inv = character:GetInventory()

		for k, v in ipairs(itemTable.items) do
			if (!inv:Add(v)) then
				ix.item.Spawn(v, client)
			end
		end

		client:EmitSound("ambient/fire/mtov_flame2.wav", 75, math.random(160, 180), 0.35)
	end,
	OnCanRun = function(item)
		local char = item.player:GetCharacter()
		return char:HasFlags("M")
	end
}
