local _, core = ...

local frame = nil;
local getPetHappiness = rawget(_G, "GetPetHappiness");
-- pet happiness doesn't exist on retail, classic only
local hasPetHappiness = type(getPetHappiness) == "function";

local function updateHappiness()
    if not frame or not frame.happiness then return end;

    local hasPetUI, isHunterPet = HasPetUI();
    local happiness = hasPetUI and isHunterPet and getPetHappiness and getPetHappiness();
    if not happiness then
        frame.happiness:Hide();
        return;
    end

    frame.happiness:Show();
    if happiness == 1 then
        frame.happinessTexture:SetTexCoord(0.375, 0.5625, 0, 0.359375); -- unhappy
    elseif happiness == 2 then
        frame.happinessTexture:SetTexCoord(0.1875, 0.375, 0, 0.359375); -- content
    else
        frame.happinessTexture:SetTexCoord(0, 0.1875, 0, 0.359375);     -- happy
    end
end

local function updateBar()
    if not frame then return end;

    if not UnitExists("pet") then
        return;
    end

    frame.name:SetText(UnitName("pet"));
    updateHappiness();

    local maxHP = UnitHealthMax("pet");
    local currentHP = UnitHealth("pet", true);
    if not maxHP or (not issecretvalue(maxHP) and maxHP <= 0) then
        return;
    end

    frame.hpBar:SetMinMaxValues(0, maxHP, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.hpBar:SetValue(currentHP, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.hpText:SetText(AbbreviateNumbers(currentHP));

    local powerType = UnitPowerType("pet");
    if not powerType then
        frame.powerBar:Hide();
        frame.powerBg:Hide();
        frame.powerText:SetText("");
        return;
    end

    local maxPower = UnitPowerMax("pet", powerType);
    if not maxPower or (not issecretvalue(maxPower) and maxPower <= 0) then
        frame.powerBar:Hide();
        frame.powerBg:Hide();
        frame.powerText:SetText("");
        return;
    end

    frame.powerBar:Show();
    frame.powerBg:Show();

    local currentPower = UnitPower("pet", powerType);
    frame.powerBar:SetMinMaxValues(0, maxPower, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.powerBar:SetValue(currentPower, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.powerText:SetText(AbbreviateNumbers(currentPower));

    local color = core.resources.resourceColours[powerType];
    if color then
        frame.powerBar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);
    end
end

function core:CreatePetFrame(parent)
    frame = CreateFrame("Frame", "PetFrameContainer", parent, "SecureHandlerStateTemplate")
    -- same height as the HP bar frame so content centered within each lines up vertically
    core:SetPixelSize(frame, core:EvenPixels(core.width * 2 / 3), core.barBgHeight);

    frame.click = CreateFrame("Button", "PetFrameClick", frame, "SecureActionButtonTemplate")
    frame.click:SetAllPoints();
    frame.click:SetAttribute("unit", "pet")
    frame.click:SetAttribute("type1", "target")
    frame.click:SetAttribute("type2", "togglemenu")
    frame.click:RegisterForClicks("AnyUp", "AnyDown")

    local barWidth = core.width / 3 - 40;
    local FOCUS_GAP = 2;

    frame.hpBg = frame:CreateTexture();
    core:SetPixelPoint(frame.hpBg, "LEFT", frame, "LEFT", 0, 0);
    frame.hpBg:SetTexture(134532)
    frame.hpBg:SetColorTexture(0, 0, 0);
    core:SetPixelSize(frame.hpBg, barWidth, core.barBgHeight);
    frame.hpBg:SetDrawLayer("OVERLAY", -1);

    frame.hpBar = CreateFrame("StatusBar", nil, frame);
    frame.hpBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    core:InsetBarInBackground(frame.hpBar, frame.hpBg);
    frame.hpBar:SetStatusBarColor(200 / 255, 70 / 255, 80 / 255);

    frame.powerBg = frame:CreateTexture();
    core:SetPixelPoint(frame.powerBg, "LEFT", frame.hpBg, "RIGHT", FOCUS_GAP, 0);
    frame.powerBg:SetTexture(134532)
    frame.powerBg:SetColorTexture(0, 0, 0);
    core:SetPixelSize(frame.powerBg, barWidth, core.barBgHeight);
    frame.powerBg:SetDrawLayer("OVERLAY", -1);

    frame.powerBar = CreateFrame("StatusBar", nil, frame);
    frame.powerBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    core:InsetBarInBackground(frame.powerBar, frame.powerBg);

    frame.name = frame:CreateFontString("PetNameText")
    frame.name:SetDrawLayer("OVERLAY", 1);
    frame.name:SetPoint("BOTTOMRIGHT", frame.powerBg, "TOPRIGHT", 0, 0);
    frame.name:SetJustifyH("RIGHT");
    core:SetBarFont(frame.name, 8);

    frame.hpText = frame:CreateFontString("PetHPText");
    frame.hpText:SetDrawLayer("OVERLAY", 1);
    frame.hpText:SetPoint("BOTTOMLEFT", frame.hpBg, "TOPLEFT", 0, 0);
    frame.hpText:SetJustifyH("LEFT");
    core:SetBarFont(frame.hpText, 8);

    frame.powerText = frame:CreateFontString("PetPowerText");
    frame.powerText:SetDrawLayer("OVERLAY", 1);
    frame.powerText:SetPoint("BOTTOMLEFT", frame.powerBg, "TOPLEFT", 0, 0);
    frame.powerText:SetJustifyH("LEFT");
    core:SetBarFont(frame.powerText, 8);

    if hasPetHappiness then
        frame.happiness = CreateFrame("Frame", nil, frame);
        frame.happiness:SetSize(20, 19);
        frame.happiness:SetPoint("RIGHT", frame.hpBg, "LEFT", -2, core.labelAboveBar);

        frame.happinessTexture = frame.happiness:CreateTexture(nil, "BACKGROUND");
        frame.happinessTexture:SetAllPoints();
        frame.happinessTexture:SetTexture("Interface\\PetPaperDollFrame\\UI-PetHappiness");

        frame:RegisterEvent("UNIT_HAPPINESS")
    end

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

    frame:SetAttribute("unit", "pet")
    RegisterUnitWatch(frame, false)

    return frame;
end
