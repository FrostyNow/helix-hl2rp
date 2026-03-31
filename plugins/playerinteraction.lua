local PLUGIN = PLUGIN

PLUGIN.name = "Player Interaction"
PLUGIN.description = "Provides a polished close-range interaction menu for player-to-player actions."
PLUGIN.author = "Riggs Mackay | Reworked by Frosty"
PLUGIN.schema = "HL2 RP"
PLUGIN.license = [[
Copyright 2022 Riggs Mackay

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

PLUGIN.interactionRange = 96
PLUGIN.untieDuration = 5
PLUGIN.useCooldown = 0.35
PLUGIN.menuCooldown = 0.2

ix.lang.AddTable("english", {
    interactionMenuTitle = "Interaction Menu",
    interactionMenuNoTarget = "No target",
    interactionMenuHint = "Look at a nearby player to interact with them.",
    interactionMenuNoDescription = "No description available.",
    interactionMenuEmpty = "No interactions are currently available.",
    interactionMenuOpenHint = "Look at a nearby player first.",
    interactionMenuInvalidPlayer = "Invalid player.",
    interactionMenuNeedValidTarget = "You must be looking at a valid player.",
    interactionMenuSelfTarget = "You can't interact with yourself.",
    interactionMenuMissingCharacter = "A character is missing.",
    interactionMenuTooFar = "That player is too far away.",
    interactionMenuNoSight = "You need a clear line of sight.",
    interactionMenuInvalidInteraction = "Invalid interaction.",
    interactionMenuCooldown = "Slow down.",
    interactionMenuRestrained = "You cannot do that while restrained.",
    interactionMenuTargetUntied = "They are not restrained.",
    interactionMenuAlreadyUntying = "Someone is already untying them.",
    interactionMenuUntiedYou = "%s untied you.",
    interactionMenuUntiedTarget = "You untied %s.",
    interactionMenuUntieCancelled = "Untying cancelled.",
    interactionMenuRecognizedAlready = "You already recognize this person.",
    interactionMenuRecognizedTarget = "You recognize %s.",
    interactionMenuRecognizedTargetAlready = "You already recognize %s.",
    interactionMenuMissingInteraction = "That interaction no longer exists.",
    interactionSearch = "Search",
    interactionSearchDesc = "Search a restrained player.",
    interactionUntie = "Untie",
    interactionUntieDesc = "Carefully untie a restrained player.",
    interactionRecognize = "Recognize",
    interactionRecognizeDesc = "Commit this person to memory.",
    interactionScoreboard = "Interact",
    interactionVortFree = "Free Vortigaunt",
    interactionVortFreeDesc = "Remove shackles from an enslaved Vortigaunt.",
    interactionVortShackle = "Shackle Vortigaunt",
    interactionVortShackleDesc = "Apply shackles to a free Vortigaunt.",
    interactionVortAlreadyFree = "That Vortigaunt is already free.",
    interactionVortAlreadyShackled = "That Vortigaunt is already shackled.",
    interactionHeal = "Heal",
    interactionHealDesc = "Heal the person using a medical item.",
    interactionRevive = "Revive",
    interactionReviveDesc = "Revive the person using a medical item."
})

ix.lang.AddTable("korean", {
    interactionMenuTitle = "상호작용 메뉴",
    interactionMenuNoTarget = "대상 없음",
    interactionMenuHint = "가까운 플레이어를 바라보고 상호작용하세요.",
    interactionMenuNoDescription = "설명이 없습니다.",
    interactionMenuEmpty = "현재 사용할 수 있는 상호작용이 없습니다.",
    interactionMenuOpenHint = "먼저 가까운 플레이어를 바라보세요.",
    interactionMenuInvalidPlayer = "유효하지 않은 플레이어입니다.",
    interactionMenuNeedValidTarget = "유효한 플레이어를 바라봐야 합니다.",
    interactionMenuSelfTarget = "자기 자신에게는 사용할 수 없습니다.",
    interactionMenuMissingCharacter = "캐릭터 정보를 찾을 수 없습니다.",
    interactionMenuTooFar = "대상이 너무 멉니다.",
    interactionMenuNoSight = "시야가 확보되어야 합니다.",
    interactionMenuInvalidInteraction = "유효하지 않은 상호작용입니다.",
    interactionMenuCooldown = "너무 빠르게 사용할 수 없습니다.",
    interactionMenuRestrained = "묶인 상태에서는 이 행동을 할 수 없습니다.",
    interactionMenuTargetUntied = "대상이 묶여 있지 않습니다.",
    interactionMenuAlreadyUntying = "이미 다른 누군가가 풀어주고 있습니다.",
    interactionMenuUntiedYou = "%s(이)가 당신을 풀어주었습니다.",
    interactionMenuUntiedTarget = "%s(을)를 풀어주었습니다.",
    interactionMenuUntieCancelled = "포박 해제가 취소되었습니다.",
    interactionMenuRecognizedAlready = "이미 인식한 사람입니다.",
    interactionMenuRecognizedTarget = "%s(을)를 인식했습니다.",
    interactionMenuRecognizedTargetAlready = "이미 %s(을)를 인식하고 있습니다.",
    interactionMenuMissingInteraction = "더 이상 존재하지 않는 상호작용입니다.",
    interactionSearch = "수색",
    interactionSearchDesc = "묶인 플레이어를 수색합니다.",
    interactionUntie = "포박 해제",
    interactionUntieDesc = "묶인 플레이어를 조심스럽게 풀어줍니다.",
    interactionRecognize = "인식",
    interactionRecognizeDesc = "이 사람을 기억해 둡니다.",
    interactionScoreboard = "상호작용",
    interactionVortFree = "보르티곤트 해방",
    interactionVortFreeDesc = "노예 보르티곤트의 족쇄를 해제합니다.",
    interactionVortShackle = "보르티곤트 족쇄",
    interactionVortShackleDesc = "해방된 보르티곤트에게 족쇄를 채웁니다.",
    interactionVortAlreadyFree = "대상 보르티곤트는 이미 해방된 상태입니다.",
    interactionVortAlreadyShackled = "대상 보르티곤트는 이미 족쇄가 채워져 있습니다.",
    interactionHeal = "치료하기",
    interactionHealDesc = "의료 도구를 사용하여 대상을 치료합니다.",
    interactionRevive = "소생시키기",
    interactionReviveDesc = "의료 도구를 사용하여 대상을 소생시킵니다."
})

local function GetTargetName(viewer, target)
    local targetPlayer = IsValid(target) and (target:IsPlayer() and target or target:GetNetVar("player"))
    local targetCharacter = IsValid(targetPlayer) and targetPlayer:GetCharacter()

    if not (targetCharacter and IsValid(viewer) and viewer.GetCharacter) then
        return IsValid(targetPlayer) and targetPlayer:Name() or (IsValid(target) and target:GetNetVar("ixPlayerName") or "Unknown")
    end

    local viewerCharacter = viewer:GetCharacter()

    if (viewerCharacter and viewerCharacter.DoesRecognize and viewerCharacter:DoesRecognize(targetCharacter)) then
        return targetCharacter:GetName()
    end

    local customName = hook.Run("GetCharacterName", target)

    if (isstring(customName) and customName != "") then
        return customName
    end

    return targetCharacter:GetName()
end

local function IsValidTarget(client, target)
    if not (IsValid(client) and client:IsPlayer()) then
        return false, "interactionMenuInvalidPlayer"
    end

    if not (IsValid(target) and (target:IsPlayer() or (target:GetClass() == "prop_ragdoll" and target:GetNetVar("player")))) then
        return false, "interactionMenuNeedValidTarget"
    end

    if (client == target) then
        return false, "interactionMenuSelfTarget"
    end

    local targetPlayer = target:IsPlayer() and target or target:GetNetVar("player")
    if not (client:GetCharacter() and IsValid(targetPlayer) and targetPlayer:GetCharacter()) then
        return false, "interactionMenuMissingCharacter"
    end

    return true
end

local function IsTargetInRange(client, target, maxDistance)
    local distance = maxDistance or PLUGIN.interactionRange

    if not (IsValid(client) and IsValid(target)) then
        return false
    end

    return client:GetPos():DistToSqr(target:GetPos()) <= (distance * distance)
end

local function IsTargetVisible(client, target)
    if not (IsValid(client) and IsValid(target)) then
        return false
    end

    local trace = util.TraceLine({
        start = client:EyePos(),
        endpos = target:EyePos(),
        filter = {client, target},
        mask = MASK_SOLID_BRUSHONLY
    })

    return not trace.Hit
end

local function CanInteractWithTarget(client, target)
    local isValid, reason = IsValidTarget(client, target)

    if not isValid then
        return false, reason
    end

    if not IsTargetInRange(client, target) then
        return false, "interactionMenuTooFar"
    end

    if not IsTargetVisible(client, target) then
        return false, "interactionMenuNoSight"
    end

    return true
end

function PLUGIN:GetInteractionTarget(client)
    if not IsValid(client) then
        return NULL
    end

    local trace = client:GetEyeTraceNoCursor()
    local target = trace.Entity

    if not (IsValid(target) and (target:IsPlayer() or (target:GetClass() == "prop_ragdoll" and target:GetNetVar("player")))) then
        return NULL
    end

    if not IsTargetInRange(client, target) then
        return NULL
    end

    return target
end

function PLUGIN:CanUseInteraction(client, target, interaction)
    local ok, reason = CanInteractWithTarget(client, target)

    if not ok then
        return false, reason
    end

    if not istable(interaction) then
        return false, "interactionMenuInvalidInteraction"
    end

    if (client.ixNextPlayerInteraction or 0) > CurTime() then
        return false, "interactionMenuCooldown"
    end

    if (client:IsRestricted() and not interaction.allowRestrictedClient) then
        return false, "interactionMenuRestrained"
    end

    if (interaction.shouldShow) then
        local visible, visibleReason = interaction.shouldShow(client, target)

        if (visible == false) then
            return false, visibleReason
        end
    end

    if (interaction.check) then
        local legacyOk, legacyReason = interaction.check(client, target)

        if (legacyOk == false or legacyOk == nil) then
            return false, legacyReason
        end
    end

    if (interaction.canRun) then
        local canRun, blockedReason = interaction.canRun(client, target)

        if (canRun == false) then
            return false, blockedReason
        end
    end

    return true
end

function PLUGIN:GetSortedInteractions(client, target)
    local available = {}

    for uniqueID, interaction in pairs(self.interactions) do
        local ok = self:CanUseInteraction(client, target, interaction)

        if (ok) then
            available[#available + 1] = {
                uniqueID = uniqueID,
                data = interaction
            }
        end
    end

    table.sort(available, function(a, b)
        local orderA = a.data.order or 100
        local orderB = b.data.order or 100

        if (orderA == orderB) then
            return (a.data.name or a.uniqueID) < (b.data.name or b.uniqueID)
        end

        return orderA < orderB
    end)

    return available
end

function PLUGIN:RegisterInteraction(uniqueID, data)
    self.interactions = self.interactions or {}
    self.interactions[uniqueID] = data
end

function PLUGIN:RegisterExternalInteractions()
    local vortPlugin = ix.plugin.Get("vortigaunt_stuff")

    if (
        vortPlugin
        and vortPlugin.CanManageSlaveVortigaunt
        and vortPlugin.IsEnslavedVortigaunt
        and vortPlugin.StartVortigauntLiberation
        and vortPlugin.StartVortigauntReshackle
    ) then
        self:RegisterInteraction("free_vort_shackles", {
            order = 40,
            name = "interactionVortFree",
            description = "interactionVortFreeDesc",
            shouldShow = function(client, target)
                local targetCharacter = IsValid(target) and target:GetCharacter()

                return targetCharacter
                    and targetCharacter.IsVortigaunt
                    and targetCharacter:IsVortigaunt()
                    and vortPlugin:IsEnslavedVortigaunt(targetCharacter)
                    and vortPlugin:CanManageSlaveVortigaunt(client, target)
            end,
            canRun = function(client, target)
                local targetCharacter = IsValid(target) and target:GetCharacter()

                if not (targetCharacter and targetCharacter.IsVortigaunt and targetCharacter:IsVortigaunt()) then
                    return false, "vortTargetNotVort"
                end

                if not vortPlugin:IsEnslavedVortigaunt(targetCharacter) then
                    return false, "interactionVortAlreadyFree"
                end

                if (target:GetNetVar("vortShackleRemoving")) then
                    return false, "interactionMenuCooldown"
                end

                if not vortPlugin:CanManageSlaveVortigaunt(client, target) then
                    return false, "vortShackleDenied"
                end

                return true
            end,
            onRun = function(client, target)
                vortPlugin:StartVortigauntLiberation(client, target)
            end
        })

        self:RegisterInteraction("enslave_vort_shackles", {
            order = 50,
            name = "interactionVortShackle",
            description = "interactionVortShackleDesc",
            shouldShow = function(client, target)
                local targetCharacter = IsValid(target) and target:GetCharacter()

                return targetCharacter
                    and targetCharacter.IsVortigaunt
                    and targetCharacter:IsVortigaunt()
                    and not vortPlugin:IsEnslavedVortigaunt(targetCharacter)
                    and vortPlugin:CanManageSlaveVortigaunt(client, target)
            end,
            canRun = function(client, target)
                local targetCharacter = IsValid(target) and target:GetCharacter()

                if not (targetCharacter and targetCharacter.IsVortigaunt and targetCharacter:IsVortigaunt()) then
                    return false, "vortTargetNotVort"
                end

                if (target:GetNetVar("vortShackleRemoving")) then
                    return false, "interactionMenuCooldown"
                end

                if not vortPlugin:CanManageSlaveVortigaunt(client, target) then
                    return false, "vortShackleDenied"
                end

                if (vortPlugin:IsEnslavedVortigaunt(targetCharacter)) then
                    return false, "interactionVortAlreadyShackled"
                end

                return true
            end,
            onRun = function(client, target)
                vortPlugin:StartVortigauntReshackle(client, target)
            end
        })
    end
end

PLUGIN.interactions = PLUGIN.interactions or {}

PLUGIN:RegisterInteraction("search", {
    order = 10,
    name = "interactionSearch",
    description = "interactionSearchDesc",
    shouldShow = function(client, target)
        if not target:IsRestricted() then
            return false
        end

        return true
    end,
    canRun = function(client, target)
        if not target:IsRestricted() then
            return false, "interactionMenuTargetUntied"
        end

        return true
    end,
    onRun = function(client, target)
        Schema:SearchPlayer(client, target)
        client:EmitSound("physics/cardboard/cardboard_box_impact_soft2.wav", 55, 115)
    end
})

PLUGIN:RegisterInteraction("untie", {
    order = 20,
    name = "interactionUntie",
    description = "interactionUntieDesc",
    shouldShow = function(client, target)
        if not target:IsRestricted() then
            return false
        end

        return true
    end,
    canRun = function(client, target)
        if not target:IsRestricted() then
            return false, "interactionMenuTargetUntied"
        end

        if (target:GetNetVar("untying")) then
            return false, "interactionMenuAlreadyUntying"
        end

        return true
    end,
    onRun = function(client, target)
        local duration = PLUGIN.untieDuration

        target:SetAction("@beingUntied", duration)
        target:SetNetVar("untying", true)
        client:SetAction("@unTying", duration)

        client:DoStaredAction(target, function()
            if not (IsValid(client) and IsValid(target)) then
                return
            end

            if (target:IsRestricted()) then
                target:SetRestricted(false)
            end

            target:SetNetVar("untying", nil)
            target:SetAction()
            client:SetAction()

            client:NotifyLocalized("interactionMenuUntiedTarget", GetTargetName(client, target))
            target:NotifyLocalized("interactionMenuUntiedYou", GetTargetName(target, client))
        end, duration, function()
            if (IsValid(target)) then
                target:SetNetVar("untying", nil)
                target:SetAction()
            end

            if (IsValid(client)) then
                client:SetAction()
                client:NotifyLocalized("interactionMenuUntieCancelled")
            end
        end, PLUGIN.interactionRange)
    end
})

--[[
PLUGIN:RegisterInteraction("recognise", {
    order = 30,
    name = "interactionRecognize",
    description = "interactionRecognizeDesc",
    canRun = function(client, target)
        local clientCharacter = client:GetCharacter()
        local targetCharacter = target:GetCharacter()

        if (clientCharacter:DoesRecognize(targetCharacter)) then
            return false, "interactionMenuRecognizedAlready"
        end

        return true
    end,
    onRun = function(client, target)
        local clientCharacter = client:GetCharacter()
        local targetCharacter = target:GetCharacter()

        if (clientCharacter:Recognize(targetCharacter)) then
            client:NotifyLocalized("interactionMenuRecognizedTarget", targetCharacter:GetName())
            hook.Run("CharacterRecognized", client, targetCharacter:GetID())
        else
            client:NotifyLocalized("interactionMenuRecognizedTargetAlready", targetCharacter:GetName())
        end
    end
})
--]]

PLUGIN:RegisterInteraction("heal", {
    order = 32,
    name = "interactionHeal",
    description = "interactionHealDesc",
    shouldShow = function(client, target)
        return target:IsPlayer() and target:Alive() and ix.plugin.Get("easymedikit")
    end,
    canRun = function(client, target)
        local character = client:GetCharacter()
        local inventory = character:GetInventory()
        local healItem

        for _, item in pairs(inventory:GetItems()) do
            if (item.functions and item.functions.heal) then
                healItem = item
                break
            end
        end

        if not healItem then
            return false, "noHealItem"
        end

        return true
    end,
    onRun = function(client, target)
        local character = client:GetCharacter()
        local inventory = character:GetInventory()
        local healItem

        for _, item in pairs(inventory:GetItems()) do
            if (item.functions and item.functions.heal) then
                healItem = item
                break
            end
        end

        if (healItem) then
            healItem.player = client
            healItem.functions.heal.OnRun(healItem)
        end
    end
})

PLUGIN:RegisterInteraction("revive", {
    order = 35,
    name = "interactionRevive",
    description = "interactionReviveDesc",
    shouldShow = function(client, target)
        local corpsePlugin = ix.plugin.Get("persistent_corpses")
        return target:GetClass() == "prop_ragdoll" and target:GetNetVar("player") and corpsePlugin
    end,
    canRun = function(client, target)
        local corpsePlugin = ix.plugin.Get("persistent_corpses")
        if not corpsePlugin then return false end

        local character = client:GetCharacter()
        local inventory = character:GetInventory()
        local reviveItem

        if (corpsePlugin.GetReviveItem) then
            reviveItem = corpsePlugin:GetReviveItem(inventory)
        else
            reviveItem = inventory:HasItem("health_kit") or inventory:HasItem("health_vial") or inventory:HasItem("aed")
        end

        if not reviveItem then
            return false, "noHealItem"
        end

        return true
    end,
    onRun = function(client, target)
        local corpsePlugin = ix.plugin.Get("persistent_corpses")
        if (corpsePlugin) then
            corpsePlugin:StartCorpseRevive(client, target)
        end
    end
})

function PLUGIN:InitializedPlugins()
    self:RegisterExternalInteractions()
end

if (CLIENT) then
    ix.gui.interactionMenu = ix.gui.interactionMenu or nil

    local function CanOpenInteractionMenu(client)
        if not IsValid(client) then
            return false
        end

        if (gui.IsGameUIVisible() or vgui.CursorVisible()) then
            return false
        end

        if (client:GetViewEntity() != client) then
            return false
        end

        return true
    end

    local PANEL = {}

    function PANEL:Init()
        self:SetSize(math.min(ScrW() * 0.34, 560), math.min(ScrH() * 0.56, 520))
        self:Center()
        self:MakePopup()
        self:SetTitle(L("interactionMenuTitle"))
        self:SetDraggable(false)
        self:ShowCloseButton(true)
        self:SetBackgroundBlur(true)

        self.target = NULL

        self.header = self:Add("DPanel")
        self.header:Dock(TOP)
        self.header:SetTall(108)
        self.header:DockMargin(0, 0, 0, 8)
        self.header.Paint = function(panel, width, height)
            surface.SetDrawColor(20, 20, 20, 220)
            surface.DrawRect(0, 0, width, height)
            surface.SetDrawColor(ix.config.Get("color", Color(200, 30, 30)))
            surface.DrawRect(0, height - 2, width, 2)
        end

        self.titleLabel = self.header:Add("DLabel")
        self.titleLabel:Dock(TOP)
        self.titleLabel:DockMargin(14, 12, 14, 2)
        self.titleLabel:SetFont("ixMediumFont")
        self.titleLabel:SetTextColor(color_white)
        self.titleLabel:SetWrap(true)
        self.titleLabel:SetAutoStretchVertical(true)
        self.titleLabel:SetText(L("interactionMenuNoTarget"))

        self.descriptionLabel = self.header:Add("DLabel")
        self.descriptionLabel:Dock(FILL)
        self.descriptionLabel:DockMargin(14, 2, 14, 10)
        self.descriptionLabel:SetFont("ixSmallFont")
        self.descriptionLabel:SetTextColor(Color(210, 210, 210))
        self.descriptionLabel:SetWrap(true)
        self.descriptionLabel:SetAutoStretchVertical(true)
        self.descriptionLabel:SetText(L("interactionMenuHint"))

        self.list = self:Add("DScrollPanel")
        self.list:Dock(FILL)
        self.list:SetDrawBackground(false)
        self.list:DockMargin(10, 0, 10, 10)

        local vbar = self.list:GetVBar()
        vbar:SetWide(4)
    end

    function PANEL:ClearButtons()
        self.list:Clear()
    end

    function PANEL:SetTarget(target)
        self.target = target
        self:Refresh()
    end

    function PANEL:Refresh()
        self:ClearButtons()

        if not (IsValid(self.target) and self.target:IsPlayer() and self.target:GetCharacter()) then
            self.titleLabel:SetText(L("interactionMenuNoTarget"))
            self.descriptionLabel:SetText(L("interactionMenuHint"))
            self:InvalidateLayout(true)
            return
        end

        local client = LocalPlayer()
        local targetCharacter = self.target:GetCharacter()
        local interactions = PLUGIN:GetSortedInteractions(client, self.target)

        self.titleLabel:SetText(GetTargetName(client, self.target))

        local description = targetCharacter:GetDescription() or ""
        description = string.Trim(description)

        if (description == "") then
            description = L("interactionMenuNoDescription")
        elseif (#description > 96) then
            description = string.sub(description, 1, 93) .. "..."
        end

        self.descriptionLabel:SetText(description)

        if (#interactions == 0) then
            local empty = self.list:Add("DLabel")
            empty:Dock(TOP)
            empty:DockMargin(6, 8, 6, 0)
            empty:SetFont("ixSmallFont")
            empty:SetTextColor(Color(180, 180, 180))
            empty:SetText(L("interactionMenuEmpty"))
            empty:SetWrap(true)
            empty:SetAutoStretchVertical(true)
            return
        end

        for _, entry in ipairs(interactions) do
            local interactionID = entry.uniqueID
            local interaction = entry.data
            local button = self.list:Add("ixMenuButton")

            button:Dock(TOP)
            button:DockMargin(0, 0, 0, 6)
            button:SetTall(34)
            button:SetFont("ixMenuButtonFontSmall")
            local name = interaction.name and L(interaction.name) or interactionID
            local description = interaction.description and L(interaction.description) or ""

            button:SetText(name)
            button:SetToolTip(description)
            button.DoClick = function()
                if not IsValid(self.target) then
                    self:Close()
                    return
                end

                net.Start("ixInteraction")
                    net.WriteString(interactionID)
                    net.WriteEntity(self.target)
                net.SendToServer()

                self:Close()
            end
        end
    end

    function PANEL:Think()
        local client = LocalPlayer()

        if not IsValid(client) then
            self:Close()
            return
        end

        if not IsValid(self.target) or not IsTargetInRange(client, self.target) then
            self:Close()
            return
        end
    end

    function PANEL:OnClose()
        if (ix.gui.interactionMenu == self) then
            ix.gui.interactionMenu = nil
        end
    end

    vgui.Register("ixInteractionMenu", PANEL, "DFrame")

    function PLUGIN:OpenInteractionMenu(target)
        local client = LocalPlayer()

        if not CanOpenInteractionMenu(client) then
            return
        end

        if (client.ixNextInteractionMenuOpen or 0) > RealTime() then
            return
        end

        target = IsValid(target) and target or self:GetInteractionTarget(client)

        if not IsValid(target) then
            client:NotifyLocalized("interactionMenuOpenHint")
            return
        end

        local ok, reason = CanInteractWithTarget(client, target)

        if not ok then
            client:NotifyLocalized(reason or "interactionMenuInvalidInteraction")
            return
        end

        if IsValid(ix.gui.interactionMenu) then
            ix.gui.interactionMenu:SetTarget(target)
            ix.gui.interactionMenu:MakePopup()
        else
            ix.gui.interactionMenu = vgui.Create("ixInteractionMenu")
            ix.gui.interactionMenu:SetTarget(target)
        end

        client.ixNextInteractionMenuOpen = RealTime() + self.menuCooldown
    end

    function PLUGIN:PlayerButtonDown(client, button)
        if (client != LocalPlayer() or button != KEY_F4) then
            return
        end

        self:OpenInteractionMenu()
    end

    function PLUGIN:PopulateScoreboardPlayerMenu(target, menu)
        if not (IsValid(target) and target:IsPlayer()) then
            return
        end

        menu:AddOption(L("interactionScoreboard"), function()
            self:OpenInteractionMenu(target)
        end)
    end
else
    util.AddNetworkString("ixInteraction")

    net.Receive("ixInteraction", function(_, client)
        local interactionID = net.ReadString()
        local target = net.ReadEntity()
        local interaction = PLUGIN.interactions[interactionID]

        if not interaction then
            client:NotifyLocalized("interactionMenuMissingInteraction")
            return
        end

        local ok, reason = PLUGIN:CanUseInteraction(client, target, interaction)

        if not ok then
            if (isstring(reason) and reason != "") then
                client:NotifyLocalized(reason)
            end

            return
        end

        client.ixNextPlayerInteraction = CurTime() + PLUGIN.useCooldown

        if (interaction.onRun) then
            interaction.onRun(client, target)
        elseif (interaction.action) then
            interaction.action(client, target)
        end
    end)
end
