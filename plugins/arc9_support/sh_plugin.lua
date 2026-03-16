PLUGIN.name = "ARC9 Base Support"
PLUGIN.author = "OpenAI, Ronald, bruck"
PLUGIN.description = "Adds ARC9 preset persistence, icon/worldmodel attachment rendering, and item-level TPIK overrides."

ix.util.Include("sh_net.lua")
ix.util.IncludeDir(PLUGIN.folder .. "/libs", true)
ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)

ix.lang.AddTable("english", {
	["ARC9 Attachments"] = "ARC9 부착물",
})

function PLUGIN:OnLoaded()
    if (SERVER) then
        local conVar = GetConVar("arc9_mult_defaultammo")

        if (conVar) then
            conVar:SetInt(0)
        end
    end
end
