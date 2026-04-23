PLUGIN.name = "Grenade Throwables"
PLUGIN.author = "Black Tea | Ported by Frosty"
PLUGIN.desc = "Grenade Throwables."

ix.lang.AddTable("english", {
	beaconDesc = "A throwable beacon that beeps and glows to call for attention.",
	flareDesc = "A throwable flare that emits dense smoke and glows to call for attention.",
	teargasDesc = "A throwable tear gas grenade that emits dense smoke and incapacitates an area for a moment.",
})

ix.lang.AddTable("korean", {
	["Throw"] = "투척하기",
	beaconDesc = "신호를 보내기 위해 투척할 수 있는 신호기입니다.",
	flareDesc = "연기와 함께 밝게 빛나며 신호를 보내기 위해 투척할 수 있는 신호탄입니다.",
	teargasDesc = "연기와 함께 퍼져나가 구역을 일시적으로 무력화시킬 수 있는 최루탄입니다.",

	["Yellow Beacon"] = "노란색 신호기",
	["Red Beacon"] = "빨간색 신호기",
	["Blue Beacon"] = "파란색 신호기",
	["Green Beacon"] = "초록색 신호기",

	["Blue Flare"] = "파란색 신호탄",
	["Green Flare"] = "초록색 신호탄",
	["Red Flare"] = "빨간색 신호탄",
	["Tear Gas"] = "최루탄",
})

function PLUGIN:Move(client, mv)
	if client:GetMoveType() != MOVETYPE_WALK then return end

	local teargas = client:GetNetVar("teargas")

	if (teargas and teargas > CurTime()) then
		local m = .25
		local f = mv:GetForwardSpeed() 
		local s = mv:GetSideSpeed() 
		mv:SetForwardSpeed( f * .005 )
		mv:SetSideSpeed( s * .005 )
	end
end

if (SERVER) then
	function PLUGIN:PlayerSpawn(client)
		client:SetNetVar("teargas", 0)
	end

	function PLUGIN:PlayerDeath(client)
		client:SetNetVar("teargas", 0)
	end
else
	local trg = 0
	local cur = 0
	local icon = {
		[1] = "R",
		[2] = "Z",
		[3] = "a",
		[4] = "b",
	}
	local w, h
	local lclient
	local myChar 
	function PLUGIN:HUDPaint()
		w, h = ScrW(), ScrH()
		lclient = LocalPlayer()
		myChar = lclient:GetCharacter()
		
		if (myChar) then
			if (!lclient:Alive()) then
				return
			end
			
			local teargas = lclient:GetNetVar("teargas")

			if (teargas and teargas > CurTime()) then
				trg = 120 + math.abs(math.sin( RealTime()*2 )*70)
			else
				trg = 0
			end

			cur = Lerp(FrameTime()*3, cur, trg)
			surface.SetDrawColor(255, 255, 255, cur)
			surface.DrawRect(0, 0, w, h)
			
			-- Nice optimizaion, Ass.
			for _, entity in pairs(GLOBAL_BEACONS) do
				local pos = entity:GetPos() + entity:OBBCenter()
				local scr = (pos):ToScreen()
				local dis = pos:Distance(lclient:GetPos())
				local what = entity:GetDTInt(0)

				local owner = entity:CPPIGetOwner()
				if (!owner) then return end

				local char = owner:GetCharacter()

				if (char and myChar) then
					local team = nut.class.list[myChar:getClass()].team
					
					if ((myChar == char) or (team and nut.class.list[char:getClass()].team == team)) then
						local matrix = Matrix()
						local scale = math.max(1, 1.5 - RealTime()*3%1.5)
						matrix:Translate(Vector(math.Clamp(scr.x - 20*scale, w*.1, w*.9), math.Clamp(scr.y - 20*scale, h*.1, h*.9)))
						matrix:Rotate(Angle(0, 0, 0))
						matrix:Scale(Vector(scale, scale))

						cam.PushModelMatrix(matrix)
							local tx, ty = nut.util.drawText(icon[what], 0, 0, color_white, 3, 5, "nutIconsBig")
							nut.util.drawText(math.Round(dis/10) .. " m", tx/2, 0 + ty*0.9, color_white, 1, 5, "nutSmallFont")
						cam.PopModelMatrix()
					end
				end
			end
		end
	end

	function PLUGIN:PlayerPostThink(client)
		if (client:GetCharacter()) then
			local teargas = client:GetNetVar("teargas")

			if (teargas and teargas > CurTime() and client:Alive()) then
				if (!client.nextCough or client.nextCough < CurTime()) then
					client.nextCough = CurTime() + math.random(2, 5)

					client:EmitSound( Format( "ambient/voices/cough%d.wav", math.random( 1, 4 ) ) )
				end
			end
		end
	end
end