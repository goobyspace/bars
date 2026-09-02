local _, core = ...

local frame;

local IMPROVED_WHIRLWIND = 85739;
local IMPROVED_WHIRLWIND_MAX_STACKS = 4;
local EBON_MIGHT = 395152;
local RENEWING_MIST = 115151;

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
        local formID = GetShapeshiftFormID() or 0
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
    if not tracker or not tracker.bar then return end;

    local chargeInfo = C_Spell.GetSpellCharges(RENEWING_MIST);
    if not chargeInfo then return end;

    tracker.bar:SetMinMaxValues(0, chargeInfo.maxCharges, Enum.StatusBarInterpolation.ExponentialEaseOut);
    tracker.bar:SetValue(chargeInfo.currentCharges, Enum.StatusBarInterpolation.ExponentialEaseOut);
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
    container:SetSize(core.width / 3, 6);
    container:SetUnit("player");

    container:AddAuraSlot("tracked", "HELPFUL", {
        candidateFilters = { includeSpellIDs = { [spellID] = true } },
        initializeFrame = configureButton,
    });

    return container;
end

local function createTrackerBar(button, colorKey, texture)
    texture = texture or "Interface/TargetingFrame/UI-StatusBar"
    button:SetSize(core.width / 3 - 2, 4);
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
        tracker.bg:SetSize(core.width / 3, 6);
        tracker.bg:SetDrawLayer("OVERLAY", -1);
        table.insert(tracker.visuals, tracker.bg);

        tracker.bar = CreateFrame("StatusBar", nil, frame);
        tracker.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
        tracker.bar:SetPoint("CENTER");
        tracker.bar:SetSize(core.width / 3 - 2, 4);
        table.insert(tracker.visuals, tracker.bar);
    end,

    ["WHIRLWIND"] = function(tracker)
        local segmentWidth = (core.width / 3 - 2) / IMPROVED_WHIRLWIND_MAX_STACKS;
        for i = 1, 4 do
            local bars = frame:CreateTexture(nil, "OVERLAY");
            bars:SetColorTexture(0, 0, 0);
            bars:SetSize(segmentWidth - 1, 6);
            bars:SetPoint("LEFT", frame, "LEFT", (i - 1) * (segmentWidth + 1), 0);
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
        bg:SetSize(core.width / 3, 6);
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
        local segmentWidth = core.width / 9;
        -- never secret
        local charges = C_Spell.GetSpellCharges(RENEWING_MIST)
        for i = 1, charges.maxCharges do
            local bars = frame:CreateTexture(nil, "OVERLAY");
            bars:SetColorTexture(0, 0, 0);
            bars:SetSize(segmentWidth - 1, 6);
            bars:SetPoint("LEFT", frame, "LEFT", (i - 1) * (segmentWidth + 1), 0);
            table.insert(tracker.visuals, bars);
        end

        table.insert(tracker.visuals, tracker.bg);

        tracker.bar = CreateFrame("StatusBar", nil, frame);
        tracker.bar:SetStatusBarTexture("Interface/Addons/Bars/assets/three segment bar small.png");
        tracker.bar:SetPoint("CENTER");
        tracker.bar:SetSize(core.width / 3 - 2, 4);
        tracker.bar:SetMinMaxValues(0, 1);
        tracker.bar:SetValue(0);
        local color = core.resources.resourceColours["RENEWING_MIST"];
        tracker.bar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);
        table.insert(tracker.visuals, tracker.bar);
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
    frame:SetSize(core.width / 3, 6);

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
        if event[2] then
            frame:RegisterUnitEvent(event[1], event[2])
        else
            frame:RegisterEvent(event[1])
        end
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
