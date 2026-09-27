local _, core = ...;

local colours = core.colours;
core.ClassColors = colours.classes;

local function setBarRangeAndValue(bar, minimum, maximum, value, immediate)
    if immediate then
        bar:SetMinMaxValues(minimum, maximum);
        bar:SetValue(value);
    else
        bar:SetMinMaxValues(minimum, maximum, Enum.StatusBarInterpolation.ExponentialEaseOut);
        bar:SetValue(value, Enum.StatusBarInterpolation.ExponentialEaseOut);
    end;
end;

function core:CreateHPBarBase(name, parent, width, height, template)
    local frame = core:CreateSimpleStatusBar(name, parent, width, height, { template = template });
    frame.bar:SetStatusBarColor(colours.white.r, colours.white.g, colours.white.b);

    frame.healCalc = CreateUnitHealPredictionCalculator();
    frame.healCalc:SetIncomingHealOverflowPercent(core.healPredictionOverflow);
    -- we let blizzard handle this because were not allowed to do heal calcs in combat
    frame.healCalc:SetHealAbsorbMode(Enum.UnitHealAbsorbMode.ReducedByIncomingHeals);

    -- this was a pain in the ass to keep working but tldr using the using the setpoint we can make it start at the edge anyway
    frame.healPredictionBar = CreateFrame("StatusBar", nil, frame);
    core:SetPixelSize(frame.healPredictionBar, width, height);
    frame.healPredictionBar:SetPoint("LEFT", frame.bar:GetStatusBarTexture(), "RIGHT", 0, 0);
    frame.healPredictionBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    frame.healPredictionBar:SetFrameLevel(frame.bar:GetFrameLevel() + 1);
    frame.healPredictionBar:SetStatusBarColor(colours.healPrediction.r, colours.healPrediction.g,
        colours.healPrediction.b, colours.healPrediction.a);

    -- same edge fix, just starting after health plus predicted heals
    frame.absorbBar = CreateFrame("StatusBar", nil, frame.bar);
    core:SetPixelSize(frame.absorbBar, width, height);
    frame.absorbBar:SetPoint("LEFT", frame.healPredictionBar:GetStatusBarTexture(), "RIGHT", 0, 0);
    frame.absorbBar:SetStatusBarTexture("Interface/Addons/Bars/assets/absorb.png");
    frame.absorbBar:SetFrameLevel(frame.bar:GetFrameLevel() + 2);
    frame.absorbBar:SetStatusBarColor(colours.absorb.r, colours.absorb.g, colours.absorb.b, colours.absorb.a);

    -- put the absorb value in and set the bar's minimum to the overflow
    frame.absorbOverflowBar = CreateFrame("StatusBar", nil, frame);
    core:SetPixelPoint(frame.absorbOverflowBar, "TOPLEFT", frame.bar, "TOPLEFT", 0, 0);
    core:SetPixelPoint(frame.absorbOverflowBar, "BOTTOMLEFT", frame.bar, "BOTTOMLEFT", 0, 0);
    core:SetPixelSize(frame.absorbOverflowBar, width, height);
    frame.absorbOverflowBar:SetStatusBarTexture("Interface/Addons/Bars/assets/absorb.png");
    frame.absorbOverflowBar:SetFrameLevel(frame.bar:GetFrameLevel() + 4);
    frame.absorbOverflowBar:SetStatusBarColor(colours.absorb.r, colours.absorb.g, colours.absorb.b, colours.absorb.a);

    -- fill backwards from the health edge like the way blizz heal absorbs work
    frame.healAbsorbBar = CreateFrame("StatusBar", nil, frame.bar);
    core:SetPixelSize(frame.healAbsorbBar, width, height);
    frame.healAbsorbBar:SetPoint("RIGHT", frame.bar:GetStatusBarTexture(), "RIGHT", 0, 0);
    frame.healAbsorbBar:SetReverseFill(true);
    frame.healAbsorbBar:SetStatusBarTexture("interface/RAIDFRAME/RaidFrameAbsorbOverlay");
    frame.healAbsorbBar:SetFrameLevel(frame.bar:GetFrameLevel() + 3);
    frame.healAbsorbBar:SetStatusBarColor(colours.absorb.r, colours.absorb.g, colours.absorb.b, colours.absorb.a);

    setBarRangeAndValue(frame.bar, 0, 1, 0, true);
    setBarRangeAndValue(frame.healPredictionBar, 0, 1, 0, true);
    setBarRangeAndValue(frame.absorbBar, 0, 1, 0, true);
    setBarRangeAndValue(frame.absorbOverflowBar, 0, 1, 0, true);
    setBarRangeAndValue(frame.healAbsorbBar, 0, 1, 0, true);

    return frame;
end;

function core:UpdateHPBarValues(frame, unit, immediate)
    if not UnitExists(unit) then
        return nil, nil;
    end;

    local maxHP = UnitHealthMax(unit);
    local currentHP = UnitHealth(unit, true);
    if not maxHP or (not issecretvalue(maxHP) and maxHP <= 0) then
        return nil, nil;
    end;

    setBarRangeAndValue(frame.bar, 0, maxHP, currentHP, immediate);

    UnitGetDetailedHealPrediction(unit, nil, frame.healCalc);
    -- UnitGetDetailedHealPrediction resets the calc so we have to re-set it
    frame.healCalc:SetIncomingHealOverflowPercent(core.healPredictionOverflow);
    frame.healCalc:SetHealAbsorbMode(Enum.UnitHealAbsorbMode.ReducedByIncomingHeals);
    local incomingHeal = frame.healCalc:GetIncomingHeals() or 0;
    setBarRangeAndValue(frame.healPredictionBar, 0, maxHP, incomingHeal, true);

    frame.healCalc:SetDamageAbsorbClampMode(Enum.UnitDamageAbsorbClampMode.MissingHealth);
    local absorb = frame.healCalc:GetDamageAbsorbs() or 0;
    setBarRangeAndValue(frame.absorbBar, 0, maxHP, absorb, true);

    -- starting at the boundary leaves only overflow visible
    local overflowBoundary = frame.healCalc:GetMaximumDamageAbsorbs();
    local rawAbsorb = UnitGetTotalAbsorbs(unit) or 0;
    setBarRangeAndValue(frame.absorbOverflowBar, overflowBoundary, maxHP, rawAbsorb, true);

    -- heal absorbs here are already reduced by incoming heals (see SetHealAbsorbMode above).
    local shownHealAbsorb = frame.healCalc:GetHealAbsorbs() or 0;
    setBarRangeAndValue(frame.healAbsorbBar, 0, maxHP, shownHealAbsorb, true);

    return currentHP, maxHP;
end;
