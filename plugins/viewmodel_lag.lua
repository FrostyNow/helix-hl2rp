local PLUGIN = PLUGIN

PLUGIN.name = "Viewmodel Lag"
PLUGIN.author = "Valve | Ported by OpenAI"
PLUGIN.description = "Adds optional HL2-style viewmodel lag while excluding ARC9 weapons, the toolgun, and the physgun."

ix.lang.AddTable("english", {
	optViewmodelLagEnabled = "Enable viewmodel lag",
	optdViewmodelLagEnabled = "Applies HL2-style viewmodel lag to supported weapons.",
})

ix.lang.AddTable("korean", {
	optViewmodelLagEnabled = "뷰모델 지연 활성화",
	optdViewmodelLagEnabled = "지원되는 무기에 HL2 스타일 뷰모델 지연 효과를 적용합니다.",
})

if (CLIENT) then
	ix.option.Add("viewmodelLagEnabled", ix.type.bool, true, {
		category = "appearance"
	})

	local EXCLUDED_WEAPON_CLASSES = {
		["gmod_tool"] = true,
		["weapon_physgun"] = true,
	}

	local function vectorMA(start, scale, direction, dest)
		dest.x = start.x + direction.x * scale
		dest.y = start.y + direction.y * scale
		dest.z = start.z + direction.z * scale
	end

	local function isARC9Weapon(weapon)
		if (!IsValid(weapon)) then
			return false
		end

		if (weapon.ARC9) then
			return true
		end

		local class = weapon:GetClass()

		if (ix.arc9 and ix.arc9.IsARC9WeaponClass and ix.arc9.IsARC9WeaponClass(class)) then
			return true
		end

		if (weapons.IsBasedOn and weapons.IsBasedOn(class, "arc9_base")) then
			return true
		end

		return false
	end

	local function shouldSkipWeapon(weapon)
		if (!IsValid(weapon)) then
			return true
		end

		local class = weapon:GetClass()

		if (EXCLUDED_WEAPON_CLASSES[class]) then
			return true
		end

		return isARC9Weapon(weapon)
	end

	local function calcViewModelLag(vm, origin, angles, originalAngles)
		local originalOrigin = Vector(origin.x, origin.y, origin.z)
		local originalAngle = Angle(angles.x, angles.y, angles.z)
		local lagScale = 1.5

		vm.ixLastFacing = vm.ixLastFacing or angles:Forward()

		local forward = angles:Forward()

		if (FrameTime() != 0) then
			local difference = forward - vm.ixLastFacing
			local speed = 5
			local diffLength = difference:Length()

			if (diffLength > lagScale and lagScale > 0) then
				speed = speed * (diffLength / lagScale)
			end

			vectorMA(vm.ixLastFacing, speed * FrameTime(), difference, vm.ixLastFacing)
			vm.ixLastFacing:Normalize()
			vectorMA(origin, 5, difference * -1, origin)
		end

		local right = originalAngles:Right()
		local up = originalAngles:Up()
		local pitch = originalAngles[1]

		if (pitch > 180) then
			pitch = pitch - 360
		elseif (pitch < -180) then
			pitch = pitch + 360
		end

		vectorMA(origin, -pitch * 0.035, forward, origin)
		vectorMA(origin, -pitch * 0.03, right, origin)
		vectorMA(origin, -pitch * 0.02, up, origin)

		return origin, angles, originalOrigin, originalAngle
	end

	function PLUGIN:CalcViewModelView(weapon, vm, oldPos, oldAng, pos, ang)
		if (!ix.option.Get("viewmodelLagEnabled", true)) then
			return
		end

		if (!IsValid(vm) or shouldSkipWeapon(weapon)) then
			if (IsValid(vm)) then
				vm.ixLastFacing = ang:Forward()
			end

			return
		end

		if (weapon.GetIronSights and weapon:GetIronSights()) then
			vm.ixLastFacing = ang:Forward()
			return
		end

		local newPos, newAng = calcViewModelLag(vm, pos, ang, oldAng)
		return newPos, newAng
	end
end
