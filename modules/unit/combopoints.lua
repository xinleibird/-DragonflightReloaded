setfenv(1, DFRL:GetEnv())

DFRL:NewDefaults("ComboPoints", {
    enabled  = {true, "checkbox", nil, nil, "General", 1,
                "Display combo points for rogue / druid cat form", nil, nil},
    size     = {14, "slider", {8, 24}, "enabled", "Layout", 2,
                "Width and height of each combo point pip", nil, nil},
    spacing  = {2,  "slider", {0, 8},  "enabled", "Layout", 3,
                "Pixel gap between pips", nil, nil},
    lowColor = {{1, 0.3, 0.3}, "colour", nil, "enabled", "Colors", 4,
                "Pip color for 1-2 combo points", nil, nil},
    midColor = {{1, 1,   0.3}, "colour", nil, "enabled", "Colors", 5,
                "Pip color for 3 combo points", nil, nil},
    highColor= {{0.3, 1, 0.3}, "colour", nil, "enabled", "Colors", 6,
                "Pip color for 4-5 combo points", nil, nil},
})

DFRL:NewMod("ComboPoints", 1, function()
    if MAX_COMBO_POINTS == nil then MAX_COMBO_POINTS = 5 end

    local _, class = UnitClass("player")
    if class ~= "ROGUE" and class ~= "DRUID" then return end

    local container = CreateFrame("Frame", "DFRL_ComboPoints", UIParent)
    container:SetMovable(true)
    container:EnableMouse(false)
    container:SetFrameStrata("MEDIUM")
    container:Hide()
    DFRL.comboPointsContainer = container

    local pips = {}
    for i = 1, MAX_COMBO_POINTS do
        local pip = CreateFrame("Frame", "DFRL_ComboPoints_Pip" .. i, container)
        pip.tex = pip:CreateTexture(nil, "BACKGROUND")
        pip.tex:SetAllPoints(pip)
        pips[i] = pip
    end

    local anchored = false
    local function AnchorToTarget()
        if anchored then return end
        if not TargetFrame then return end
        if DFRL_FRAMEPOS and DFRL_FRAMEPOS["DFRL_ComboPoints"] then
            anchored = true
            return
        end
        container:ClearAllPoints()
        container:SetPoint("BOTTOM", TargetFrame, "TOP", 0, 6)
        anchored = true
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

    local function Update()
        if not DFRL:GetTempDB("ComboPoints", "enabled") or not InComboForm() then
            container:Hide()
            return
        end
        AnchorToTarget()
        local n = GetComboPoints() or 0
        if n > MAX_COMBO_POINTS then n = MAX_COMBO_POINTS end

        container:Show()
        for i = 1, MAX_COMBO_POINTS do
            if i <= n and n > 0 then
                local r, g, b = PipColor(i)
                pips[i].tex:SetTexture(r, g, b, 0.85)
            else
                pips[i].tex:SetTexture(0.2, 0.2, 0.2, 0.4)
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
        enabled   = Update,
        size      = function() Relayout(); Update() end,
        spacing   = function() Relayout(); Update() end,
        lowColor  = Update,
        midColor  = Update,
        highColor = Update,
    })
end)