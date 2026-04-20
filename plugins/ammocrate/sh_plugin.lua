local PLUGIN = PLUGIN

PLUGIN.name = "Easy Ammo Crate"
PLUGIN.author = "Frosty"
PLUGIN.description = "Adds an ammo crate entity that replenishes player ammo with a cooldown."

PLUGIN.license = [[
Copyright © 2026 Frosty

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/
]]

ix.lang.AddTable("english", {
	ammoCrateUseWait = "You cannot use this crate yet. (%d seconds remaining)",
	ammoCrateDesc = "An ammo supply crate that can replenish ammo for the weapon you are holding."
})

ix.lang.AddTable("korean", {
	ammoCrateUseWait = "아직 이 탄약 상자를 사용할 수 없습니다. (%d초 남음)",
	ammoCrateDesc = "보유하고 있는 무기의 탄약을 보충할 수 있는 탄약 보급 상자입니다."
})

if (SERVER) then
	function PLUGIN:SaveData()
		local data = {}

		for _, v in ipairs(ents.FindByClass("ix_ammocrate")) do
			data[#data + 1] = {
				pos = v:GetPos(),
				angles = v:GetAngles()
			}
		end

		self:SetData(data)
	end

	function PLUGIN:LoadData()
		for _, v in ipairs(self:GetData() or {}) do
			local entity = ents.Create("ix_ammocrate")
			entity:SetPos(v.pos)
			entity:SetAngles(v.angles)
			entity:Spawn()
			
			local phys = entity:GetPhysicsObject()
			if (IsValid(phys)) then
				phys:EnableMotion(false)
			end
		end
	end
end
