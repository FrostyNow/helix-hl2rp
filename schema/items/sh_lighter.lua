ITEM.name = "Lighter"
ITEM.description = "itemLighterDesc"
ITEM.price = 20
ITEM.model = "models/hls/alyxports/tabletop_lighter.mdl"
ITEM.isjunk = true
ITEM.isStackable = true
ITEM.usenum = 10

ITEM.functions.Ignite = {
	tip = "igniteTip",
	icon = "icon16/fire.png",
	OnRun = function(item)
		local client = item.player
		local data = item:GetData("uses", item.usenum)

		if (data <= 0) then
			return false
		end

		local trace = client:GetEyeTraceNoCursor()
		local hitPos = trace.HitPos

		if (client:GetPos():DistToSqr(hitPos) <= 90 * 90) then
			item:SetData("uses", data - 1)
			
			client:EmitSound("ambient/fire/mtl_fire_ignite.wav", 50, 120)

			-- Damage logic
			if (SERVER and IsValid(trace.Entity)) then
				local dmg = DamageInfo()
				dmg:SetDamage(1)
				dmg:SetDamageType(DMG_BURN)
				dmg:SetAttacker(client)
				dmg:SetInflictor(client)
				dmg:SetDamagePosition(hitPos)
				dmg:SetDamageForce(Vector(0, 0, 0))
				trace.Entity:TakeDamageInfo(dmg)
			end

			-- Effect
			local effectData = EffectData()
			effectData:SetOrigin(hitPos)
			effectData:SetNormal(trace.HitNormal)
			util.Effect("StunstickImpact", effectData)

			-- 0.5s Ember (Light)
			if (SERVER) then
				local light = ents.Create("light_dynamic")
				if (IsValid(light)) then
					light:SetPos(hitPos + trace.HitNormal * 4)
					light:SetKeyValue("_light", "255 150 50 200")
					light:SetKeyValue("brightness", "1")
					light:SetKeyValue("distance", "128")
					light:SetKeyValue("style", "0")
					light:Spawn()
					light:Activate()
					light:Fire("TurnOn", "", 0)
					
					-- Remove after 0.5s
					timer.Simple(0.5, function()
						if (IsValid(light)) then
							light:Remove()
						end
					end)
				end
			end

			return false
		end

		return false
	end,
	OnCanRun = function(item)
		return item:GetData("uses", item.usenum) > 0
	end
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		local panel = tooltip:AddRow("uses")
		panel:SetBackgroundColor(Color(219, 189, 70))
		panel:SetText(L("usesLeft", self:GetData("uses", self.usenum)))
		panel:SizeToContents()
	end
end