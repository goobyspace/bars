local _, core = ...

local frame = nil;

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

    local currentHP, maxHP = core:UpdateHPBarValues(frame, "targettarget");
    if not maxHP then
        return frame:Hide();
    end

    local percentHP = string.format("%.0f%%", UnitHealthPercent("targettarget", true, CurveConstants.ScaleTo100))
    frame.hpText:SetText(tostring(percentHP));
    frame.name:SetText(UnitName("targettarget"))
end

function core:CreateTargetTargetHPBar(parent)
    frame = core:CreateHPBarBase("TargetTargetHPBarContainer", parent, core.width / 3 - 2, core.barBgHeight,
        "SecureHandlerStateTemplate");

    frame.hpText = frame.bar:CreateFontString("PrimaryText");
    frame.hpText:SetDrawLayer("OVERLAY", 1);
    frame.hpText:SetPoint("LEFT", 0, core.labelBelowBar);
    core:SetBarFont(frame.hpText, 10)

    frame.name = frame.bar:CreateFontString("PrimaryText");
    frame.name:SetDrawLayer("OVERLAY", 1);
    frame.name:SetPoint("RIGHT", 0, core.labelBelowBar);
    frame.name:SetSize((core.width / 3 - 2) * 0.6, core.barBgHeight)
    core:SetBarFont(frame.name, 10)

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
    frame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "targettarget")
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
