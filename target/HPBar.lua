local _, core = ...

local frame = nil;

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

    local currentHP, maxHP = core:UpdateHPBarValues(frame, "target");
    if not maxHP then
        return frame:Hide();
    end

    frame.hpText:SetText(AbbreviateNumbers(currentHP));
    frame.name:SetText(UnitName("target"))
    local function LevelText()
        if UnitLevel("target") == -1 then return "??" else return tostring(UnitLevel("target")) end
    end
    frame.level:SetText(LevelText())
end

function core:CreateTargetHPBar(parent)
    frame = core:CreateHPBarBase("TargetHPBarContainer", parent, core.width, core.barBgHeight);

    frame.hpText = frame.bar:CreateFontString("PrimaryText");
    frame.hpText:SetDrawLayer("OVERLAY", 1);
    frame.hpText:SetPoint("LEFT", 0, core.labelAboveBar);
    core:SetBarFont(frame.hpText, 12)

    frame.level = frame.bar:CreateFontString("PrimaryText");
    frame.level:SetDrawLayer("OVERLAY", 1);
    frame.level:SetPoint("RIGHT", 0, core.labelAboveBar);
    core:SetBarFont(frame.level, 12)

    frame.name = frame.bar:CreateFontString("PrimaryText");
    frame.name:SetDrawLayer("OVERLAY", 1);
    frame.name:SetPoint("CENTER", 0, core.labelAboveBar);
    core:SetBarFont(frame.name, 12)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "target")
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "target")
    frame:RegisterUnitEvent("UNIT_HEALTH", "target")
    frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "target")
    frame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "target")
    frame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "target")
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
