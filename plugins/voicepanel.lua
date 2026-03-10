PLUGIN.name = "Voice Overlay"
PLUGIN.author = "Black Tea | Modified by Frosty"
PLUGIN.desc = "This plugin makes voice overlay clear and look nice (really?)"

if (CLIENT) then
	local PANEL = {}
	local ixVoicePanels = {}

	function PANEL:Init()
		self.Icon = vgui.Create("DLabel", self)
		self.Icon:SetFont("ixIconsMedium")
		self.Icon:Dock(LEFT)
		self.Icon:DockMargin(8, 0, 8, 0)
		self.Icon:SetTextColor(color_white)
		self.Icon:SetText("i")
		self.Icon:SetWide(30)
		self.Icon:SetExpensiveShadow(1, Color(0, 0, 0, 150))

		self.LabelName = vgui.Create("DLabel", self)
		self.LabelName:SetFont("ixMediumFont")
		self.LabelName:Dock(FILL)
		self.LabelName:DockMargin(0, 0, 0, 0)
		self.LabelName:SetTextColor(color_white)
		self.LabelName:SetExpensiveShadow(1, Color(0, 0, 0, 150))

		self.Color = color_transparent

		self:SetSize(280, 32 + 8)
		self:DockPadding(4, 4, 4, 4)
		self:DockMargin(2, 2, 2, 2)
		self:Dock(BOTTOM)
	end

	function PANEL:Setup(client)
		self.client = client
		self:InvalidateLayout()
	end

	function PANEL:Paint(w, h)
		if (!IsValid(self.client)) then return end

		ix.util.DrawBlur(self, 1, 2)

		surface.SetDrawColor(0, 0, 0, 50 + self.client:VoiceVolume() * 50)
		surface.DrawRect(0, 0, w, h)
	end

	function PANEL:Think()
		if (IsValid(self.client)) then
			local client = self.client
			local character = client:GetCharacter()
			local localChar = LocalPlayer():GetCharacter()
			local name = client:Nick()
			local color = color_white

			if (character and localChar) then
				local bRecognized = client == LocalPlayer() or localChar:DoesRecognize(character) or hook.Run("IsPlayerRecognized", client)

				if (bRecognized) then
					name = hook.Run("ShouldAllowScoreboardOverride", client, "name") and hook.Run("GetDisplayedName", client) or client:GetName()

					local class = ix.class.Get(character:GetClass())
					if (class and class.color) then
						color = class.color
					else
						color = team.GetColor(client:Team())
					end
				else
					name = L("unknown")
					color = color_white
				end
			end

			if (self.LabelName:GetText() != name) then
				self.LabelName:SetText(name)

				surface.SetFont("ixMediumFont")
				local nameW = surface.GetTextSize(name)
				local totalW = math.max(280, nameW + 30 + 16 + 16) -- icon(30) + margins(16) + padding(8*2)

				if (self:GetWide() != totalW) then
					self:SetWide(totalW)
				end
			end

			if (self.LabelName:GetTextColor() != color) then
				self.LabelName:SetTextColor(color)
				self.Icon:SetTextColor(color)
			end
		end

		if (self.fadeAnim) then
			self.fadeAnim:Run()
		end
	end

	function PANEL:FadeOut(anim, delta, data)
		if (anim.Finished) then
			if (IsValid(ixVoicePanels[self.client])) then
				ixVoicePanels[self.client]:Remove()
				ixVoicePanels[self.client] = nil
				return
			end
		return end

		self:SetAlpha(255 - (255 * (delta * 2)))
	end

	vgui.Register("VoicePanel", PANEL, "DPanel")

	function PLUGIN:PlayerStartVoice(client)
		if (!IsValid(ixVoicePanelList) or !ix.config.Get("allowVoice", false)) then return end

		hook.Run("PlayerEndVoice", client)

		if (IsValid(ixVoicePanels[client])) then
			if (ixVoicePanels[client].fadeAnim) then
				ixVoicePanels[client].fadeAnim:Stop()
				ixVoicePanels[client].fadeAnim = nil
			end

			ixVoicePanels[client]:SetAlpha(255)

			return
		end

		if (!IsValid(client)) then return end

		local pnl = ixVoicePanelList:Add("VoicePanel")
		pnl:Setup(client)

		ixVoicePanels[client] = pnl
	end

	local function VoiceClean()
		for k, v in pairs(ixVoicePanels) do
			if (!IsValid(k)) then
				hook.Run("PlayerEndVoice", k)
			end
		end
	end
	timer.Create("VoiceClean", 10, 0, VoiceClean)

	function PLUGIN:PlayerEndVoice(client)
		if (IsValid(ixVoicePanels[client])) then
			if (ixVoicePanels[client].fadeAnim) then return end

			ixVoicePanels[client].fadeAnim = Derma_Anim("FadeOut", ixVoicePanels[client], ixVoicePanels[client].FadeOut)
			ixVoicePanels[client].fadeAnim:Start(2)
		end
	end

	local function CreateVoiceVGUI()
		gmod.GetGamemode().PlayerStartVoice = function() end
		gmod.GetGamemode().PlayerEndVoice = function() end

		if (IsValid(ixVoicePanelList)) then
			ixVoicePanelList:Remove()
		end

		ixVoicePanelList = vgui.Create("DPanel")

		ixVoicePanelList:ParentToHUD()
		ixVoicePanelList:SetSize(600, ScrH() - 200)
		ixVoicePanelList:SetPos(ScrW() - 620, 100)
		ixVoicePanelList:SetPaintBackground(false)
	end

	hook.Add("InitPostEntity", "CreateVoiceVGUI", CreateVoiceVGUI)
end