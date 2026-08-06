setfenv(1, DFRL:GetEnv())

-- Master switch: when ComboPoints.enabled is true, disable Blizzard's
-- built-in ComboFrame so only this addon's pips show. When false,
-- restore ComboFrame to its default behavior.
local function ApplyComboFrameState(combo, enabled)
    if enabled then
        combo:UnregisterAllEvents()
        combo:Hide()
    else
        combo:RegisterEvent("UNIT_COMBO_POINTS")
        combo:RegisterEvent("PLAYER_COMBO_POINTS")
        combo:RegisterEvent("PLAYER_TARGET_CHANGED")
        combo:RegisterEvent("PLAYER_ENTERING_WORLD")
        combo:Show()
    end
end

do
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        local combo = _G["ComboFrame"]
        if not combo then return end
        local db = DFRL and DFRL.tempDB and DFRL.tempDB.ComboPoints
        if db then ApplyComboFrameState(combo, db.enabled) end
    end)
end

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
    rounded  = {14, "slider", {0, 14}, "enabled", "Layout", 6,
                "Corner roundness (0 = square, 14 = most rounded)", nil, nil},
    lowColor = {{1, 0.3, 0.3}, "colour", nil, "enabled", "Colors", 7,
                "Pip color for 1-2 combo points", nil, nil},
    midColor = {{1, 1,   0.3}, "colour", nil, "enabled", "Colors", 8,
                "Pip color for 3 combo points", nil, nil},
    highColor= {{0.3, 1, 0.3}, "colour", nil, "enabled", "Colors", 9,
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
    local pipActive = {}
    local pipOffsetX = {}

    local function ApplyBackdrop(pip)
        local rounded = DFRL:GetTempDB("ComboPoints", "rounded")
        if rounded < 1 then
            pip:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8X8",
                edgeFile = nil,
                tile = false, tileSize = 0, edgeSize = 0,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
        else
            pip:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = rounded,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
        end
    end

    for i = 1, MAX_COMBO_POINTS do
        local pip = CreateFrame("Frame", "DFRL_ComboPoints_Pip" .. i, container)
        ApplyBackdrop(pip)
        pip:SetBackdropColor(0.15, 0.15, 0.15, 1)
        pip:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        pip:SetAlpha(1)
        pips[i] = pip
        pipActive[i] = false
        pipOffsetX[i] = 0
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
        local total = MAX_COMBO_POINTS * size + (MAX_COMBO_POINTS - 1) * spacing
        for i = 1, MAX_COMBO_POINTS do
            pips[i]:SetWidth(size)
            pips[i]:SetHeight(size)
            pips[i]:ClearAllPoints()
            pipOffsetX[i] = -total / 2 + size / 2 + (i - 1) * (size + spacing)
            pips[i]:SetPoint("CENTER", container, "CENTER", pipOffsetX[i], 0)
        end
        container:SetWidth(total)
        container:SetHeight(size)
    end

    local function InComboForm()
        if class == "ROGUE" then return true end
        local form = GetShapeshiftForm and GetShapeshiftForm()
        return form == 1 or form == 2 or form == 3
    end

    local function PulsePip(pip, baseX)
        pip.pulseTime = 0
        local baseW = pip:GetWidth()
        local baseH = pip:GetHeight()
        pip:SetScript("OnUpdate", function()
            this.pulseTime = (this.pulseTime or 0) + arg1
            local t = this.pulseTime / 0.5
            local scale
            if t >= 1 then
                scale = 1
            elseif t < 0.5 then
                local nt = t * 2
                scale = 1.0 + 0.6 * (1 - (1 - nt) * (1 - nt))
            else
                local nt = (t - 0.5) * 2
                scale = 1.6 - 0.6 * (nt * nt)
            end
            -- Resize the frame in place; anchor stays at CENTER + baseX so
            -- the visual center is pinned to its original position.
            this:ClearAllPoints()
            this:SetWidth(baseW * scale)
            this:SetHeight(baseH * scale)
            this:SetPoint("CENTER", container, "CENTER", baseX, 0)
            if t >= 1 then
                this:SetScript("OnUpdate", nil)
            end
        end)
    end

    local function ShowCombo()
        if visible then return end
        visible = true
        UIFrameFadeIn(container, 0.25, 0, 1)
    end

    local function HideCombo()
        if not visible then return end
        visible = false
        UIFrameFadeOut(container, 0.35, container:GetAlpha(), 0)
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
            if i <= n then
                local r, g, b = PipColor(i)
                pips[i]:SetBackdropColor(r, g, b, 1)
                if not pipActive[i] then
                    PulsePip(pips[i], pipOffsetX[i])
                    pipActive[i] = true
                end
            else
                pips[i]:SetBackdropColor(0.15, 0.15, 0.15, 1)
                pipActive[i] = false
            end
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
        enabled   = function(value)
            local combo = _G["ComboFrame"]
            if combo then ApplyComboFrameState(combo, value) end
            Update()
        end,
        size      = function() Relayout(); Update() end,
        spacing   = function() Relayout(); Update() end,
        offsetX   = AnchorToTarget,
        offsetY   = AnchorToTarget,
        rounded   = function()
            for i = 1, MAX_COMBO_POINTS do
                ApplyBackdrop(pips[i])
                if pipActive[i] then
                    local r, g, b = PipColor(i)
                    pips[i]:SetBackdropColor(r, g, b, 1)
                else
                    pips[i]:SetBackdropColor(0.15, 0.15, 0.15, 1)
                end
            end
        end,
        lowColor  = Update,
        midColor  = Update,
        highColor = Update,
    })
end)