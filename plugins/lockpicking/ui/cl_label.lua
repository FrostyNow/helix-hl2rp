local LABEL = {}

function LABEL:Init()
	self:SetFont("ixGenericFont")
	self:SetTextColor( ix.config.Get("color") or Color(255, 182, 66, 255) )
end

function LABEL:SetText(text)
    self.BaseClass.SetText(self, text)
	self:SizeToContents()
end

vgui.Register("lockpickingLabel", LABEL, "DLabel")