ITEM.name = "저항군 전쟁 전 방탄 조끼"
ITEM.description = "저항을 상징하는 람다 마크가 칠해져 있습니다."
ITEM.model = "models/tnb/items/aphelion/shirt_rebel_molle.mdl"
ITEM.skin = 0
ITEM.width = 1
ITEM.height = 1
ITEM.armorAmount = 70
ITEM.gasmask = false -- It will protect you from bad air
ITEM.resistance = false -- This will activate the protection bellow
ITEM.damage = { -- It is scaled; so 100 damage * 0.8 will makes the damage be 80.
			1, -- Bullets
			1, -- Slash
			1, -- Shock
			1, -- Burn
			1, -- Radiation
			1, -- Acid
			1, -- Explosion
}
ITEM.outfitCategory = "torso"
ITEM.noResetBodyGroups = true
ITEM.hitGroups = {HITGROUP_CHEST, HITGROUP_STOMACH}
ITEM.bodyGroups = {
	["torso"] = 15
}
ITEM.allowedModels = {
	"models/tnb/citizens/aphelion/male_01.mdl",
	"models/tnb/citizens/aphelion/male_02.mdl",
	"models/tnb/citizens/aphelion/male_03.mdl",
	"models/tnb/citizens/aphelion/male_04.mdl",
	"models/tnb/citizens/aphelion/male_05.mdl",
	"models/tnb/citizens/aphelion/male_06.mdl",
	"models/tnb/citizens/aphelion/male_07.mdl",
	"models/tnb/citizens/aphelion/male_09.mdl",
	"models/tnb/citizens/aphelion/male_16.mdl",
	"models/tnb/citizens/aphelion/female_01.mdl",
	"models/tnb/citizens/aphelion/female_02.mdl",
	"models/tnb/citizens/aphelion/female_03.mdl",
	"models/tnb/citizens/aphelion/female_04.mdl",
	"models/tnb/citizens/aphelion/female_05.mdl",
	"models/tnb/citizens/aphelion/female_08.mdl",
	"models/tnb/citizens/aphelion/female_09.mdl",
	"models/tnb/citizens/aphelion/female_10.mdl",
	"models/tnb/citizens/aphelion/female_11.mdl"
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(Color(218, 24, 24))
		data:SetText(L("sociocidalItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end