local PLUGIN = PLUGIN

PLUGIN.name = "GModPatchTool Detector"
PLUGIN.author = "Frosty"
PLUGIN.desc = "Detects if GModPatchTool and x86-64 branch are running on client side."

--[[
	GModPatchTool (formerly GModCEFCodecFix) detection code example

	Copyright 2024-2026, Solstice Game Studios (solsticegamestudios.com)
	LICENSE: GNU General Public License v3.0

	Purpose: Detects if GModPatchTool's CEF patches have been applied successfully on a GMod client.

	Contact:
		Repository: https://github.com/solsticegamestudios/GModPatchTool/
		Discord: https://solsticegamestudios.com/discord/
		Email: contact@solsticegamestudios.com
]]

-- Localizations
if (CLIENT) then
	ix.lang.AddTable("korean", {
		gmodPatchToolX86 = "(권장) Garry's Mod의 베타 버전을 x86-64로 선택하셔야 서버의 모든 기능이 잘 작동합니다!",
		gmodPatchToolFix = "(선택) 커뮤니티에서 제작 및 유지 중인 GModPatchTool을 사용하셔야 서버의 모든 기능이 잘 작동합니다!"
	})

	ix.lang.AddTable("english", {
		gmodPatchToolX86 = "(Recommended) You should select the x86-64 beta version of Garry's Mod for all server features to work correctly!",
		gmodPatchToolFix = "(Optional) You should use GModPatchTool created and maintained by the community for all server features to work correctly!"
	})
end

if (SERVER) then
	util.AddNetworkString("ixGModPatchToolStatus")

	net.Receive("ixGModPatchToolStatus", function(length, client)
		local bIsX86 = net.ReadBool()
		local bHasPatch = net.ReadBool()

		-- Notify if not on x86-64 branch
		if (!bIsX86) then
			client:NotifyLocalized("gmodPatchToolX86")
		end

		-- Notify if GModPatchTool is not installed/working
		if (!bHasPatch) then
			client:NotifyLocalized("gmodPatchToolFix")
		end
	end)
else
	-- GModPatchTool (formerly GModCEFCodecFix) detection code
	-- Original logic by Solstice Game Studios

	CEFCodecFixChecked = false
	CEFCodecFixAvailable = false

	-- We hook PreRender for reliability
	hook.Add("PreRender", "CEFCodecFixCheck", function()
		hook.Remove("PreRender", "CEFCodecFixCheck")

		print("Querying CEF Codec Support...")

		local bIsX86 = BRANCH == "x86-64"
		-- CEF is generally available on x86-64 or Windows
		local bCEFAvailable = bIsX86 or system.IsWindows()

		-- If the client isn't on a version that likely has CEF, it's impossible for them to have CEFCodecFix
		if not bCEFAvailable then
			CEFCodecFixAvailable = false
			CEFCodecFixChecked = true

			print("CEF is not available on this platform/branch.")
			hook.Run("CEFCodecFixStatus", bIsX86, CEFCodecFixAvailable)
			return
		end

		local cefTestPanel = vgui.Create("DHTML", nil, "CEFCodecFixCheck")
		cefTestPanel:SetSize(32, 32)
		cefTestPanel:SetAlpha(0)
		cefTestPanel:SetMouseInputEnabled(false)
		cefTestPanel:SetKeyboardInputEnabled(false)

		function cefTestPanel:Paint()
			return true
		end

		function cefTestPanel:OnDocumentReady()
			if not CEFCodecFixChecked then
				self:AddFunction("gmod", "getCodecStatus", function(codecStatus)
					CEFCodecFixAvailable = codecStatus
					CEFCodecFixChecked = true

					print(CEFCodecFixAvailable and "CEF has CEFCodecFix" or "CEF does not have CEFCodecFix")

					hook.Run("CEFCodecFixStatus", bIsX86, CEFCodecFixAvailable)
					self:Remove()
				end)

				-- This checks if the web framework can play H.264
				self:QueueJavascript([[gmod.getCodecStatus(document.createElement("video").canPlayType('video/mp4; codecs="avc1.42E01E, mp4a.40.2"') == "probably")]])
			elseif IsValid(self) then
				self:Remove()
			end
		end

		cefTestPanel:SetHTML("")
	end)

	-- Send status to server once detected AND character is loaded
	function PLUGIN:CheckAndNotifyStatus()
		local client = LocalPlayer()

		if (self.DetectedStatus and IsValid(client) and client:GetCharacter() and !self.StatusSent) then
			net.Start("ixGModPatchToolStatus")
				net.WriteBool(self.DetectedStatus.bIsX86)
				net.WriteBool(self.DetectedStatus.bHasPatch)
			net.SendToServer()

			self.StatusSent = true
		end
	end

	hook.Add("CEFCodecFixStatus", "ixGModPatchToolInit", function(bIsX86, bHasPatch)
		PLUGIN.DetectedStatus = {
			bIsX86 = bIsX86,
			bHasPatch = bHasPatch
		}
		PLUGIN:CheckAndNotifyStatus()
	end)

	function PLUGIN:OnCharacterLoaded(character)
		self:CheckAndNotifyStatus()
	end
end
