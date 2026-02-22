
PLUGIN.name = "Combine Technology Overlay"
PLUGIN.author = "Trudeau & Aspect™"
PLUGIN.description = "A Helix port of the modern overhaul of Combine technology designed with non-intrusiveness and responsiveness in mind."

ix.util.Include("cl_hooks.lua")
ix.util.Include("cl_plugin.lua")
ix.util.Include("sh_commands.lua")
ix.util.Include("sh_configs.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("sv_plugin.lua")

ix.lang.AddTable("english", {
	["Camera Terminal"] = "Camera Terminal",
	cameraTerminalDesc = "A terminal connected to surveillance cameras.",
	notCombine = "You are not the Combine!",
})

ix.lang.AddTable("korean", {
	["Camera Terminal"] = "카메라 단말기",
	cameraTerminalDesc = "감시 카메라와 연결된 단말기입니다.",
	notCombine = "당신은 콤바인이 아닙니다!",
})

PLUGIN.sociostatusColors = {
	GREEN = Color(0, 255, 0),
	BLUE = Color(0, 128, 255),
	YELLOW = Color(255, 255, 0),
	RED = Color(255, 0, 0),
	BLACK = Color(128, 128, 128)
}

-- Biosignal change enums, used for player/admin command language variations.
PLUGIN.ERROR_NONE = 0
PLUGIN.ERROR_NOT_COMBINE = 1
PLUGIN.ERROR_ALREADY_ENABLED = 2
PLUGIN.ERROR_ALREADY_DISABLED = 3

-- Movement violation enums, used when networking cameras.
PLUGIN.VIOLATION_RUNNING = 0
PLUGIN.VIOLATION_JUMPING = 1
PLUGIN.VIOLATION_CROUCHING = 2
PLUGIN.VIOLATION_FALLEN_OVER = 3

-- Camera controlling enums.
PLUGIN.CAMERA_VIEW = 0
PLUGIN.CAMERA_DISABLE = 1
PLUGIN.CAMERA_ENABLE = 2

function PLUGIN:isCameraEnabled(camera)
	return camera:GetSequenceName(camera:GetSequence()) == "idlealert"
end

if (SERVER) then
	function PLUGIN:SaveData()
		local data = {}

		for _, v in ipairs(ents.FindByClass("ix_ctocameraterminal")) do
			data[#data + 1] = {	
				pos = v:GetPos(),
				angles = v:GetAngles(),
				color = v:GetColor(),
			}
		end

		ix.data.Set("camera_terminals", data)
	end

	function PLUGIN:LoadData()
		local data = ix.data.Get("camera_terminals") or {}

		for _, v in ipairs(data) do
			local entity = ents.Create("ix_ctocameraterminal")
			entity:SetPos(v.pos)
			entity:SetAngles(v.angles)
			entity:SetColor(v.color)
			entity:Spawn()

			local physicsObject = entity:GetPhysicsObject()

			if (IsValid(physicsObject)) then
				physicsObject:Wake()
			end
		end
	end
end