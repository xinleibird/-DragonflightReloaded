setfenv(1, DFRL:GetEnv())

DFRL:NewDefaults("ComboPoints", {
    enabled  = {true, "checkbox", nil, nil, "General", 1,
                "Display combo points for rogue / druid cat form", nil, nil},
    size     = {20, "slider", {20, 32}, "enabled", "Layout", 2,
                "Width and height of each combo point pip", nil, nil},
    spacing  = {2,  "slider", {0, 8}, "enabled", "Layout", 3,
                "Pixel gap between pips", nil, nil},
    offsetX  = {0,  "slider", {-200, 200}, "enabled", "Layout", 4,
                "X offset from TargetFrame top center", nil, nil},
    offsetY  = {6,  "slider", {-200, 200}, "enabled", "Layout", 5,
                "Y offset from TargetFrame top edge (positive = above)", nil, nil},
    lowColor = {{1, 0.3, 0.3}, "colour", nil, "enabled", "Colors", 6,
                "Pip color for 1-2 combo points", nil, nil},
    midColor = {{1, 1,   0.3}, "colour", nil, "enabled", "Colors", 7,
                "Pip color for 3 combo points", nil, nil},
    highColor= {{0.3, 1, 0.3}, "colour", nil, "enabled", "Colors", 8,
                "Pip color for 4-5 combo points", nil, nil},
})

DFRL:NewMod("ComboPoints", 1, function()
    if MAX_COMBO_POINTS == nil then MAX_COMBO_POINTS = 5 end

    local _, class = UnitClass("player")
    if class ~= "ROGUE" and class ~= "DRUID" then return end

    local container = CreateFrame("Frame", "DFRL_ComboPoints", UIParent)
    container:SetFrameStrata("MEDIUM")
    container:EnableMouse(false)
    container:SetAlpha(0)
    container:Hide()

    local pips = {}
    local pipAlpha = {}
    for i = 1, MAX_COMBO_POINTS do
        local pip = CreateFrame("Frame", "DFRL_ComboPoints_Pip" .. i, container)
        pip:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        pip:SetBackdropColor(0.2, 0.2, 0.2, 0.4)
        pip:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        pip:SetAlpha(0.4)
        pips[i] = pip
        pipAlpha[i] = 0.4
    end

    local visible = false

    local function AnchorToTarget()
        if not TargetFrame then return end
        local ox = DFRL:GetTempDB("ComboPoints", "offsetX")
        local oy = DFRL:GetTempDB("ComboPoints", "offsetY")
        container:ClearAllPoints()
        container:SetPoint("BOTTOM", TargetFrame, "TOP", ox, oy)
    end

    local function PipColor(n)
        local key = (n <= 2) and "lowColor" or (n == 3) and "midColor" or "highColor"
        local c = DFRL:GetTempDB("ComboPoints", key)
        return c[1], c[2], c[3]
    end

    local function Relayout()
        AnchorToTarget()
        local size    = DFRL:GetTempDB("ComboPoints", "size")
        local spacing = DFRL:GetTempDB("ComboPoints", "spacing")
        for i = 1, MAX_COMBO_POINTS do
            pips[i]:SetWidth(size)
            pips[i]:SetHeight(size)
            pips[i]:ClearAllPoints()
            pips[i]:SetPoint("LEFT", container, "LEFT",
                             (i - 1) * (size + spacing), 0)
        end
        container:SetWidth(MAX_COMBO_POINTS * size + (MAX_COMBO_POINTS - 1) * spacing)
        container:SetHeight(size)
    end

    local function InComboForm()
        if class == "ROGUE" then return true end
        local form = GetShapeshiftForm and GetShapeshiftForm()
        return form == 1 or form == 2 or form == 3
    end

    local function PulsePip(pip)
        pip.pulseTime = 0
        pip:SetScale(0.5)
        pip:SetScript("OnUpdate", function()
            this.pulseTime = (this.pulseTime or 0) + arg1
            local t = this.pulseTime / 0.25
            if t >= 1 then
                this:SetScale(1)
                this:SetScript("OnUpdate", nil)
                return
            end
            local s
            if t < 0.4 then
                s = 0.5 + (1.15 - 0.5) * (t / 0.4)
            elseif t < 0.7 then
                s = 1.15 - (1.15 - 0.9) * ((t - 0.4) / 0.3)
            else
                s = 0.9 + (1.0 - 0.9) * ((t - 0.7) / 0.3)
            end
            this:SetScale(s)
        end)
    end

    local function ShowCombo()
        if visible then return end
        visible = true
        container:SetAlpha(0)
        container:Show()
        UIFrameFadeIn(container, 0.2, 0, 1)
    end

    local function HideCombo()
        if not visible then return end
        visible = false
        UIFrameFadeOut(container, 0.3, container:GetAlpha(), 0)
    end

    local function Update()
        if not DFRL:GetTempDB("ComboPoints", "enabled") or not InComboForm() then
            HideCombo()
            return
        end
        AnchorToTarget()
        local n = GetComboPoints() or 0
        if n > MAX_COMBO_POINTS then n = MAX_COMBO_POINTS end

        if n < 1 then
            HideCombo()
            return
        end

        ShowCombo()
        for i = 1, MAX_COMBO_POINTS do
            local r, g, b, targetAlpha
            if i <= n then
                r, g, b = PipColor(i)
                targetAlpha = 1
            else
                r, g, b = 0.2, 0.2, 0.2
                targetAlpha = 0.4
            end
            pips[i]:SetBackdropColor(r, g, b, targetAlpha)
            pips[i]:SetAlpha(targetAlpha)
            if targetAlpha > 0.5 and pipAlpha[i] <= 0.5 then
                PulsePip(pips[i])
            end
            pipAlpha[i] = targetAlpha
        end
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UNIT_COMBO_POINTS")
    f:RegisterEvent("PLAYER_COMBO_POINTS")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    f:RegisterEvent("UPDATE_SHAPESHIFT_USABLE")
    f:SetScript("OnEvent", Update)

    Relayout()

    DFRL:NewCallbacks("ComboPoints", {
        enabled   = Update,
        size      = function() Relayout(); Update() end,
        spacing   = function() Relayout(); Update() end,
        offsetX   = AnchorToTarget,
        offsetY   = AnchorToTarget,
        lowColor  = Update,
        midColor  = Update,
        highColor = Update,
    })
end)