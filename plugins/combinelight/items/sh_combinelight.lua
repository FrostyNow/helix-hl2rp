ITEM.name = "Combine Light"
ITEM.uniqueID = "comlight"
ITEM.description = "comlightDesc"
ITEM.model = "models/props_combine/combine_light001a.mdl"
ITEM.width = 1
ITEM.height = 2
ITEM.price = 100
ITEM.iconCam = {
	pos = Vector(453.60931396484, 381.55184936523, 296.04327392578),
	ang = Angle(25, 220, 0),
	fov = 2.75
}
ITEM.exRender = true
ITEM.functions.Place = {
	icon = "icon16/anchor.png",
	OnRun = function(item)
		local client = item.player

		net.Start("ixCombineLightStartPlacement")
			net.WriteUInt(item:GetID(), 32)
			net.WriteString(item.model)
		net.Send(client)

		return false
	end,
	OnCanRun = function(item)
		return !IsValid(item.entity)
	end
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local data = tooltip:AddRow("data")
		data:SetBackgroundColor(team.GetColor(FACTION_MPF))
		data:SetText(L("securitizedItemTooltip"))
		data:SetExpensiveShadow(0.5)
		data:SizeToContents()
	end
end