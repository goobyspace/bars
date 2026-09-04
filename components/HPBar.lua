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
    -- lets GetHealAbsorbs()/GetIncomingHeals() net the two against each other internally, since retail
    -- disallows Lua arithmetic (healAbsorb - incomingHeal) on these secret values ourselves
    frame.healCalc:SetHealAbsorbMode(Enum.UnitHealAbsorbMode.ReducedByIncomingHeals);

    -- represents ONLY the incoming heal amount -- never combined with current health via Lua
    -- arithmetic, which retail disallows on secret health values. Anchored natively to frame.bar's own
    -- fill texture's right edge (a zero-offset anchor, resolved by the engine, not computed by us) so it
    -- always starts exactly where current health ends and never needs per-update anchor math.
    frame.healPredictionBar = CreateFrame("StatusBar", nil, frame)
    core:SetPixelSize(frame.healPredictionBar, width, height);
    frame.healPredictionBar:SetPoint("LEFT", frame.bar:GetStatusBarTexture(), "RIGHT", 0, 0);
    frame.healPredictionBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
    frame.healPredictionBar:SetFrameLevel(frame.bar:GetFrameLevel() + 1)
    frame.healPredictionBar:SetStatusBarColor(0, 1, 0.59, 0.8)

    -- shield/absorb amount: like CompactUnitFrame's totalAbsorb bar, drawn as an extension past
    -- wherever current health + predicted healing ends, via the same zero-offset anchor trick as
    -- frame.healPredictionBar above so it never needs per-update anchor math
    frame.absorbBar = CreateFrame("StatusBar", nil, frame.bar)
    core:SetPixelSize(frame.absorbBar, width, height);
    frame.absorbBar:SetPoint("LEFT", frame.healPredictionBar:GetStatusBarTexture(), "RIGHT", 0, 0);
    frame.absorbBar:SetStatusBarTexture("Interface/Addons/Bars/assets/absorb.png")
    frame.absorbBar:SetFrameLevel(frame.bar:GetFrameLevel() + 2)
    frame.absorbBar:SetStatusBarColor(1, 1, 1, 0.7)

    -- shield overflow: retail won't let Lua subtract two secret numbers, so instead of computing the
    -- overflow amount ourselves this bar is clamped to (missingHealthBoundary, maxHP) and fed the raw
    -- absorb value -- the StatusBar engine does the equivalent subtraction internally and simply shows
    -- a zero-width fill whenever nothing overflows. Sized to the full bar width (like the other overlay
    -- bars) so the fill fraction maps onto the same pixel scale as the rest of the bar.
    frame.absorbOverflowBar = CreateFrame("StatusBar", nil, frame)
    core:SetPixelPoint(frame.absorbOverflowBar, "TOPLEFT", frame.bar, "TOPLEFT", 0, 0);
    core:SetPixelPoint(frame.absorbOverflowBar, "BOTTOMLEFT", frame.bar, "BOTTOMLEFT", 0, 0);
    core:SetPixelSize(frame.absorbOverflowBar, width, height);
    frame.absorbOverflowBar:SetStatusBarTexture("Interface/Addons/Bars/assets/absorb.png")
    frame.absorbOverflowBar:SetFrameLevel(frame.bar:GetFrameLevel() + 4)
    frame.absorbOverflowBar:SetStatusBarColor(1, 1, 1, 0.7)

    -- heal-absorb debuff: like CompactUnitFrame's myHealAbsorb bar, eats into current health from its
    -- right edge inward, so it's reverse-filled and anchored to that same edge instead of overlaid
    frame.healAbsorbBar = CreateFrame("StatusBar", nil, frame.bar)
    core:SetPixelSize(frame.healAbsorbBar, width, height);
    frame.healAbsorbBar:SetPoint("RIGHT", frame.bar:GetStatusBarTexture(), "RIGHT", 0, 0);
    frame.healAbsorbBar:SetReverseFill(true);
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

    -- incoming heal prediction: represents ONLY incomingHeal (never currentHP+incomingHeal -- retail
    -- disallows Lua arithmetic on secret health values). Anchored once at creation to frame.bar's own
    -- fill texture edge (see CreateHPBarBase), so it always starts exactly where current health ends
    -- with zero per-update anchor math; both values below are passed through unmodified.
    UnitGetDetailedHealPrediction(unit, nil, frame.healCalc);
    -- UnitGetDetailedHealPrediction resets the calculator's options, so overflow/mode must be re-applied every update
    frame.healCalc:SetIncomingHealOverflowPercent(core.healPredictionOverflow);
    frame.healCalc:SetHealAbsorbMode(Enum.UnitHealAbsorbMode.ReducedByIncomingHeals);
    local incomingHeal = frame.healCalc:GetIncomingHeals() or 0;
    frame.healPredictionBar:SetMinMaxValues(0, maxHP, Enum.StatusBarInterpolation.ExponentialEaseOut)
    frame.healPredictionBar:SetValue(incomingHeal, Enum.StatusBarInterpolation.ExponentialEaseOut)

    -- shield absorb: drawn past current health + predicted healing via the anchor set up in
    -- CreateHPBarBase, same as CompactUnitFrame's totalAbsorb bar. Clamped to the room actually left
    -- before maxHP so it never spills out past the bar's background.
    frame.healCalc:SetDamageAbsorbClampMode(Enum.UnitDamageAbsorbClampMode.MissingHealth);
    local absorb = frame.healCalc:GetDamageAbsorbs() or 0;
    frame.absorbBar:SetMinMaxValues(0, maxHP, Enum.StatusBarInterpolation.ExponentialEaseOut)
    frame.absorbBar:SetValue(absorb, Enum.StatusBarInterpolation.ExponentialEaseOut)

    -- shield overflow: fed the SAME raw, unclamped absorb value but with min set to the clamp
    -- boundary above, so whatever exceeds that boundary is the only part that fills this bar
    local overflowBoundary = frame.healCalc:GetMaximumDamageAbsorbs();
    local rawAbsorb = UnitGetTotalAbsorbs(unit) or 0;
    frame.absorbOverflowBar:SetMinMaxValues(overflowBoundary, maxHP, Enum.StatusBarInterpolation.ExponentialEaseOut)
    frame.absorbOverflowBar:SetValue(rawAbsorb, Enum.StatusBarInterpolation.ExponentialEaseOut)

    -- heal absorb debuff: GetHealAbsorbs() already nets out the portion covered by incoming heals
    -- (see SetHealAbsorbMode above), since incoming heals would otherwise fill straight over it
    local shownHealAbsorb = frame.healCalc:GetHealAbsorbs() or 0;
    frame.healAbsorbBar:SetMinMaxValues(0, maxHP, Enum.StatusBarInterpolation.ExponentialEaseOut)
    frame.healAbsorbBar:SetValue(shownHealAbsorb, Enum.StatusBarInterpolation.ExponentialEaseOut)

    return currentHP, maxHP;
end
