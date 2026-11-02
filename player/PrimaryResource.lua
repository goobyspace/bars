local _, core = ...;
local colours = core.colours;

local frame = nil;
local predictedCostPercent = 0;
local predictedCostFlat = 0;
local predictedResource = nil;
local spentCostPercent = 0;
local spentCostFlat = 0;
local spentResource = nil;

local function clearPredictedCost()
    predictedCostPercent = 0;
    predictedCostFlat = 0;
    predictedResource = nil;
    if frame then
        frame.costPredictionBar:Hide();
    end;
end;

local function clearSpentCost()
    spentCostPercent = 0;
    spentCostFlat = 0;
    spentResource = nil;
    if frame then
        frame.spentCostFade:Stop();
        frame.spentCostBar:SetAlpha(1);
        frame.spentCostBar:Hide();
    end;
end;

local function clearAllCosts()
    clearPredictedCost();
    clearSpentCost();
end;

local function getResource()
    local playerClass = select(2, UnitClass("player"));


    local spec = C_SpecializationInfo.GetSpecialization();
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec);

    local resource = core.resources.primary[playerClass];

    if playerClass == "DRUID" then
        local formID = core:GetShapeshiftFormKey();
        resource = resource and resource[formID or 0];
    end;

    if type(resource) == "table" then
        return resource[specID];
    else
        return resource;
    end;
end;

local function getResourceValue(resource)
    if not resource then return nil, nil; end;

    local current = UnitPower("player", resource);
    local max = UnitPowerMax("player", resource);
    if max == nil or (not issecretvalue(max) and max <= 0) then return nil; end;

    return max, current;
end;

local function getSpellCost(resource, spellID)
    local costPercent, flatCost = 0, 0;
    if resource and spellID and not issecretvalue(spellID) then
        local costTable = spellID and C_Spell.GetSpellPowerCost(spellID) or {};
        for _, costInfo in pairs(costTable) do
            if costInfo.type == resource then
                costPercent = costInfo.costPercent or 0;
                flatCost = costInfo.cost or 0;
                break;
            end;
        end;
    end;
    return costPercent, flatCost;
end;

-- retail usually gives us a percentage but classic gives us a flat cost
local function getCostFraction(costPercent, flatCost, max)
    -- era: costPercent is relative to base mana, not max mana, so use the flat cost
    if core.isClassicEra then
        if core:IsSafePositiveNumber(flatCost) and core:IsSafePositiveNumber(max) then
            return flatCost / max;
        end;
    elseif core:IsSafePositiveNumber(costPercent) then
        return costPercent / 100;
    elseif core:IsSafePositiveNumber(flatCost) and core:IsSafePositiveNumber(max) then
        return flatCost / max;
    end;
    return 0;
end;

local function updatePredictedCost(resource, isCasting)
    clearPredictedCost();
    local spellID;
    if isCasting then
        spellID = select(9, UnitCastingInfo("player")) or select(9, UnitChannelInfo("player"));
    end;
    local costPercent, flatCost = getSpellCost(resource, spellID);
    predictedCostPercent = costPercent;
    predictedCostFlat = flatCost;
    predictedResource = resource;
end;

local function updateBar()
    if not frame or not frame:IsShown() then return; end;

    local resource = getResource();
    if not resource then return; end;

    if predictedResource and predictedResource ~= resource then
        clearPredictedCost();
    end;
    if spentResource and spentResource ~= resource then
        clearSpentCost();
    end;

    if frame.resourceTicker then
        local tickResource = resource == Enum.PowerType.Mana or resource == Enum.PowerType.Energy;
        frame.resourceTicker:SetActive(tickResource and resource or nil);
    end;

    local max, current = getResourceValue(resource);
    if not max then
        return frame:Hide();
    end;
    if not current then current = 0; end;

    frame.bar:SetMinMaxValues(0, max, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.bar:SetValue(current, Enum.StatusBarInterpolation.ExponentialEaseOut);
    frame.costAnchor:SetMinMaxValues(0, max);
    frame.costAnchor:SetValue(current);
    frame.text:SetText(AbbreviateNumbers(current));

    local predictedFraction = getCostFraction(predictedCostPercent, predictedCostFlat, max);
    if predictedFraction > 0 then
        frame.costPredictionBar:SetWidth(core:EvenPixels(frame.bar:GetWidth() * math.min(1, predictedFraction)));
        frame.costPredictionBar:Show();
    else
        frame.costPredictionBar:Hide();
    end;

    -- keep the spent bar frozen while it fades out
    if frame.spentCostFade:IsPlaying() then return; end;
    local spentFraction = getCostFraction(spentCostPercent, spentCostFlat, max);
    if spentFraction > 0 then
        local colour = core.resources.resourceColours[resource];
        local config = core.resourceCostHighlightConfig;
        frame.spentCostBar:SetColorTexture(
            colour.r / 255 * (1 - config.brighten) + config.brighten,
            colour.g / 255 * (1 - config.brighten) + config.brighten,
            colour.b / 255 * (1 - config.brighten) + config.brighten, config.alpha);
        frame.spentCostBar:SetWidth(core:EvenPixels(frame.bar:GetWidth() * math.min(1, spentFraction)));
        frame.spentCostBar:Show();
    else
        frame.spentCostBar:Hide();
    end;
end;

local function highlightSpentCost(spellID)
    if not frame or not frame:IsShown() then return; end;

    local resource = getResource();
    local duration = core.resourceCostHighlightConfig.duration;
    if not resource or duration <= 0 then return; end;

    local costPercent, flatCost = getSpellCost(resource, spellID);
    if not core:IsSafePositiveNumber(costPercent) and not core:IsSafePositiveNumber(flatCost) then return; end;

    clearSpentCost();
    spentCostPercent = costPercent;
    spentCostFlat = flatCost;
    spentResource = resource;
    frame.spentCostFadeAlpha:SetDuration(duration);
    updateBar();
    frame.spentCostFade:Play();
end;

local function updateColour()
    if not frame or not frame:IsShown() then return; end;

    local resource = getResource();
    if not resource then return; end;

    local color = core.resources.resourceColours[resource];

    frame.bar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);
end;

function core:CreatePrimaryBar(parent)
    frame = core:CreateSimpleStatusBar("PrimaryResourceContainer", parent, core.width, core.barBgHeight, {
        includeText = true,
        fontSize = 14,
    });

    if core.CreateResourceTicker then
        frame.resourceTicker = core:CreateResourceTicker(frame.bar);
    end;

    local costWindow = CreateFrame("Frame", nil, frame.bar);
    costWindow:SetAllPoints(frame.bar);
    costWindow:SetClipsChildren(true);

    frame.costAnchor = CreateFrame("StatusBar", nil, costWindow);
    frame.costAnchor:SetAllPoints(frame.bar);
    frame.costAnchor:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");
    frame.costAnchor:SetStatusBarColor(0, 0, 0, 0);

    frame.costPredictionBar = costWindow:CreateTexture(nil, "OVERLAY", nil, 1);
    frame.costPredictionBar:SetColorTexture(colours.blackCostPrediction.r, colours.blackCostPrediction.g,
        colours.blackCostPrediction.b, colours.blackCostPrediction.a);
    frame.costPredictionBar:SetPoint("TOPRIGHT", frame.bar:GetStatusBarTexture(), "TOPRIGHT", 0, 0);
    frame.costPredictionBar:SetPoint("BOTTOMRIGHT", frame.bar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0);
    frame.costPredictionBar:Hide();

    frame.spentCostBar = costWindow:CreateTexture(nil, "OVERLAY", nil, 1);
    frame.spentCostBar:SetPoint("TOPLEFT", frame.costAnchor:GetStatusBarTexture(), "TOPRIGHT", 0, 0);
    frame.spentCostBar:SetPoint("BOTTOMLEFT", frame.costAnchor:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0);
    frame.spentCostBar:Hide();
    frame.spentCostFade = frame.spentCostBar:CreateAnimationGroup();
    frame.spentCostFadeAlpha = frame.spentCostFade:CreateAnimation("Alpha");
    frame.spentCostFadeAlpha:SetFromAlpha(core.resourceCostHighlightConfig.fromAlpha);
    frame.spentCostFadeAlpha:SetToAlpha(core.resourceCostHighlightConfig.toAlpha);
    frame.spentCostFade:SetScript("OnFinished", clearSpentCost);
    frame:HookScript("OnHide", clearAllCosts);

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player");
    frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player");
    frame:RegisterUnitEvent("UNIT_MAXPOWER", "player");
    frame:RegisterEvent("PET_BATTLE_OPENING_START");
    frame:RegisterEvent("PET_BATTLE_CLOSE");
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player");
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player");
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player");

    local playerClass = select(2, UnitClass("player"));

    if playerClass == "DRUID" then
        frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM");
    end;

    frame:SetScript("OnEvent", function(_, event, unit, _, spellID)
        if event == "PLAYER_ENTERING_WORLD"
            or event == "UPDATE_SHAPESHIFT_FORM"
            or (event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit == "player") then
            clearAllCosts();
            updateColour();
        end;
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            highlightSpentCost(spellID);
        end;
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED"
            or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            updatePredictedCost(getResource(), event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START");
        end;
        updateBar();
    end);

    return frame;
end;
