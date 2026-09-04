local _, core = ...

core.ClassColors = {
    --warrior
    [1] = { r = 0.78, g = 0.61, b = 0.43 },
    -- paladin
    [2] = { r = 0.96, g = 0.55, b = 0.73 },
    -- hunter
    [3] = { r = 0.67, g = 0.83, b = 0.45 },
    -- rogue
    [4] = { r = 1, g = 0.96, b = 0.41 },
    -- priest
    [5] = { r = 1, g = 1, b = 1 },
    -- death knight
    [6] = { r = 0.77, g = 0.12, b = 0.23 },
    -- shaman
    [7] = { r = 0, g = 0.44, b = 0.87 },
    -- mage
    [8] = { r = 0.25, g = 0.78, b = 0.92 },
    -- warlock
    [9] = { r = 0.53, g = 0.53, b = 0.93 },
    -- monk
    [10] = { r = 0, g = 1, b = 0.6 },
    -- druid
    [11] = { r = 1, g = 0.49, b = 0.04 },
    -- dh
    [12] = { r = 0.64, g = 0.19, b = 0.79 },
    -- evoker
    [13] = { r = 0.2, g = 0.58, b = 0.50 },
    ["neutral"] = { r = 1, g = 1, b = 0 },
    ["hostile"] = { r = 1, g = 0, b = 0 },
    ["friendly"] = { r = 0, g = 1, b = 0 },
}

-- creates the chrome shared by every HP bar: background, status bar, and the absorb/heal-absorb/
-- heal-prediction overlay bars. Callers add their own text/labels, unit-specific colouring, and
-- event wiring on top of the returned frame.
function core:CreateHPBarBase(name, parent, width, height, template)
    local frame = CreateFrame("Frame", name, parent, template);
    core:SetPixelSize(frame, width, height);

    frame.bg = frame:CreateTexture();
    core:SetPixelPoint(frame.bg, "CENTER", frame, "CENTER", 0, 0);
    frame.bg:SetTexture(134532)
    frame.bg:SetColorTexture(0, 0, 0);
    core:SetPixelSize(frame.bg, width, height);
    frame.bg:SetDrawLayer("OVERLAY", -1);

    frame.bar = CreateFrame("StatusBar", nil, frame);
    frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    core:InsetBarInBackground(frame.bar, frame.bg);
    frame.bar:SetStatusBarColor(1, 1, 1)

    frame.healCalc = CreateUnitHealPredictionCalculator();
    frame.healCalc:SetIncomingHealOverflowPercent(core.healPredictionOverflow);

    -- positioned/sized dynamically each update (see UpdateHPBarValues) to start exactly where current health ends
    frame.healPredictionBar = CreateFrame("StatusBar", nil, frame.bar)
    frame.healPredictionBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
    frame.healPredictionBar:SetMinMaxValues(0, 1);
    frame.healPredictionBar:SetValue(1);
    frame.healPredictionBar:SetFrameLevel(frame.bar:GetFrameLevel() + 1)
    frame.healPredictionBar:SetStatusBarColor(0, 1, 0.59, 0.8)
    frame.healPredictionBar:Hide();

    frame.absorbBar = CreateFrame("StatusBar", nil, frame.bar)
    frame.absorbBar:SetAllPoints(frame.bar);
    frame.absorbBar:SetStatusBarTexture("Interface/Addons/Bars/assets/absorb.png")
    frame.absorbBar:SetFrameLevel(frame.bar:GetFrameLevel() + 2)
    frame.absorbBar:SetStatusBarColor(1, 1, 1, 0.7)

    frame.healAbsorbBar = CreateFrame("StatusBar", nil, frame.bar)
    frame.healAbsorbBar:SetAllPoints(frame.bar);
    frame.healAbsorbBar:SetStatusBarTexture("interface/RAIDFRAME/RaidFrameAbsorbOverlay")
    frame.healAbsorbBar:SetFrameLevel(frame.bar:GetFrameLevel() + 3)
    frame.healAbsorbBar:SetStatusBarColor(1, 1, 1, 0.7)

    return frame;
end

-- updates the bar fill, absorb/heal-absorb overlays, and heal-prediction sliver for `unit`.
-- returns currentHP, maxHP; both nil if the unit has no valid health (caller should Hide()).
function core:UpdateHPBarValues(frame, unit)
    local maxHP = UnitHealthMax(unit);
    local currentHP = UnitHealth(unit, true);
    if not maxHP then
        return nil, nil;
    end

    frame.bar:SetMinMaxValues(0, maxHP, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.bar:SetValue(currentHP, Enum.StatusBarInterpolation.ExponentialEaseOut);

    -- healing absorb:
    local absorb = UnitGetTotalAbsorbs(unit) or 0;
    if frame.absorbBar:IsShown() then
        frame.absorbBar:SetMinMaxValues(0, select(2, frame.bar:GetMinMaxValues()),
            Enum.StatusBarInterpolation.ExponentialEaseOut)
        frame.absorbBar:SetValue(absorb,
            Enum.StatusBarInterpolation.ExponentialEaseOut)
    end

    local healAbsorb = UnitGetTotalHealAbsorbs(unit) or 0;
    if frame.healAbsorbBar:IsShown() then
        frame.healAbsorbBar:SetMinMaxValues(0, select(2, frame.bar:GetMinMaxValues()),
            Enum.StatusBarInterpolation.ExponentialEaseOut)
        frame.healAbsorbBar:SetValue(healAbsorb,
            Enum.StatusBarInterpolation.ExponentialEaseOut)
    end

    -- incoming heal prediction (Blizzard's secret-safe calculator handles clamping/overflow internally)
    UnitGetDetailedHealPrediction(unit, nil, frame.healCalc);
    -- UnitGetDetailedHealPrediction resets the calculator's options, so overflow must be re-applied every update
    frame.healCalc:SetIncomingHealOverflowPercent(core.healPredictionOverflow);
    local incomingHeal = frame.healCalc:GetIncomingHeals() or 0;
    if incomingHeal > 0 then
        -- anchor/size directly from the health fraction so the sliver always starts exactly where
        -- current health ends, and can spill past the bar's right edge for genuine overhealing
        local barWidth = frame.bar:GetWidth();
        frame.healPredictionBar:ClearAllPoints();
        frame.healPredictionBar:SetPoint("TOPLEFT", frame.bar, "TOPLEFT", barWidth * (currentHP / maxHP), 0);
        frame.healPredictionBar:SetPoint("BOTTOMLEFT", frame.bar, "BOTTOMLEFT", barWidth * (currentHP / maxHP), 0);
        frame.healPredictionBar:SetWidth(barWidth * (incomingHeal / maxHP));
        frame.healPredictionBar:Show();
    else
        frame.healPredictionBar:Hide();
    end

    return currentHP, maxHP;
end
