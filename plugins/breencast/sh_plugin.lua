local PLUGIN = PLUGIN

PLUGIN.name = "Breen Cast"
PLUGIN.author = "Antigravity"
PLUGIN.description = "Breen Cast functionality with Dr. Breen NPC repeating lines."

ix.util.Include("sv_plugin.lua")

if (CLIENT) then
    ix.lang.Register("ko", {
        ["breenCast"] = "브린캐스트",
        ["breenCastDesc"] = "브린 박사가 대사와 애니메이션을 반복하도록 설정합니다.",
        ["breenCastSetLines"] = "대사 설정",
        ["breenCastInterval"] = "간격(초)",
        ["breenCastModel"] = "모델",
        ["breenCastLoop"] = "반복 재생",
        ["breenCastPlay"] = "재생 시작",
        ["breenCastStop"] = "재생 중지",
        ["breenCastSuccess"] = "브린캐스트 엔티티가 성공적으로 지정되었습니다.",
        ["breenCastNoBreen"] = "브린 박사 모델을 바라보고 있어야 합니다.",
        ["breenCastNoEntity"] = "엔티티를 바라보고 있어야 합니다."
    })
    ix.lang.Register("en", {
        ["breenCast"] = "Breen Cast",
        ["breenCastDesc"] = "Configure Dr. Breen to repeat lines and animations.",
        ["breenCastSetLines"] = "Set Lines",
        ["breenCastInterval"] = "Interval (Seconds)",
        ["breenCastModel"] = "Model",
        ["breenCastLoop"] = "Loop playback",
        ["breenCastPlay"] = "Start playback",
        ["breenCastStop"] = "Stop playback",
        ["breenCastSuccess"] = "Successfully designated Breen Cast entity.",
        ["breenCastNoBreen"] = "You must be looking at a Dr. Breen model.",
        ["breenCastNoEntity"] = "You must be looking at an entity."
    })
end
