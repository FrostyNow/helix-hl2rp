local PLUGIN = PLUGIN

ITEM.name = "Medikit"
ITEM.description = "A Medikit Base."
ITEM.category = "Medical"
ITEM.model = "models/Gibs/HGIBS.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.healthPoint = 0
ITEM.medAttr = 0
ITEM.bleeding = false
ITEM.fracture = false
ITEM.sound = nil

function ITEM:GetDescription()
	return (L(self.description) .. L("itemMedkitDesc01") .. self.medAttr .. L("itemMedkitDesc02") .. self.healthPoint)
end

ITEM.functions.selfheal = {
	icon = "icon16/pill.png",
	OnRun = function(itemTable)
		local client = itemTable.player
		local character = client:GetCharacter()
		local int = character:GetAttribute("int", 0)
		local maxAttr = ix.config.Get("maxAttributes", 100)
		if int >= itemTable.medAttr then
			client:SetNetworkedFloat("NextBandageuse", 2 + CurTime())
			local amount = math.floor(itemTable.healthPoint * (1 + int / maxAttr))
			local newHealth = client:Health() + amount

			if (newHealth <= 0) then
				local dmg = DamageInfo()
				dmg:SetDamage(client:Health() + 100)
				dmg:SetAttacker(client)
				dmg:SetInflictor(client)
				dmg:SetDamageType(DMG_SHOCK)
				dmg:SetDamageForce(client:GetAimVector() * -8000)

				client:TakeDamageInfo(dmg)
			else
				client:SetHealth(math.Clamp(newHealth, 0, client:GetMaxHealth()))
			end
			character:SetAttrib("int", int + 0.2)
			if itemTable.bleeding then
				PLUGIN:SetBleeding(client, false)
			end
			if itemTable.fracture then
				PLUGIN:SetFracture(client, false)
			end
			if itemTable.sound then
				client:EmitSound(itemTable.sound)
			end
		else
			client:NotifyLocalized("lackKnowledge")
			return false
		end
	end
}
ITEM.functions.heal = {
	icon = "icon16/pill.png",
	OnRun = function(itemTable)
		local client = itemTable.player
		local character = client:GetCharacter()
		local int = character:GetAttribute("int", 0)
		local maxAttr = ix.config.Get("maxAttributes", 100)
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 96
			data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		if (IsValid(entity) and entity:IsRagdoll()) then
			entity = entity:GetNetVar("player", entity)
		end

		-- Check if the entity is a valid door.
		if (IsValid(entity) and entity:IsPlayer()) then
			if int >= itemTable.medAttr then
				entity:SetNetworkedFloat("NextBandageuse", 2 + CurTime())
				local amount = math.floor(itemTable.healthPoint * (1 + int / maxAttr))
				local newHealth = entity:Health() + amount

				if (newHealth <= 0) then
				local dmg = DamageInfo()
					dmg:SetDamage(entity:Health() + 100)
					dmg:SetAttacker(client)
					dmg:SetInflictor(client)
					dmg:SetDamageType(DMG_SHOCK)
					dmg:SetDamageForce(client:GetAimVector() * 8000)

					entity:TakeDamageInfo(dmg)
				else
					entity:SetHealth(math.Clamp(newHealth, 0, entity:GetMaxHealth()))
				end
				character:SetAttrib("int", int + 0.2)
				if itemTable.bleeding then
					PLUGIN:SetBleeding(entity, false)
				end
				if itemTable.fracture then
					PLUGIN:SetFracture(entity, false)
				end
				if itemTable.sound then
					client:EmitSound(itemTable.sound)
				end
				
				-- Sound is handled by individual item hooks (selfheal/heal)
			else
				client:NotifyLocalized("lackKnowledge")
				return false
			end
		else
			client:NotifyLocalized("cNotValid")
			return false
		end
	end,
	OnCanRun =  function(item)
		local ent = item.player:GetEyeTraceNoCursor().Entity
		
		return IsValid(ent) and (ent:IsPlayer() or ent:IsRagdoll())
	end
}