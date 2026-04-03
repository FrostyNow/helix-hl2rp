local PLUGIN = PLUGIN
PLUGIN.name = "Easy Medikit"
PLUGIN.description = "A small base of medical kit (Heal yourself, heal others, works with medical attribute)"
PLUGIN.author = "Subleader"

do
	ix.char.RegisterVar("bleeding", {
		field = "bleeding",
		fieldType = ix.type.bool,
		default = false,
		isLocal = false,
		bNoDisplay = true
	})

	ix.char.RegisterVar("fracture", {
		field = "fracture",
		fieldType = ix.type.bool,
		default = false,
		isLocal = false,
		bNoDisplay = true
	})
end

if (CLIENT) then
	function PLUGIN:PopulateCharacterInfo(player, character, tooltip)
		if (character:GetBleeding()) then
			local row = tooltip:AddRow("bleeding")
			row:SetText(L("isBleeding"))
			row:SetBackgroundColor(Color(200, 0, 0))
			row:SetTextColor(color_white)
			row:SizeToContents()
		end

		if (character:GetFracture()) then
			local row = tooltip:AddRow("fracture")
			row:SetText(L("isFractured"))
			row:SetBackgroundColor(Color(200, 0, 0))
			row:SetTextColor(color_white)
			row:SizeToContents()
		end
	end
end

ix.util.Include("sv_hooks.lua", "server")