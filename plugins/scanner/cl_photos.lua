local PLUGIN = PLUGIN

local PICTURE_WIDTH = PLUGIN.PICTURE_WIDTH
local PICTURE_HEIGHT = PLUGIN.PICTURE_HEIGHT
local PICTURE_WIDTH2 = PICTURE_WIDTH * 0.5
local PICTURE_HEIGHT2 = PICTURE_HEIGHT * 0.5

PHOTO_CACHE = PHOTO_CACHE or {}

function PLUGIN:takePicture()
    if ((self.lastPic or 0) < CurTime()) then
        self.lastPic = CurTime() + 15

        net.Start("ixScannerPicture")
        net.SendToServer()

        timer.Simple(0.1, function()
            self.startPicture = true
        end)
    end
end

local surveillanceRT = GetRenderTarget("ixSurveillanceRT", PICTURE_WIDTH, PICTURE_HEIGHT)



ix.lang.AddTable("english", {
    SurveillanceCapture = "SURVEILLANCE CAPTURE",
    ScannerCapture = "SCANNER CAPTURE",
})

ix.lang.AddTable("korean", {
    SurveillanceCapture = "감시 카메라 촬영",
    ScannerCapture = "스캐너 촬영",
})

function PLUGIN:PostRender()
    if (self.surveillanceRequest) then
        local camera = self.surveillanceRequest
        self.surveillanceRequest = nil

        local bonePos, boneAngles = camera:GetBonePosition(camera:LookupBone("Combine_Camera.bone1"))
        if (bonePos) then
            local camPos, camAngles = camera:GetBonePosition(camera:LookupBone("Combine_Camera.Lens"))
            boneAngles.roll = boneAngles.roll + 90

            render.PushRenderTarget(surveillanceRT)
            render.Clear(0, 0, 0, 255)
            render.RenderView({
                origin = camPos + (boneAngles:Forward() * 2.8),
                angles = boneAngles,
                fov = 90,
                aspect = PICTURE_WIDTH / PICTURE_HEIGHT,
                x = 0,
                y = 0,
                w = PICTURE_WIDTH,
                h = PICTURE_HEIGHT,
                drawviewmodel = false
            })

            local data = util.Compress(render.Capture({
                format = "jpeg",
                h = PICTURE_HEIGHT,
                w = PICTURE_WIDTH,
                quality = 30,
                x = 0,
                y = 0
            }))
            render.PopRenderTarget()

            net.Start("ixScannerData")
                net.WriteBool(true) -- Surveillance
                net.WriteUInt(#data, 16)
                net.WriteData(data, #data)
            net.SendToServer()
        end
    end

    if (self.startPicture) then
        local data = util.Compress(render.Capture({
            format = "jpeg",
            h = PICTURE_HEIGHT,
            w = PICTURE_WIDTH,
            quality = 35,
            x = ScrW() * 0.5 - PICTURE_WIDTH2,
            y = ScrH() * 0.5 - PICTURE_HEIGHT2
        }))

        net.Start("ixScannerData")
            net.WriteBool(false) -- Regular
            net.WriteUInt(#data, 16)
            net.WriteData(data, #data)
        net.SendToServer()
        
        self.startPicture = false
    end
end

net.Receive("ixScannerData", function()
    local isSurveillance = net.ReadBool()
    local data = net.ReadData(net.ReadUInt(16))
    data = util.Base64Encode(util.Decompress(data))

    if (not data) then return end

    if (isSurveillance) then
        ix.util.EmitQueuedSounds(LocalPlayer(), {
            "npc/metropolice/vo/on" .. math.random(1, 2) .. ".wav",
            "npc/overwatch/radiovoice/preparevisualdownload.wav",
            "npc/metropolice/vo/off" .. math.random(1, 4) .. ".wav"
        }, 0, 0.1, 0)
    else
        ix.util.EmitQueuedSounds(LocalPlayer(), {
            "npc/metropolice/vo/on" .. math.random(1, 2) .. ".wav",
            "npc/overwatch/radiovoice/visualidentificationat.wav",
            "npc/metropolice/vo/off" .. math.random(1, 4) .. ".wav"
        }, 0, 0.1, 0)
    end

    if (IsValid(CURRENT_PHOTO)) then
        local panel = CURRENT_PHOTO

        CURRENT_PHOTO:AlphaTo(0, 0.25, 0, function()
            if (IsValid(panel)) then
                panel:Remove()
            end
        end)
    end

    local html = Format([[
        <html>
            <body style="background: black; overflow: hidden; margin: 0; padding: 0;">
                <img src="data:image/jpeg;base64,%s" width="%s" height="%s" />
            </body>
        </html>
    ]], data, PICTURE_WIDTH, PICTURE_HEIGHT)

    local panel = vgui.Create("DPanel")
    panel:SetSize(PICTURE_WIDTH + 8, PICTURE_HEIGHT + 8)
    panel:SetPos(ScrW(), 8)
    panel:SetDrawBackground(true)
    panel:SetAlpha(150)

    panel.body = panel:Add("DHTML")
    panel.body:Dock(FILL)
    panel.body:DockMargin(4, 4, 4, 4)
    panel.body:SetHTML(html)

    local title = isSurveillance and "@SurveillanceCapture" or "@ScannerCapture"
    panel:MoveTo(ScrW() - (panel:GetWide() + 8), 8, 0.5)

    local function DrawSurveillanceText()
        if (IsValid(panel)) then
            draw.SimpleText(L(title), "ixScannerFont", 4, 4, color_white)
        end
    end
    panel.PaintOver = DrawSurveillanceText

    timer.Simple(15, function()
        if (IsValid(panel)) then
            panel:MoveTo(ScrW(), 8, 0.5, 0, -1, function()
                panel:Remove()
            end)
        end
    end)

    PHOTO_CACHE[#PHOTO_CACHE + 1] = {data = html, time = os.time()}
    if (#PHOTO_CACHE > 50) then
        table.remove(PHOTO_CACHE, 1)
    end
    CURRENT_PHOTO = panel
end)

concommand.Add("ix_scanner_photocache", function()
	local bAllowed = false

	if (LocalPlayer():IsCombine() and Schema:CanPlayerSeeCombineOverlay(LocalPlayer())) then
		bAllowed = true
	else
		for _, v in ipairs(ents.FindByClass("ix_ctocameraterminal")) do
			if (v:GetPos():DistToSqr(LocalPlayer():GetPos()) <= 150 * 150) then
				bAllowed = true
				break
			end
		end
	end

	if (bAllowed) then
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L("Photo Cache"))
		frame:SetSize(480, 360)
		frame:MakePopup()
		frame:Center()

		frame.list = frame:Add("DScrollPanel")
		frame.list:Dock(FILL)
		frame.list:SetDrawBackground(true)

		for k, v in ipairs(PHOTO_CACHE) do
			local button = frame.list:Add("DButton")
			button:SetTall(28)
			button:Dock(TOP)
			button:DockMargin(4, 4, 4, 0)
			button:SetText(os.date("%X - %d/%m/%Y", v.time))
			button.DoClick = function()
				local frame2 = vgui.Create("DFrame")
				frame2:SetSize(PICTURE_WIDTH + 8, PICTURE_HEIGHT + 8)
				frame2:SetTitle(button:GetText())
				frame2:MakePopup()
				frame2:Center()

				frame2.body = frame2:Add("DHTML")
				frame2.body:SetHTML(v.data)
				frame2.body:Dock(FILL)
				frame2.body:DockMargin(4, 4, 4, 4)
			end
		end
	else
		LocalPlayer():NotifyLocalized("cacheCmbOnly")
		return false
	end
end)

net.Receive("ixSurveillancePhotoRequest", function()
    local camera = net.ReadEntity()
    if (!IsValid(camera)) then return end

    -- 해당 카메라를 출력 중인 터미널이 있는지 확인 (이미 렌더링 중인 자원 활용)
    local cto = ix.plugin.Get("cto")
    if (cto and cto.terminalsToDraw) then
        for terminal, bDraw in pairs(cto.terminalsToDraw) do
            if (IsValid(terminal) and bDraw and terminal:GetNWEntity("camera") == camera and terminal.tex) then
                render.PushRenderTarget(terminal.tex)
                local data = util.Compress(render.Capture({
                    format = "jpeg",
                    h = 256,
                    w = 512,
                    quality = 30,
                    x = 0,
                    y = 0
                }))
                render.PopRenderTarget()

                if (data) then
                    net.Start("ixScannerData")
                        net.WriteBool(true)
                        net.WriteUInt(#data, 16)
                        net.WriteData(data, #data)
                    net.SendToServer()
                    return
                end
            end
        end
    end

    -- 터미널이 없으면 백그라운드에서 직접 1컷 렌더링 요청
    PLUGIN.surveillanceRequest = camera
end)