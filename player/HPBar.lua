local _, core = ...

local frame = nil;

local function UpdateBar()
    if not frame or not frame:IsShown() then return end;

    -- hp:
    local maxHP = UnitHealthMax("player");
    local currentHP = UnitHealth("player", true);
    if not maxHP then
        return frame:Hide();
    end

    frame.bar:SetMinMaxValues(0, maxHP, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.bar:SetValue(currentHP, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.text:SetText(AbbreviateNumbers(currentHP));

    -- healing absorb:
    local absorb = UnitGetTotalAbsorbs("player") or 0;
    if frame.absorbBar:IsShown() then
        frame.absorbBar:SetMinMaxValues(0, select(2, frame.bar:GetMinMaxValues()),
            Enum.StatusBarInterpolation.ExponentialEaseOut)
        frame.absorbBar:SetValue(absorb,
            Enum.StatusBarInterpolation.ExponentialEaseOut)
    end

    local healAbsorb = UnitGetTotalHealAbsorbs("player") or 0;
    if frame.healAbsorbBar:IsShown() then
        frame.healAbsorbBar:SetMinMaxValues(0, select(2, frame.bar:GetMinMaxValues()),
            Enum.StatusBarInterpolation.ExponentialEaseOut)
        frame.healAbsorbBar:SetValue(healAbsorb,
            Enum.StatusBarInterpolation.ExponentialEaseOut)
    end
end

function core:CreateHPBar(parent)
    frame = CreateFrame("Frame", "HPBarContainer", parent)
    core:SetPixelSize(frame, core:EvenPixels(core.width / 3), core.barBgHeight);

    frame.bg = frame:CreateTexture();
    core:SetPixelPoint(frame.bg, "CENTER", frame, "CENTER", 0, 0);
    frame.bg:SetTexture(134532)
    frame.bg:SetColorTexture(0, 0, 0);
    core:SetPixelSize(frame.bg, core:EvenPixels(core.width / 3), core.barBgHeight);
    frame.bg:SetDrawLayer("OVERLAY", -1);

    frame.bar = CreateFrame("StatusBar", nil, frame);
    frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    core:InsetBarInBackground(frame.bar, frame.bg);
    frame.bar:SetStatusBarColor(200 / 255, 70 / 255, 80 / 255)

    frame.absorbBar = CreateFrame("StatusBar", nil, frame.bar)
    frame.absorbBar:SetAllPoints(frame.bar);
    frame.absorbBar:SetStatusBarTexture("Interface/Addons/Bars/assets/absorb.png")
    frame.absorbBar:SetFrameLevel(frame.bar:GetFrameLevel() + 1)
    frame.absorbBar:SetStatusBarColor(1, 1, 1, 0.7)

    frame.healAbsorbBar = CreateFrame("StatusBar", nil, frame.bar)
    frame.healAbsorbBar:SetAllPoints(frame.bar);
    frame.healAbsorbBar:SetStatusBarTexture("interface/RAIDFRAME/RaidFrameAbsorbOverlay")
    frame.healAbsorbBar:SetFrameLevel(frame.bar:GetFrameLevel() + 1)
    frame.healAbsorbBar:SetStatusBarColor(1, 1, 1, 0.7)

    frame.text = frame.bar:CreateFontString("PrimaryText");
    frame.text:SetDrawLayer("OVERLAY", 1);
    frame.text:SetPoint("RIGHT", 0, 10);
    frame.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    frame:RegisterUnitEvent("UNIT_HEALTH", "player")
    frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "player")
    frame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "player")
    frame:RegisterEvent("PET_BATTLE_OPENING_START")
    frame:RegisterEvent("PET_BATTLE_CLOSE")

    local playerClass = select(2, UnitClass("player"))

    if playerClass == "DRUID" then
        frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    end

    frame:SetScript("OnEvent", function()
        UpdateBar();
    end)

    return frame;
end
