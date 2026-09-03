local _, core = ...

local frame = nil;

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

local function UpdateBar()
    if not frame or not frame:IsShown() then return end;

    local isPlayer = UnitIsPlayer("target")
    local threat = UnitThreatSituation("player", "target")
    if isPlayer then
        local _, _, id = UnitClass("target");
        frame.bar:SetStatusBarColor(core.ClassColors[id].r, core.ClassColors[id].g, core.ClassColors[id].b)
    elseif threat ~= nil or UnitIsEnemy("player", "target") then
        frame.bar:SetStatusBarColor(core.ClassColors["hostile"].r, core.ClassColors["hostile"].g,
            core.ClassColors["hostile"].b)
    elseif UnitIsFriend("player", "target") then
        frame.bar:SetStatusBarColor(core.ClassColors["friendly"].r, core.ClassColors["friendly"].g,
            core.ClassColors["friendly"].b)
    else
        frame.bar:SetStatusBarColor(core.ClassColors["neutral"].r, core.ClassColors["neutral"].g,
            core.ClassColors["neutral"].b)
    end

    -- hp:
    local maxHP = UnitHealthMax("target");
    local currentHP = UnitHealth("target", true);
    if not maxHP then
        return frame:Hide();
    end

    frame.bar:SetMinMaxValues(0, maxHP, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.bar:SetValue(currentHP, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.hpText:SetText(AbbreviateNumbers(currentHP));
    frame.name:SetText(UnitName("target"))
    local function LevelText()
        if UnitLevel("target") == -1 then return "??" else return tostring(UnitLevel("target")) end
    end
    frame.level:SetText(LevelText())

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
    core:SetPixelSize(frame, core.width, core.barBgHeight);

    frame.bg = frame:CreateTexture();
    core:SetPixelPoint(frame.bg, "CENTER", frame, "CENTER", 0, 0);
    frame.bg:SetTexture(134532)
    frame.bg:SetColorTexture(0, 0, 0);
    core:SetPixelSize(frame.bg, core.width, core.barBgHeight);
    frame.bg:SetDrawLayer("OVERLAY", -1);

    frame.bar = CreateFrame("StatusBar", nil, frame);
    frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    core:InsetBarInBackground(frame.bar, frame.bg);
    frame.bar:SetStatusBarColor(1, 1, 1)

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

    frame.hpText = frame.bar:CreateFontString("PrimaryText");
    frame.hpText:SetDrawLayer("OVERLAY", 1);
    frame.hpText:SetPoint("LEFT", 0, 10);
    frame.hpText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

    frame.level = frame.bar:CreateFontString("PrimaryText");
    frame.level:SetDrawLayer("OVERLAY", 1);
    frame.level:SetPoint("RIGHT", 0, 10);
    frame.level:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

    frame.name = frame.bar:CreateFontString("PrimaryText");
    frame.name:SetDrawLayer("OVERLAY", 1);
    frame.name:SetPoint("CENTER", 0, 10);
    frame.name:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "target")
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "target")
    frame:RegisterUnitEvent("UNIT_HEALTH", "target")
    frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "target")
    frame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "target")
    frame:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "target")
    frame:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", "target")
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
