local _, core = ...

local frame = nil;

local function UpdateBar()
    if not frame or not frame:IsShown() then return end;

    -- hp:
    local maxHP = UnitHealthMax("target");
    local currentHP = UnitHealth("target", true);
    if not maxHP then
        return frame:Hide();
    end

    frame.bar:SetMinMaxValues(0, maxHP, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.bar:SetValue(currentHP, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.text:SetText(AbbreviateNumbers(currentHP));

    -- healing absorb:
    local absorb = UnitGetTotalAbsorbs("target") or 0;
    if frame.absorbBar:IsShown() then
        frame.absorbBar:SetMinMaxValues(0, select(2, frame.bar:GetMinMaxValues()),
            Enum.StatusBarInterpolation.ExponentialEaseOut)
        frame.absorbBar:SetValue(absorb,
            Enum.StatusBarInterpolation.ExponentialEaseOut)
    end

    local healAbsorb = UnitGetTotalHealAbsorbs("target") or 0;
    if frame.healAbsorbBar:IsShown() then
        frame.healAbsorbBar:SetMinMaxValues(0, select(2, frame.bar:GetMinMaxValues()),
            Enum.StatusBarInterpolation.ExponentialEaseOut)
        frame.healAbsorbBar:SetValue(healAbsorb,
            Enum.StatusBarInterpolation.ExponentialEaseOut)
    end
end

function core:CreateTargetHPBar(parent)
    frame = CreateFrame("Frame", "TargetHPBarContainer", parent)
    frame:SetSize(core.width, 4);

    frame.bg = frame:CreateTexture();
    frame.bg:SetPoint("CENTER");
    frame.bg:SetTexture(134532)
    frame.bg:SetColorTexture(0, 0, 0);
    frame.bg:SetSize(core.width, 4);
    frame.bg:SetDrawLayer("OVERLAY", -1);

    frame.bar = CreateFrame("StatusBar", nil, frame);
    frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    frame.bar:SetPoint("CENTER");
    frame.bar:SetSize(core.width - 2, 2);
    frame.bar:SetStatusBarColor(200 / 255, 70 / 255, core.width / 255)

    frame.absorbBar = CreateFrame("StatusBar", nil, frame.bar)
    frame.absorbBar:SetPoint("CENTER");
    frame.absorbBar:SetSize(core.width - 2, 2);
    frame.absorbBar:SetStatusBarTexture("Interface/Addons/Bars/texture/absorb.png")
    frame.absorbBar:SetFrameLevel(frame.bar:GetFrameLevel() + 1)
    frame.absorbBar:SetStatusBarColor(1, 1, 1, 0.7)

    frame.healAbsorbBar = CreateFrame("StatusBar", nil, frame.bar)
    frame.healAbsorbBar:SetPoint("CENTER");
    frame.healAbsorbBar:SetSize(core.width - 2, 2);
    frame.healAbsorbBar:SetStatusBarTexture("interface/RAIDFRAME/RaidFrameAbsorbOverlay")
    frame.healAbsorbBar:SetFrameLevel(frame.bar:GetFrameLevel() + 1)
    frame.healAbsorbBar:SetStatusBarColor(1, 1, 1, 0.7)

    frame.text = frame.bar:CreateFontString("PrimaryText");
    frame.text:SetDrawLayer("OVERLAY", 1);
    frame.text:SetPoint("RIGHT", 0, 10);
    frame.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "target")
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "target")
    frame:RegisterUnitEvent("UNIT_HEALTH", "target")
    frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "target")
    frame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "target")
    frame:RegisterUnitEvent("PLAYER_TARGET_DIED")
    frame:RegisterEvent("PET_BATTLE_OPENING_START")
    frame:RegisterEvent("PET_BATTLE_CLOSE")

    local playerClass = select(2, UnitClass("target"))

    if playerClass == "DRUID" then
        frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    end

    frame:SetScript("OnEvent", function()
        UpdateBar();
    end)

    return frame;
end
