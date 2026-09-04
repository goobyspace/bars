local _, core = ...

local frame = nil;
local predictedCostPercent = 0;

local function getResource()
    local playerClass = select(2, UnitClass("player"))


    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

    local resource = core.resources.primary[playerClass]

    -- Druid: form-based
    if playerClass == "DRUID" then
        local formID = core:GetShapeshiftFormKey()
        resource = resource and resource[formID or 0]
    end

    if type(resource) == "table" then
        return resource[specID]
    else
        return resource
    end
end

local function getResourceValue(resource)
    if not resource then return nil, nil end

    local current = UnitPower("player", resource)
    local max = UnitPowerMax("player", resource)
    if max <= 0 then return nil end

    return max, current
end

-- tracks what % of the resource (static spell data, never a live/secret value) the current cast/channel will consume
local function updatePredictedCost(resource, isCasting)
    local costPercent = 0;
    if isCasting and resource then
        local spellID = select(9, UnitCastingInfo("player")) or select(9, UnitChannelInfo("player"));
        local costTable = spellID and C_Spell.GetSpellPowerCost(spellID) or {};
        for _, costInfo in pairs(costTable) do
            if costInfo.type == resource then
                costPercent = costInfo.costPercent or 0;
                break;
            end
        end
    end
    predictedCostPercent = costPercent;
end

local function updateBar()
    if not frame or not frame:IsShown() then return end;

    local resource = getResource();
    if not resource then return end;

    if frame.manaTicker then
        frame.manaTicker:SetActive(resource == Enum.PowerType.Mana);
    end

    local max, current = getResourceValue(resource);
    if not max then
        return frame:Hide();
    end
    if not current then current = 0; end

    frame.bar:SetMinMaxValues(0, max, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.bar:SetValue(current, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.text:SetText(AbbreviateNumbers(current));

    -- darken exactly predictedCostPercent of the resource, ending flush with frame.bar's current fill.
    -- costPercent is static spell data (never secret), so this width math is always safe -- no need to
    -- touch the (possibly secret) current/max power values at all.
    if predictedCostPercent > 0 then
        frame.costPredictionBar:SetWidth(core.width * (predictedCostPercent / 100));
        frame.costPredictionBar:Show();
    else
        frame.costPredictionBar:Hide();
    end
end

local function updateColour()
    -- this is always a bar so we only need to worry about colour
    if not frame or not frame:IsShown() then return end;

    local resource = getResource();
    if not resource then return end;

    local color = core.resources.resourceColours[resource];

    frame.bar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255)
end

function core:CreatePrimaryBar(parent)
    frame = CreateFrame("Frame", "PrimaryResourceContainer", parent)
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

    frame.text = frame.bar:CreateFontString("PrimaryText");
    frame.text:SetDrawLayer("OVERLAY", 1);
    frame.text:SetPoint("CENTER", 0, 0);
    core:SetBarFont(frame.text, 14)

    if core.CreateManaTicker then
        frame.manaTicker = core:CreateManaTicker(frame.bar);
    end

    -- darkens exactly predictedCostPercent of the resource, ending flush with frame.bar's current fill.
    -- A plain texture sized directly from costPercent (static spell data, never secret) -- this never
    -- needs to touch the (possibly secret) current/max power values or rely on any StatusBar fill style.
    frame.costPredictionBar = frame.bar:CreateTexture(nil, "ARTWORK", nil, 1);
    frame.costPredictionBar:SetColorTexture(0, 0, 0, 0.6);
    frame.costPredictionBar:SetPoint("TOPRIGHT", frame.bar:GetStatusBarTexture(), "TOPRIGHT", 0, 0);
    frame.costPredictionBar:SetPoint("BOTTOMRIGHT", frame.bar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0);
    frame.costPredictionBar:Hide();

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    frame:RegisterEvent("PET_BATTLE_OPENING_START")
    frame:RegisterEvent("PET_BATTLE_CLOSE")
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")

    local playerClass = select(2, UnitClass("player"))

    if playerClass == "DRUID" then
        frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    end

    frame:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_ENTERING_WORLD"
            or event == "UPDATE_SHAPESHIFT_FORM"
            or (event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit == "player") then
            updateColour();
        end
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED"
            or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            updatePredictedCost(getResource(), event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START");
        end
        updateBar();
    end)

    return frame;
end
