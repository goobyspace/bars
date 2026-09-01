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

    local isPlayer = UnitIsPlayer("targettarget")
    local threat = UnitThreatSituation("player", "targettarget")
    if isPlayer then
        local _, name, _ = UnitClass("targettarget");
        local color = C_ClassColor.GetClassColor(name)
        local barTexture = frame.bar:GetStatusBarTexture()
        if (barTexture) then
            barTexture:SetVertexColor(color:GetRGB())
        end
    elseif threat ~= nil or UnitIsEnemy("player", "targettarget") then
        frame.bar:SetStatusBarColor(core.ClassColors["hostile"].r, core.ClassColors["hostile"].g,
            core.ClassColors["hostile"].b)
    elseif UnitIsFriend("player", "targettarget") then
        frame.bar:SetStatusBarColor(core.ClassColors["friendly"].r, core.ClassColors["friendly"].g,
            core.ClassColors["friendly"].b)
    else
        frame.bar:SetStatusBarColor(core.ClassColors["neutral"].r, core.ClassColors["neutral"].g,
            core.ClassColors["neutral"].b)
    end

    -- hp:
    local maxHP = UnitHealthMax("targettarget");
    local currentHP = UnitHealth("targettarget", true);
    local percentHP = string.format("%.0f%%", UnitHealthPercent("targettarget", true, CurveConstants.ScaleTo100))
    if not maxHP then
        return frame:Hide();
    end

    frame.bar:SetMinMaxValues(0, maxHP, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.bar:SetValue(currentHP, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.hpText:SetText(tostring(percentHP));
    frame.name:SetText(UnitName("targettarget"))

    -- healing absorb:
    local absorb = UnitGetTotalAbsorbs("targettarget") or 0;
    if frame.absorbBar:IsShown() then
        frame.absorbBar:SetMinMaxValues(0, select(2, frame.bar:GetMinMaxValues()),
            Enum.StatusBarInterpolation.ExponentialEaseOut)
        frame.absorbBar:SetValue(absorb,
            Enum.StatusBarInterpolation.ExponentialEaseOut)
    end

    local healAbsorb = UnitGetTotalHealAbsorbs("targettarget") or 0;
    if frame.healAbsorbBar:IsShown() then
        frame.healAbsorbBar:SetMinMaxValues(0, select(2, frame.bar:GetMinMaxValues()),
            Enum.StatusBarInterpolation.ExponentialEaseOut)
        frame.healAbsorbBar:SetValue(healAbsorb,
            Enum.StatusBarInterpolation.ExponentialEaseOut)
    end
end

function core:CreateTargetTargetHPBar(parent)
    frame = CreateFrame("Frame", "TargetTargetHPBarContainer", parent, "SecureHandlerStateTemplate")
    frame:SetSize(core.width, 4);

    frame.bg = frame:CreateTexture();
    frame.bg:SetPoint("CENTER");
    frame.bg:SetTexture(134532)
    frame.bg:SetColorTexture(0, 0, 0);
    frame.bg:SetSize(core.width / 3, 4);
    frame.bg:SetDrawLayer("OVERLAY", -1);

    frame.bar = CreateFrame("StatusBar", nil, frame);
    frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    frame.bar:SetPoint("CENTER");
    frame.bar:SetSize(core.width / 3 - 2, 2);
    frame.bar:SetStatusBarColor(1, 1, 1)

    frame.absorbBar = CreateFrame("StatusBar", nil, frame.bar)
    frame.absorbBar:SetPoint("CENTER");
    frame.absorbBar:SetSize(core.width / 3 - 2, 2);
    frame.absorbBar:SetStatusBarTexture("Interface/Addons/Bars/assets/absorb.png")
    frame.absorbBar:SetFrameLevel(frame.bar:GetFrameLevel() + 1)
    frame.absorbBar:SetStatusBarColor(1, 1, 1, 0.7)

    frame.healAbsorbBar = CreateFrame("StatusBar", nil, frame.bar)
    frame.healAbsorbBar:SetPoint("CENTER");
    frame.healAbsorbBar:SetSize(core.width / 3 - 2, 2);
    frame.healAbsorbBar:SetStatusBarTexture("interface/RAIDFRAME/RaidFrameAbsorbOverlay")
    frame.healAbsorbBar:SetFrameLevel(frame.bar:GetFrameLevel() + 1)
    frame.healAbsorbBar:SetStatusBarColor(1, 1, 1, 0.7)

    frame.hpText = frame.bar:CreateFontString("PrimaryText");
    frame.hpText:SetDrawLayer("OVERLAY", 1);
    frame.hpText:SetPoint("CENTER", 0, 0);
    frame.hpText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

    frame.name = frame.bar:CreateFontString("PrimaryText");
    frame.name:SetDrawLayer("OVERLAY", 1);
    frame.name:SetPoint("RIGHT", 0, -6);
    frame.name:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

    frame.click = CreateFrame("Button", "TargetFrameClick", frame, "SecureActionButtonTemplate")
    frame.click:SetPoint("CENTER");
    frame.click:SetSize(core.width / 4, 12);
    frame.click:SetAttribute("unit", "targettarget")
    frame.click:SetAttribute("type1", "target")
    frame.click:SetAttribute("type2", "togglemenu")
    frame.click:RegisterForClicks("AnyUp", "AnyDown")

    -- frame.bg = frame:CreateTexture();
    -- frame.bg:SetPoint("CENTER");
    -- frame.bg:SetColorTexture(1, 0, 0, 0.1);
    -- frame.bg:SetSize(core.width/4, 12);

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "targettarget")
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "targettarget")
    frame:RegisterUnitEvent("UNIT_HEALTH", "targettarget")
    frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "targettarget")
    frame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "targettarget")
    frame:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "targettarget")
    frame:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", "targettarget")
    frame:RegisterUnitEvent("UNIT_TARGET", "target")
    frame:RegisterUnitEvent("PLAYER_TARGET_DIED")
    frame:RegisterEvent("PET_BATTLE_OPENING_START")
    frame:RegisterEvent("PET_BATTLE_CLOSE")

    frame:HookScript("OnEvent", function()
        UpdateBar();
    end)

    frame:HookScript("OnShow", function()
        UpdateBar()
    end)

    frame:SetAttribute("unit", "targettarget")
    RegisterUnitWatch(frame, false)

    return frame;
end
