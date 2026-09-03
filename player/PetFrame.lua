local _, core = ...

local frame = nil;
-- pet happiness doesn't exist on retail (removed in Cataclysm); GetPetHappiness won't even exist there
local hasPetHappiness = type(GetPetHappiness) == "function";

local function updateHappiness()
    if not frame or not frame.happiness then return end;

    local hasPetUI, isHunterPet = HasPetUI();
    local happiness = hasPetUI and isHunterPet and GetPetHappiness();
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
    frame:SetSize(core.width / 3, 27);

    frame.click = CreateFrame("Button", "PetFrameClick", frame, "SecureActionButtonTemplate")
    frame.click:SetPoint("CENTER");
    frame.click:SetSize(core.width / 3, 27);
    frame.click:SetAttribute("unit", "pet")
    frame.click:SetAttribute("type1", "target")
    frame.click:SetAttribute("type2", "togglemenu")
    frame.click:RegisterForClicks("AnyUp", "AnyDown")

    -- name + HP value share the top row
    frame.name = frame:CreateFontString("PetNameText")
    frame.name:SetDrawLayer("OVERLAY", 1);
    frame.name:SetPoint("TOPLEFT", 1, 0);
    frame.name:SetSize(core.width / 6, 9);
    frame.name:SetJustifyH("LEFT");
    frame.name:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE");

    frame.hpText = frame:CreateFontString("PetHPText");
    frame.hpText:SetDrawLayer("OVERLAY", 1);
    frame.hpText:SetPoint("TOPRIGHT", -1, 0);
    frame.hpText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE");

    frame.hpBg = frame:CreateTexture();
    frame.hpBg:SetPoint("TOPLEFT", 0, -10);
    frame.hpBg:SetTexture(134532)
    frame.hpBg:SetColorTexture(0, 0, 0);
    frame.hpBg:SetSize(core.width / 3, 4);
    frame.hpBg:SetDrawLayer("OVERLAY", -1);

    frame.hpBar = CreateFrame("StatusBar", nil, frame);
    frame.hpBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    frame.hpBar:SetPoint("TOPLEFT", 1, -11);
    frame.hpBar:SetSize(core.width / 3 - 2, 2);
    frame.hpBar:SetStatusBarColor(200 / 255, 70 / 255, 80 / 255);

    -- power value sits in the gap between the HP bar and the power bar
    frame.powerText = frame:CreateFontString("PetPowerText");
    frame.powerText:SetDrawLayer("OVERLAY", 1);
    frame.powerText:SetPoint("TOPRIGHT", -1, -15);
    frame.powerText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE");

    frame.powerBg = frame:CreateTexture();
    frame.powerBg:SetPoint("TOPLEFT", 0, -23);
    frame.powerBg:SetTexture(134532)
    frame.powerBg:SetColorTexture(0, 0, 0);
    frame.powerBg:SetSize(core.width / 3, 4);
    frame.powerBg:SetDrawLayer("OVERLAY", -1);

    frame.powerBar = CreateFrame("StatusBar", nil, frame);
    frame.powerBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    frame.powerBar:SetPoint("TOPLEFT", 1, -24);
    frame.powerBar:SetSize(core.width / 3 - 2, 2);

    if hasPetHappiness then
        frame.happiness = CreateFrame("Frame", nil, frame);
        frame.happiness:SetSize(20, 19);
        frame.happiness:SetPoint("TOPRIGHT", frame, "TOPLEFT", -4, 0);

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
