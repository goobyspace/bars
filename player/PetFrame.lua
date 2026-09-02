local _, core = ...

local frame = nil;

local function updateBar()
    if not frame then return end;

    if not UnitExists("pet") then
        return frame:Hide();
    end
    frame:Show();

    local maxHP = UnitHealthMax("pet");
    local currentHP = UnitHealth("pet", true);
    if not maxHP or maxHP <= 0 then
        return frame:Hide();
    end

    frame.hpBar:SetMinMaxValues(0, maxHP, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.hpBar:SetValue(currentHP, Enum.StatusBarInterpolation.ExponentialEaseOut);

    local powerType = UnitPowerType("pet");
    if not powerType then
        frame.powerBar:Hide();
        frame.powerBg:Hide();
        return;
    end

    local maxPower = UnitPowerMax("pet", powerType);
    if not maxPower or maxPower <= 0 then
        frame.powerBar:Hide();
        frame.powerBg:Hide();
        return;
    end

    frame.powerBar:Show();
    frame.powerBg:Show();

    local currentPower = UnitPower("pet", powerType);
    frame.powerBar:SetMinMaxValues(0, maxPower, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.powerBar:SetValue(currentPower, Enum.StatusBarInterpolation.ExponentialEaseOut);

    local color = core.resources.resourceColours[powerType];
    if color then
        frame.powerBar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);
    end
end

function core:CreatePetFrame(parent)
    frame = CreateFrame("Frame", "PetFrameContainer", parent)
    frame:SetSize(core.width / 3, 6);

    frame.click = CreateFrame("Button", "PetFrameClick", frame, "SecureActionButtonTemplate")
    frame.click:SetPoint("CENTER");
    frame.click:SetSize(core.width / 3, 6);
    frame.click:SetAttribute("unit", "pet")
    frame.click:SetAttribute("type1", "target")
    frame.click:SetAttribute("type2", "togglemenu")
    frame.click:RegisterForClicks("AnyUp", "AnyDown")

    frame.hpBg = frame:CreateTexture();
    frame.hpBg:SetPoint("TOPLEFT");
    frame.hpBg:SetTexture(134532)
    frame.hpBg:SetColorTexture(0, 0, 0);
    frame.hpBg:SetSize(core.width / 3, 4);
    frame.hpBg:SetDrawLayer("OVERLAY", -1);

    frame.hpBar = CreateFrame("StatusBar", nil, frame);
    frame.hpBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    frame.hpBar:SetPoint("TOPLEFT", 1, -1);
    frame.hpBar:SetSize(core.width / 3 - 2, 2);
    frame.hpBar:SetStatusBarColor(200 / 255, 70 / 255, 80 / 255);

    frame.powerBg = frame:CreateTexture();
    frame.powerBg:SetPoint("TOPLEFT", 0, -4);
    frame.powerBg:SetTexture(134532)
    frame.powerBg:SetColorTexture(0, 0, 0);
    frame.powerBg:SetSize(core.width / 3, 2);
    frame.powerBg:SetDrawLayer("OVERLAY", -1);

    frame.powerBar = CreateFrame("StatusBar", nil, frame);
    frame.powerBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    frame.powerBar:SetPoint("TOPLEFT", 1, -5);
    frame.powerBar:SetSize(core.width / 3 - 2, 1);

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_PET")
    frame:RegisterUnitEvent("UNIT_HEALTH", "pet")
    frame:RegisterUnitEvent("UNIT_MAXHEALTH", "pet")
    frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "pet")
    frame:RegisterUnitEvent("UNIT_MAXPOWER", "pet")
    frame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "pet")
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    frame:RegisterEvent("PET_BATTLE_OPENING_START")
    frame:RegisterEvent("PET_BATTLE_CLOSE")

    frame:SetScript("OnEvent", function()
        updateBar();
    end)

    return frame;
end
