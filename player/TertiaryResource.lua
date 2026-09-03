local _, core = ...

local frame;

local IMPROVED_WHIRLWIND = 85739;
local IMPROVED_WHIRLWIND_MAX_STACKS = 4;
local EBON_MIGHT = 395296;
local RENEWING_MIST = 115151;
local RENEWING_MIST_MAX_SEGMENTS = 4; -- highest realistic charge cap; actual max can change via talents

local CLASS_EVENTS = {
    ["DRUID"]   = { { "UPDATE_SHAPESHIFT_FORM" }, { "UNIT_POWER_FREQUENT", "player" }, { "UNIT_MAXPOWER", "player" } },
    ["EVOKER"]  = { { "UNIT_AURA", "player" } },
    ["MONK"]    = { { "SPELL_UPDATE_CHARGES" } },
    ["PRIEST"]  = { { "UNIT_POWER_FREQUENT", "player" }, { "UNIT_MAXPOWER", "player" } },
    ["SHAMAN"]  = { { "UNIT_POWER_FREQUENT", "player" }, { "UNIT_MAXPOWER", "player" } },
    ["WARRIOR"] = { { "UNIT_AURA", "player" } },
}

local function getResource()
    local playerClass = select(2, UnitClass("player"))
    local resourceTable = core.resources.tertiary;

    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

    local resource = resourceTable[playerClass];

    if playerClass == "DRUID" then
        local formID = core:GetShapeshiftFormKey()
        resource = resource and resource[formID]
    end

    if type(resource) == "table" then
        return resource[specID]
    else
        return resource
    end
end

local function updateManaBar(resource)
    local tracker = frame.trackers[resource];
    if not tracker or not tracker.bar then return end;

    local current = UnitPower("player", resource);
    local max = UnitPowerMax("player", resource);
    if not max or max <= 0 then
        return tracker.bar:Hide(), tracker.bg:Hide();
    end
    tracker.bg:Show();
    tracker.bar:Show();

    tracker.bar:SetMinMaxValues(0, max, Enum.StatusBarInterpolation.ExponentialEaseOut);
    tracker.bar:SetValue(current, Enum.StatusBarInterpolation.ExponentialEaseOut);
end

local function updateManaColour(resource)
    local tracker = frame.trackers[resource];
    if not tracker or not tracker.bar then return end;

    local color = core.resources.resourceColours[resource];
    tracker.bar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);
end

local function updateRenewingMistBar()
    local tracker = frame.trackers["RENEWING_MIST"];
    if getResource() ~= "RENEWING_MIST" then
        frame:SetScript("OnUpdate", nil);
        return
    end

    if not tracker or not tracker.bars then return end;

    local chargeInfo = C_Spell.GetSpellCharges(RENEWING_MIST);
    if not chargeInfo then return end;

    -- maxCharges is not secret, so it is safe to use for layout. currentCharges and
    -- the recharge duration object are only passed into status bar APIs below.
    local maxCharges = math.min(chargeInfo.maxCharges, #tracker.bars);
    if maxCharges <= 0 then
        frame:SetScript("OnUpdate", nil);
        return
    end

    frame:SetScript("OnUpdate", nil);

    local segmentGap = 2;
    local segmentBgWidth = ((core.width / 3) - (segmentGap * (maxCharges - 1))) / maxCharges;

    tracker.anchorBar:ClearAllPoints();
    core:SetPixelSize(tracker.anchorBar, maxCharges * (segmentBgWidth + segmentGap), core.barHeight);
    core:SetPixelPoint(tracker.anchorBar, "LEFT", frame, "LEFT", core.pixel, 0);
    tracker.anchorBar:SetMinMaxValues(0, maxCharges, Enum.StatusBarInterpolation.ExponentialEaseOut);
    tracker.anchorBar:SetValue(chargeInfo.currentCharges, Enum.StatusBarInterpolation.ExponentialEaseOut);
    tracker.anchorBar:Show();

    local rechargeDuration = C_Spell.GetSpellChargeDuration(RENEWING_MIST);
    if rechargeDuration then
        tracker.cooldownBar:ClearAllPoints();
        core:SetPixelSize(tracker.cooldownBar, segmentBgWidth - 2 * core.pixel, core.barHeight);
        tracker.cooldownBar:SetPoint("LEFT", tracker.anchorBar:GetStatusBarTexture(), "RIGHT");
        tracker.cooldownBar:SetTimerDuration(rechargeDuration, Enum.StatusBarInterpolation.ExponentialEaseOut,
            Enum.StatusBarTimerDirection.ElapsedTime);
        tracker.cooldownBar:Show();
    else
        tracker.cooldownBar:Hide();
    end

    for i, bar in ipairs(tracker.bars) do
        if i <= maxCharges then
            local bg = tracker.bgs[i];
            bg:ClearAllPoints();
            core:SetPixelSize(bg, segmentBgWidth, core.barBgHeight);
            core:SetPixelPoint(bg, "LEFT", frame, "LEFT", (i - 1) * (segmentBgWidth + segmentGap), 0);
            bg:Show();

            bar:ClearAllPoints();
            core:SetPixelSize(bar, segmentBgWidth - 2 * core.pixel, core.barHeight);
            core:SetPixelPoint(bar, "LEFT", frame, "LEFT", core.pixel + (i - 1) * (segmentBgWidth + segmentGap), 0);
            bar:SetMinMaxValues(i - 1, i, Enum.StatusBarInterpolation.ExponentialEaseOut);
            bar:SetValue(chargeInfo.currentCharges, Enum.StatusBarInterpolation.ExponentialEaseOut);
            bar:Show();
        else
            tracker.bgs[i]:Hide();
            bar:Hide();
        end
    end
end

local function updateBar()
    local resource = getResource();
    if not resource then return end;

    if resource == Enum.PowerType.Mana then
        updateManaBar(resource);
    elseif resource == "RENEWING_MIST" then
        updateRenewingMistBar();
    end
end

local function updateColour()
    local resource = getResource();
    if not resource then return end;

    if resource == Enum.PowerType.Mana then
        updateManaColour(resource);
    end
end

local function createAuraTracker(spellID, configureButton)
    local container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate");
    container:SetPoint("CENTER");
    core:SetPixelSize(container, core.width / 3, core.barBgHeight);
    container:SetUnit("player");

    container:AddAuraSlot("tracked", "HELPFUL", {
        candidateFilters = { includeSpellIDs = { [spellID] = true } },
        initializeFrame = configureButton,
    });

    return container;
end

local function createTrackerBar(button, colorKey, texture)
    texture = texture or "Interface/TargetingFrame/UI-StatusBar"
    core:SetPixelSize(button, core.width / 3 - 2 * core.pixel, core.barHeight);
    button:SetPoint("CENTER", frame, "CENTER");

    local bar = CreateFrame("StatusBar", nil, button);
    bar:SetStatusBarTexture(texture);
    bar:SetAllPoints(button);
    bar:SetMinMaxValues(0, 1);
    bar:SetValue(0);

    local color = core.resources.resourceColours[colorKey];
    bar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);

    return bar;
end

local trackerBuilders = {
    [Enum.PowerType.Mana] = function(tracker)
        tracker.bg = frame:CreateTexture();
        tracker.bg:SetPoint("CENTER");
        tracker.bg:SetTexture(134532)
        tracker.bg:SetColorTexture(0, 0, 0);
        core:SetPixelSize(tracker.bg, core.width / 3, core.barBgHeight);
        tracker.bg:SetDrawLayer("OVERLAY", -1);
        table.insert(tracker.visuals, tracker.bg);

        tracker.bar = CreateFrame("StatusBar", nil, frame);
        tracker.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
        tracker.bar:SetPoint("CENTER");
        core:SetPixelSize(tracker.bar, core.width / 3 - 2 * core.pixel, core.barHeight);
        table.insert(tracker.visuals, tracker.bar);
    end,

    ["WHIRLWIND"] = function(tracker)
        local segmentWidth = (core.width / 3 - 2 * core.pixel) / IMPROVED_WHIRLWIND_MAX_STACKS;
        for i = 1, 4 do
            local bars = frame:CreateTexture(nil, "OVERLAY");
            bars:SetColorTexture(0, 0, 0);
            core:SetPixelSize(bars, segmentWidth - core.pixel, core.barBgHeight);
            core:SetPixelPoint(bars, "LEFT", frame, "LEFT", (i - 1) * (segmentWidth + core.pixel), 0);
            table.insert(tracker.visuals, bars);
        end

        tracker.container = createAuraTracker(IMPROVED_WHIRLWIND, function(button)
            local bar = createTrackerBar(button, "WHIRLWIND", "Interface/Addons/Bars/assets/four segment bar small.png");

            button:SetApplicationBar(bar, {
                maxApplications = IMPROVED_WHIRLWIND_MAX_STACKS,
                interpolation = Enum.StatusBarInterpolation.ExponentialEaseOut,
            });
        end);
    end,

    ["EBON_MIGHT"] = function(tracker)
        local bg = frame:CreateTexture();
        bg:SetPoint("CENTER");
        bg:SetTexture(134532)
        bg:SetColorTexture(0, 0, 0);
        core:SetPixelSize(bg, core.width / 3, core.barBgHeight);
        bg:SetDrawLayer("OVERLAY", -1);
        table.insert(tracker.visuals, bg);

        tracker.container = createAuraTracker(EBON_MIGHT, function(button)
            local bar = createTrackerBar(button, "EBON_MIGHT");

            button:SetDurationBar(bar, {
                interpolation = Enum.StatusBarInterpolation.ExponentialEaseOut,
                direction = Enum.StatusBarTimerDirection.RemainingTime,
            });
        end);
    end,

    ["RENEWING_MIST"] = function(tracker)
        local color = core.resources.resourceColours["RENEWING_MIST"];

        -- Built up front for the highest realistic cap; updateRenewingMistBar shows/positions
        -- only as many bars as the real (talent-dependent) max charges calls for.
        tracker.bgs = {};
        tracker.bars = {};

        tracker.anchorBar = CreateFrame("StatusBar", nil, frame);
        tracker.anchorBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
        tracker.anchorBar:SetStatusBarColor(0, 0, 0, 0);
        tracker.anchorBar:SetAlpha(0);
        tracker.anchorBar:Hide();

        tracker.cooldownBar = CreateFrame("StatusBar", nil, frame);
        tracker.cooldownBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
        tracker.cooldownBar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);
        tracker.cooldownBar:SetMinMaxValues(0, 1);
        tracker.cooldownBar:Hide();

        table.insert(tracker.visuals, tracker.anchorBar);
        table.insert(tracker.visuals, tracker.cooldownBar);

        for i = 1, RENEWING_MIST_MAX_SEGMENTS do
            local bg = frame:CreateTexture();
            bg:SetTexture(134532)
            bg:SetColorTexture(0, 0, 0);
            bg:SetDrawLayer("OVERLAY", -1);
            bg:Hide();

            local bar = CreateFrame("StatusBar", nil, frame);
            bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
            bar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);
            bar:SetMinMaxValues(i - 1, i);
            bar:SetValue(0);
            bar:Hide();

            table.insert(tracker.bgs, bg);
            table.insert(tracker.visuals, bg);
            table.insert(tracker.bars, bar);
            table.insert(tracker.visuals, bar);
        end
    end,
};

-- tldr if you switch spec/form and a tracker isnt relevant anymore hide it
-- if a tracker is now relevant but we havent created it go make it otherwise show it
local function refreshTrackers()
    for _, tracker in pairs(frame.trackers) do
        if tracker.container then
            tracker.container:Hide();
        end
        for _, region in ipairs(tracker.visuals) do
            region:Hide();
        end
    end

    local resource = getResource();
    local build = trackerBuilders[resource];
    if not build then return end;

    local tracker = frame.trackers[resource];
    if not tracker then
        tracker = { visuals = {} };
        frame.trackers[resource] = tracker;
        build(tracker);
    end

    if tracker.container then
        tracker.container:Show();
    end
    for _, region in ipairs(tracker.visuals) do
        region:Show();
    end
end

function core:CreateTertiaryBar(parent)
    frame = CreateFrame("Frame", "TertiaryResourceContainer", parent)
    core:SetPixelSize(frame, core.width / 3, core.barBgHeight);

    frame.trackers = {};

    local playerClass = select(2, UnitClass("player"))

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    frame:RegisterEvent("PET_BATTLE_OPENING_START")
    frame:RegisterEvent("PET_BATTLE_CLOSE")
    -- talent changes can raise/lower a resource's max (eg. renewing mist charges) without a spec change
    frame:RegisterEvent("PLAYER_TALENT_UPDATE")
    frame:RegisterEvent("TRAIT_CONFIG_UPDATED")

    for _, event in ipairs(CLASS_EVENTS[playerClass] or {}) do
        core:SafeRegisterEvent(frame, event[1], event[2])
    end

    local hidden = true;

    function frame:SetHidden(hidden)
    end

    frame:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_ENTERING_WORLD"
            or event == "UPDATE_SHAPESHIFT_FORM"
            or (event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit == "player") then
            refreshTrackers();

            local resource = getResource();
            if resource then
                hidden = false;
                frame:SetHidden(false);
            else
                hidden = true;
                frame:SetHidden(true);
                return
            end;

            updateColour();
        end
        if hidden then return end;

        updateBar();
    end)

    return frame;
end
