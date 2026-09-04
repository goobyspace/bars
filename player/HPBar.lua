local _, core = ...

local frame = nil;

local function UpdateBar()
    if not frame or not frame:IsShown() then return end;

    local currentHP, maxHP = core:UpdateHPBarValues(frame, "player");
    if not maxHP then
        frame:Hide();
        return;
    end

    frame.text:SetText(AbbreviateNumbers(currentHP));
end

function core:CreateHPBar(parent)
    frame = core:CreateHPBarBase("HPBarContainer", parent, core:EvenPixels(core.width / 3), core.barBgHeight);
    frame.bar:SetStatusBarColor(200 / 255, 70 / 255, 80 / 255)

    frame.text = frame.bar:CreateFontString("PrimaryText");
    frame.text:SetDrawLayer("OVERLAY", 1);
    frame.text:SetPoint("RIGHT", 0, core.labelAboveBar);
    core:SetBarFont(frame.text, 12)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    frame:RegisterUnitEvent("UNIT_HEALTH", "player")
    frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "player")
    frame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "player")
    frame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "player")
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
