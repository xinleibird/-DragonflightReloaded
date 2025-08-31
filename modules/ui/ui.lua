DFRL:NewDefaults("Ui", {
    enabled = {true},
    questLog = {false, "checkbox", nil, nil, "appearance", 1, "Enable dark mode for the questlog", nil, nil},
    gameMenu = {false, "checkbox", nil, nil, "appearance", 2, "Enable dark mode for the game menu", "Only for Blizzards version", nil},
    characterPanel = {false, "checkbox", nil, nil, "appearance", 3, "Enable dark mode for the character panel", nil, nil},
    hideErrorMessage = {false, "checkbox", nil, nil, "ui tweaks", 4, "Hide the top UI error message (e.g. 'Spell is not ready')", nil, nil},
    lowHpWarn = {true, "checkbox", nil, nil, "ui tweaks", 5, "Show red border when health is low", nil, nil},
    lowHpThreshold = {70, "slider", {5, 95}, nil, "ui tweaks", 6, "Health threshold for low HP warning", nil, nil},
    cameraDistanceFactor = {3, "slider", {1, 5}, nil, "ui tweaks", 7, "Extended maximum camera distance", nil, nil},
    showPlates = {false, "checkbox", nil, nil, "ui tweaks", 8, "Show nameplates only in combat", nil, nil},
})

DFRL:NewMod("Ui", 5, function()
    -- locals
    local UnitHealth = UnitHealth
    local UnitHealthMax = UnitHealthMax
    local GetTime = GetTime
    local sin = math.sin

    -- hide stuff
    do
        PetPaperDollCloseButton:Hide()
        SkillFrameCancelButton:Hide()
    end

    -- close button
    do
        local closeButtonData = {
            {"CharacterFrame", "CharacterFrameCloseButton", -36, -16},
            {"SpellBookFrame", "SpellBookCloseButton", -36, -15},
            {"TalentFrame", "TalentFrameCloseButton", -36, -17},
            {"QuestLogFrame", "QuestLogFrameCloseButton", -91, -15},
            {"FriendsFrame", "FriendsFrameCloseButton", -36, -15},
            {"ShopFrame", "ShopFrameFrameCloseButton", -9, -17},
            {"HelpFrame", "HelpFrameCloseButton", -50, -10},
            {"QuestFrame", "QuestFrameCloseButton", -34, -22},
            {"GuildMemberDetailFrame", "GuildMemberDetailCloseButton", -10, -10},

        }

        FriendsFrameCloseButton:SetFrameLevel(100) -- for some reason this button is always behind the other frames
        FriendsFrameCloseButton:Show()

        for i = 1, 5 do
            table.insert(closeButtonData, {"ContainerFrame"..i, "ContainerFrame"..i.."CloseButton", -8, -8})
        end

        local path = "Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\close_normal.tga"
        local pathpushed = "Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\close_pushed.tga"

        for _, data in ipairs(closeButtonData) do
            local frameName, buttonName, offsetX, offsetY = unpack(data)
            local frame = _G[frameName]
            local button = _G[buttonName]

            if button then
                button:SetNormalTexture(path)
                button:SetPushedTexture(pathpushed)
                button:SetHighlightTexture(path)
                button:SetWidth(17)
                button:SetHeight(17)
                button:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', offsetX, offsetY)
            end
        end
    end

    -- questlog
    do
        local questLogFrame = QuestLogFrame
        if questLogFrame then
            local regions = {questLogFrame:GetRegions()}
            for i, region in ipairs(regions) do
                if region:GetObjectType() == "Texture" then
                    local texture = region:GetTexture()
                    if texture then
                        if texture == "Interface\\QuestFrame\\UI-QuestLog-Left" then
                            region:SetTexture("Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\questlog_left.tga")
                        elseif texture == "Interface\\QuestFrame\\UI-QuestLog-Right" then
                            region:SetTexture("Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\questlog_right.tga")
                        end
                    end
                end
            end
        end
    end

    -- characterframe
    do
        local tex = {
            "Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\paperdoll_top_left.tga",
            "Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\paperdoll_top_right.tga",
            "Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\paperdoll_bot_left.tga",
            "Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\paperdoll_bot_right.tga",
        }

        local function ReplaceFrameTextures(frame)
            if not frame then return end
            frame:SetFrameStrata("MEDIUM")

            local regions = { frame:GetRegions() }
            local texIndex = 1
            for i = 1, table.getn(regions) do
                local r = regions[i]
                if r and r:IsObjectType("Texture") then
                    local name = r:GetName()
                    if not name or not string.find(name, "Portrait") then
                        r:ClearAllPoints()
                        if texIndex == 1 then
                            r:SetPoint("TOPLEFT", 0, 0)
                        elseif texIndex == 2 then
                            r:SetPoint("TOPLEFT", 256, 0)
                        elseif texIndex == 3 then
                            r:SetPoint("TOPLEFT", 0, -256)
                        elseif texIndex == 4 then
                            r:SetPoint("TOPLEFT", 256, -256)
                        end
                        r:SetTexture(tex[texIndex])
                        texIndex = texIndex + 1
                        if texIndex > table.getn(tex) then break end
                    end
                end
            end
        end

        HookScript(CharacterFrame, "OnShow", function()
            ReplaceFrameTextures(CharacterFrame)
        end)

        local subFrames = {
            "PaperDollFrame",
            "PetPaperDollFrame",
            "ReputationFrame",
            "SkillFrame",
            "HonorFrame",

        }

        for i = 1, table.getn(subFrames) do
            local f = getglobal(subFrames[i])
            if f then
                HookScript(f, "OnShow", function()
                    ReplaceFrameTextures(f)
                end)
            end
        end
    end

    -- friendsframe
    do
        local function ApplyCustomTextures(frame)
            if not frame then return end

            if not frame.customTopLeft then
                frame.customTopLeft = frame:CreateTexture(nil, "OVERLAY")
                frame.customTopLeft:SetTexture("Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\paperdoll_top_left.tga")
                frame.customTopLeft:SetWidth(256)
                frame.customTopLeft:SetHeight(256)
                frame.customTopLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", -3, 0)

                frame.customTopRight = frame:CreateTexture(nil, "OVERLAY")
                frame.customTopRight:SetTexture("Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\paperdoll_top_right.tga")
                frame.customTopRight:SetWidth(128)
                frame.customTopRight:SetHeight(256)
                frame.customTopRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, 0)

                frame.customBottomLeft = frame:CreateTexture(nil, "OVERLAY")
                frame.customBottomLeft:SetTexture("Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\paperdoll_bot_left.tga")
                frame.customBottomLeft:SetWidth(256)
                frame.customBottomLeft:SetHeight(256)
                frame.customBottomLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", -3, -256)

                frame.customBottomRight = frame:CreateTexture(nil, "OVERLAY")
                frame.customBottomRight:SetTexture("Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\paperdoll_bot_right.tga")
                frame.customBottomRight:SetWidth(128)
                frame.customBottomRight:SetHeight(256)
                frame.customBottomRight:SetPoint("TOPLEFT", frame, "TOPLEFT", 253, -256)
            end
        end

        WhoFrameTotals:SetDrawLayer("OVERLAY", 10)
        GuildFrameNotesText:SetDrawLayer("OVERLAY", 10)
        GuildFrameTotals:SetDrawLayer("OVERLAY", 10)
        GuildFrameOnlineTotals:SetDrawLayer("OVERLAY", 10)

        local function ReplaceCharacterTextures()
            ApplyCustomTextures(FriendsFrame)
            ApplyCustomTextures(WhoFrame)
            ApplyCustomTextures(GuildFrame)
        end

        if FriendsFrame then
            HookScript(FriendsFrame, "OnShow", ReplaceCharacterTextures)
        end

        ReplaceCharacterTextures()
    end

    -- spellbookframe
    do
        local function ApplyCustomTextures(frame)
            if not frame then return end

            if not frame.customTopLeft then
                frame.customTopLeft = frame:CreateTexture(nil, "OVERLAY")
                frame.customTopLeft:SetTexture("Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\paperdoll_top_left.tga")
                frame.customTopLeft:SetWidth(256)
                frame.customTopLeft:SetHeight(256)
                frame.customTopLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", -3, 0)

                frame.customTopRight = frame:CreateTexture(nil, "OVERLAY")
                frame.customTopRight:SetTexture("Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\paperdoll_top_right.tga")
                frame.customTopRight:SetWidth(128)
                frame.customTopRight:SetHeight(256)
                frame.customTopRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, 0)

                frame.customBottomLeft = frame:CreateTexture(nil, "OVERLAY")
                frame.customBottomLeft:SetTexture("Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\paperdoll_bot_left.tga")
                frame.customBottomLeft:SetWidth(256)
                frame.customBottomLeft:SetHeight(256)
                frame.customBottomLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", -3, -256)

                frame.customBottomRight = frame:CreateTexture(nil, "OVERLAY")
                frame.customBottomRight:SetTexture("Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\paperdoll_bot_right.tga")
                frame.customBottomRight:SetWidth(128)
                frame.customBottomRight:SetHeight(256)
                frame.customBottomRight:SetPoint("TOPLEFT", frame, "TOPLEFT", 253, -256)

                for i = 1, 12 do
                    local button = _G["SpellButton" .. i]
                    if button then
                        local bg = _G["SpellButton" .. i .. "Background"]
                        if bg then
                            bg:SetTexture("Interface\\AddOns\\-DragonflightReloaded\\media\\tex\\ui\\spell_bg.tga")
                            bg:SetWidth(44)
                            bg:SetHeight(44)
                        end
                        _G["SpellButton" .. i.."SubSpellName"]:SetTextColor(0.9, 0.9, 0.8,0.6);
                    end
                end
            end
        end

        if SpellBookFrame then
            HookScript(SpellBookFrame, "OnShow", function()
                ApplyCustomTextures(SpellBookFrame)
            end)
        end

        ApplyCustomTextures(SpellBookFrame)
    end

    -- optionsframe
    do
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:SetScript("OnEvent", function ()
            UIOptionsFrame:SetParent(UIParent)
            UIOptionsFrame:SetWidth(1024)
            UIOptionsFrame:SetHeight(700)
            UIOptionsFrame:SetFrameStrata("DIALOG")
            UIOptionsFrame:ClearAllPoints()
            UIOptionsFrame:SetPoint("CENTER", 0, 0)
            UIOptionsFrameTab1:SetFrameLevel(10)
            UIOptionsFrameTab2:SetFrameLevel(10)
            UIOptionsFrameDefaults:SetFrameLevel(10)
            UIOptionsFrameCancel:SetFrameLevel(10)
            UIOptionsFrameOkay:SetFrameLevel(10)
            UIOptionsFrame:SetHitRectInsets(0,0,0,50)
        end)

    end

    -- timer frame
    do
        local originalManageFramePositions = _G.UIParent_ManageFramePositions
        _G.UIParent_ManageFramePositions = function()
            originalManageFramePositions()

            if DFRL_FRAMEPOS and DFRL_FRAMEPOS['QuestTimerFrame'] then
                local pos = DFRL_FRAMEPOS['QuestTimerFrame']
                QuestTimerFrame:ClearAllPoints()
                QuestTimerFrame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', pos.x, pos.y)
            else
                QuestTimerFrame:ClearAllPoints()
                QuestTimerFrame:SetPoint('TOPRIGHT', Minimap, 'BOTTOMLEFT', -20, 40)
            end
        end

        -- QuestTimerFrame:UnregisterAllEvents()
        -- QuestTimerFrame:SetScript('OnUpdate', nil)
        QuestTimerFrame:Show()
        -- debugframe(QuestTimerFrame)
    end

    -- callbacks
    local callbacks = {}

    callbacks.questLog = function(value)
        local r, g, b, a
        if value then
            r, g, b, a = 0.4, 0.4, 0.4, 1
        else
            r, g, b, a = 1, 1, 1, 1
        end

        local function IsBlacklisted(texture)
            local name = texture:GetName()
            local tex = texture:GetTexture()
            if not tex then return true end

            if name then
                if string.find(name, "Button") or string.find(name, "Icon") or string.find(name, "Portrait") then
                return true
                end
            end

            if string.find(tex, "Button") or string.find(tex, "Icon") or string.find(tex, "Portrait") or string.find(tex, "StationeryTest") then
                return true
            end

            return nil
        end

        local function AddBackground(frame)
            if not frame.Material then
                local tex = frame:CreateTexture(nil, "OVERLAY")
                tex:SetTexture("Interface\\Stationery\\StationeryTest1")
                tex:SetWidth(frame:GetWidth())
                tex:SetHeight(frame:GetHeight())
                tex:SetPoint("TOPLEFT", frame, 0, 0)
                tex:SetVertexColor(.8, .8, .8)
                frame.Material = tex
            end
            frame.Material:Show()
        end

        local function Darken(frame)
            if frame and frame.GetRegions then
                local name = frame.GetName and frame:GetName()

                if value and name and string.find(name, "^QuestLogDetailScrollFrame$") then
                AddBackground(frame)
                elseif frame.Material then
                frame.Material:Hide()
                end

                for _, region in pairs({frame:GetRegions()}) do
                if region and region.GetObjectType and region:GetObjectType() == "Texture" and region.SetVertexColor then
                    if not IsBlacklisted(region) then
                    region:SetVertexColor(r, g, b, a)
                    end
                end
                end
            end
        end

        Darken(QuestLogFrame)
        Darken(QuestLogDetailScrollFrame)
        Darken(QuestFrame)

        for _, name in pairs({"QuestFrameGreetingPanel", "QuestFrameProgressPanel", "QuestFrameRewardPanel", "QuestFrameDetailPanel"}) do
            Darken(_G[name])
        end
    end

    callbacks.gameMenu = function(value)
        local darkColor = {0.2, 0.2, 0.2}
        local lightColor = {1, 1, 1}
        local color = value and darkColor or lightColor

        local function ShouldExclude(frame)
            if not frame or not frame.GetName then return false end

            local name = frame:GetName()
            if not name then return false end

            return string.find(name, "MacroButton") or string.find(name, "CheckButton") or string.find(name, "Slider")
        end

        local function DarkenFrame(frame)
            if not frame then return end

            if ShouldExclude(frame) then return end

            if frame.SetBackdropColor then
                frame:SetBackdropColor(color[1], color[2], color[3], 1)
            end
            if frame.SetBackdropBorderColor then
                frame:SetBackdropBorderColor(color[1], color[2], color[3], 1)
            end

            local regions = {frame:GetRegions()}
            for i = 1, table.getn(regions) do
                local region = regions[i]
                if region:GetObjectType() == "Texture" then
                    local parent = region:GetParent()
                    if parent and not ShouldExclude(parent) then
                        region:SetVertexColor(color[1], color[2], color[3])
                    end
                end
            end

            local children = {frame:GetChildren()}
            for i = 1, table.getn(children) do
                local child = children[i]
                DarkenFrame(child)
            end
        end

        if GameMenuFrame then
            DarkenFrame(GameMenuFrame)
        end
    end

    callbacks.characterPanel = function(value)
        local darkColor = {0.4, 0.4, 0.4, 1}
        local lightColor = {1, 1, 1, 1}
        local color = value and darkColor or lightColor

        local function IsBlacklisted(texture)
            local name = texture:GetName()
            local tex = texture:GetTexture()
            if not tex then return true end

            if name then
                if string.find(name, "Icon") or string.find(name, "Portrait") or string.find(name, "Check") then
                    return true
                end
            end

            if string.find(tex, "Icon") or string.find(tex, "Portrait")  or string.find(tex, "Check") then
                return true
            end

            return nil
        end

        local function Darken(frame)
            if not frame or not frame.GetRegions then return end

            for _, region in pairs({frame:GetRegions()}) do
                if region and region.GetObjectType and region:GetObjectType() == "Texture" and region.SetVertexColor then
                    if not IsBlacklisted(region) then
                        region:SetVertexColor(unpack(color))
                    end
                end
            end

            local children = {frame:GetChildren()}
            for _, child in pairs(children) do
                if child and child:GetName() and not string.find(child:GetName(), "CharacterFrameCloseButton") then
                    Darken(child)
                end
            end
        end

        Darken(CharacterFrame)

        local subFrames = {
            "PaperDollFrame",
            "PetPaperDollFrame",
            "ReputationFrame",
            "SkillFrame",
            "HonorFrame"
        }

        for _, frameName in pairs(subFrames) do
            local frame = _G[frameName]
            if frame then
                Darken(frame)
            end
        end
    end

    callbacks.hideErrorMessage = function (value)
        if value then
            UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
        else
            UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
        end
    end

    callbacks.lowHpWarn = function(value)
        if not DFRL.lowHpWarnFrame then
            local frame = CreateFrame("Frame", "DFRL_LowHpWarnFrame", UIParent)
            frame:SetFrameStrata("BACKGROUND")
            frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
            frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
            frame:Hide()

            local top = frame:CreateTexture(nil, "BACKGROUND")
            top:SetTexture("Interface\\Buttons\\WHITE8X8")
            top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            top:SetHeight(64)
            top:SetGradientAlpha("VERTICAL", 1, 0, 0, 0, 1, 0, 0, 0.7)

            local bottom = frame:CreateTexture(nil, "BACKGROUND")
            bottom:SetTexture("Interface\\Buttons\\WHITE8X8")
            bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
            bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
            bottom:SetHeight(64)
            bottom:SetGradientAlpha("VERTICAL", 1, 0, 0, 0.7, 1, 0, 0, 0)

            local left = frame:CreateTexture(nil, "BACKGROUND")
            left:SetTexture("Interface\\Buttons\\WHITE8X8")
            left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
            left:SetWidth(64)
            left:SetGradientAlpha("HORIZONTAL", 1, 0, 0, 0.7, 1, 0, 0, 0)

            local right = frame:CreateTexture(nil, "BACKGROUND")
            right:SetTexture("Interface\\Buttons\\WHITE8X8")
            right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
            right:SetWidth(64)
            right:SetGradientAlpha("HORIZONTAL", 1, 0, 0, 0, 1, 0, 0, 0.7)

            -- store
            frame.textures = {top, bottom, left, right}
            frame.pulseTime = 0
            frame.baseAlpha = 0.1

            DFRL.lowHpWarnFrame = frame

            local healthCheckFrame = CreateFrame("Frame")
            local updateFunc = function()
                if (this.tick or 0) > GetTime() then
                    DFRL.activeScripts["LowHpWarnScript"] = false
                    return
                end
                this.tick = GetTime() + 0.01

                local healthPercent = UnitHealth("player") / UnitHealthMax("player") * 100

                local threshold = DFRL:GetTempDB("Ui", "lowHpThreshold")
                if healthPercent <= threshold then
                    DFRL.lowHpWarnFrame:Show()
                    DFRL.activeScripts["LowHpWarnScript"] = true

                    -- calculate alpha
                    -- at 45% hp: alpha = 0.1, at 0% hp: alpha = 1.0
                    local warningRange = threshold * 0.9  -- start fading at 90% of threshold
                    local alphaMultiplier = (warningRange - healthPercent) / warningRange
                    local baseAlpha = 0.1 + (0.9 * alphaMultiplier)

                    -- calculate pulse speed
                    -- lower health = faster pulsing
                    local pulseSpeed = 1 + (7 * alphaMultiplier)

                    -- update pulse time
                    DFRL.lowHpWarnFrame.pulseTime = DFRL.lowHpWarnFrame.pulseTime + (arg1 * pulseSpeed)

                    -- calculate pulse factor using sine wave
                    local pulseFactor = (sin(DFRL.lowHpWarnFrame.pulseTime) + 1) / 2 -- normalized to 0-1

                    -- apply pulsing to alpha
                    local finalAlpha = baseAlpha * (0.3 + 0.7 * pulseFactor) -- pulse between 30% and 100% of base alpha

                    -- update
                    for i = 1, 4 do
                        local texture = DFRL.lowHpWarnFrame.textures[i]
                        if i == 1 then
                            texture:SetGradientAlpha("VERTICAL", 1, 0, 0, 0, 1, 0, 0, 0.7 * finalAlpha)
                        elseif i == 2 then
                            texture:SetGradientAlpha("VERTICAL", 1, 0, 0, 0.7 * finalAlpha, 1, 0, 0, 0)
                        elseif i == 3 then
                            texture:SetGradientAlpha("HORIZONTAL", 1, 0, 0, 0.7 * finalAlpha, 1, 0, 0, 0)
                        else
                            texture:SetGradientAlpha("HORIZONTAL", 1, 0, 0, 0, 1, 0, 0, 0.7 * finalAlpha)
                        end
                    end
                else
                    DFRL.lowHpWarnFrame:Hide()
                    -- reset pulse time
                    DFRL.lowHpWarnFrame.pulseTime = 0
                    DFRL.activeScripts["LowHpWarnScript"] = false
                end
            end

            healthCheckFrame:SetScript("OnUpdate", updateFunc)
            healthCheckFrame.updateFunc = updateFunc

            DFRL.healthCheckFrame = healthCheckFrame
        end

        if value then
            DFRL.healthCheckFrame:SetScript("OnUpdate", DFRL.healthCheckFrame.updateFunc)
        else
            DFRL.lowHpWarnFrame:Hide()
            DFRL.healthCheckFrame:SetScript("OnUpdate", nil)
            DFRL.activeScripts["LowHpWarnScript"] = false
        end
    end

    callbacks.lowHpThreshold = function(value)
        if DFRL.lowHpWarnFrame and DFRL.lowHpWarnFrame:IsShown() then
            DFRL.healthCheckFrame.tick = 0
        end
    end

    callbacks.cameraDistanceFactor = function(value)
        SetCVar("CameraDistanceMaxFactor", value)
    end

    callbacks.showPlates = function(value)
        if not DFRL.nameplateFrame then
            local f = CreateFrame("Frame")
            f:SetScript("OnEvent", function()
                if event == "PLAYER_ENTERING_WORLD" then
                    this:UnregisterEvent("PLAYER_ENTERING_WORLD")
                    HideNameplates()
                elseif event == "PLAYER_REGEN_DISABLED" then
                    ShowNameplates()
                else
                    HideNameplates()
                end
            end)
            DFRL.nameplateFrame = f
        end

        if value then
            DFRL.nameplateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
            DFRL.nameplateFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
            DFRL.nameplateFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            HideNameplates()
        else
            DFRL.nameplateFrame:UnregisterAllEvents()
        end
    end

    DFRL.activeScripts["LowHpWarnScript"] = false

    -- execute  callbacks
    DFRL:NewCallbacks("Ui", callbacks)
end)
