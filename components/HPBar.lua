local _, core = ...

local colours = core.colours
core.ClassColors = colours.classes

function core:CreateHPBarBase(name, parent, width, height, template)
    local frame = core:CreateSimpleStatusBar(name, parent, width, height, { template = template });
    frame.bar:SetStatusBarColor(colours.white.r, colours.white.g, colours.white.b);

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
    frame.healPredictionBar:SetStatusBarColor(colours.healPrediction.r, colours.healPrediction.g,
        colours.healPrediction.b, colours.healPrediction.a)

    -- shield/absorb amount: like CompactUnitFrame's totalAbsorb bar, drawn as an extension past
    -- wherever current health + predicted healing ends, via the same zero-offset anchor trick as
    -- frame.healPredictionBar above so it never needs per-update anchor math
    frame.absorbBar = CreateFrame("StatusBar", nil, frame.bar)
    core:SetPixelSize(frame.absorbBar, width, height);
    frame.absorbBar:SetPoint("LEFT", frame.healPredictionBar:GetStatusBarTexture(), "RIGHT", 0, 0);
    frame.absorbBar:SetStatusBarTexture("Interface/Addons/Bars/assets/absorb.png")
    frame.absorbBar:SetFrameLevel(frame.bar:GetFrameLevel() + 2)
    frame.absorbBar:SetStatusBarColor(colours.absorb.r, colours.absorb.g, colours.absorb.b, colours.absorb.a)

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
    frame.absorbOverflowBar:SetStatusBarColor(colours.absorb.r, colours.absorb.g, colours.absorb.b, colours.absorb.a)

    -- heal-absorb debuff: like CompactUnitFrame's myHealAbsorb bar, eats into current health from its
    -- right edge inward, so it's reverse-filled and anchored to that same edge instead of overlaid
    frame.healAbsorbBar = CreateFrame("StatusBar", nil, frame.bar)
    core:SetPixelSize(frame.healAbsorbBar, width, height);
    frame.healAbsorbBar:SetPoint("RIGHT", frame.bar:GetStatusBarTexture(), "RIGHT", 0, 0);
    frame.healAbsorbBar:SetReverseFill(true);
    frame.healAbsorbBar:SetStatusBarTexture("interface/RAIDFRAME/RaidFrameAbsorbOverlay")
    frame.healAbsorbBar:SetFrameLevel(frame.bar:GetFrameLevel() + 3)
    frame.healAbsorbBar:SetStatusBarColor(colours.absorb.r, colours.absorb.g, colours.absorb.b, colours.absorb.a)

    return frame;
end

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
