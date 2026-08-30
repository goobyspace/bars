local _, core = ...

local frame;

local TEACHINGS_OF_THE_MONASTERY = 202090;
local TEACHINGS_MAX_STACKS = 4;
local ENRAGE = 184362;

local function getResource()
    local playerClass = select(2, UnitClass("player"))
    local resourceTable = core.resources.secondary;

    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

    local resource = resourceTable[playerClass];

    -- Druid: form-based
    if playerClass == "DRUID" then
        local formID = GetShapeshiftFormID()
        resource = resource and resource[formID or 0]
    end

    if type(resource) == "table" then
        return resource[specID]
    else
        return resource
    end
end

local nextEssenceTick = nil;
local lastEssence = nil;
local startTime = nil;

-- this is only for basic power bars that can be handled in combat
-- check below for stuff like teachings tracker, which we have to let blizz handle
local function updateBar()
    local resource = getResource()
    if not resource then return end;

    if resource == Enum.PowerType.Essence then
        for i = 1, 6 do
            -- hide just incase
            frame['bar' .. i]:Hide();
            frame['bg' .. i]:Hide();
        end

        local current = UnitPower("player", resource);
        local max = UnitPowerMax("player", resource);
        local regenRate = GetPowerRegenForPowerType(resource);

        local gap = 4;
        local barWidth = core.width / max - gap;
        local offset = gap + (gap / max);

        if issecretvalue(regenRate) then
            regenRate = 0.2;
        end

        lastEssence = lastEssence or current;

        local tickDuration = 5 / (5 / (1 / regenRate))
        local now = GetTime()

        -- If we gained an essence, reset timer
        if current > lastEssence then
            if current < max then
                startTime = now;
                nextEssenceTick = now + tickDuration
            else
                startTime = nil;
                nextEssenceTick = nil
            end
        end

        -- If missing essence and no timer, start it
        if current < max and not nextEssenceTick then
            startTime = now;
            nextEssenceTick = now + tickDuration
        end

        -- If full essence, hide timer
        if current >= max then
            startTime = nil;
            nextEssenceTick = nil
        end

        lastEssence = current

        local duration;
        if nextEssenceTick and startTime then
            duration = C_DurationUtil.CreateDuration();
            duration:SetTimeSpan(startTime, nextEssenceTick);
        end

        for i = 1, max do
            frame['container' .. i]:ClearAllPoints();
            frame['container' .. i]:SetSize(barWidth, 6);
            frame['container' .. i]:SetPoint("LEFT", frame, "LEFT", (i - 1) * (barWidth + offset), 0);

            frame["bg" .. i]:Show();
            frame["bg" .. i]:SetSize(barWidth, 6);

            local bar = frame["bar" .. i];
            bar:Show();
            bar:SetSize(barWidth - 2, 4);

            bar:SetMinMaxValues(0, 1)
            if i <= current then
                bar:SetValue(1, Enum.StatusBarInterpolation.ExponentialEaseOut);
            elseif i == current + 1 then
                bar:SetTimerDuration(duration, Enum.StatusBarInterpolation.ExponentialEaseOut);
            else
                bar:SetValue(0, Enum.StatusBarInterpolation.ExponentialEaseOut);
            end
        end
    end
end

local function updateColour()
    local resource = getResource()
    if not resource then return end;

    local color = core.resources.resourceColours[resource];

    if resource == Enum.PowerType.Essence then
        for i = 1, 6 do
            frame['bar' .. i]:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255)
        end
    end
end

-- 12.1 you create these auracontainers to track stuff like stacks in widgets
-- can only really be either an icon or a bar, and not multiple bars either
-- use textures to make fake segments in a progress bar if you need to
local function createAuraTracker(spellID, configureButton)
    local container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate");
    container:SetPoint("CENTER");
    container:SetSize(core.width, 6);
    container:SetUnit("player");

    container:AddAuraSlot("tracked", "HELPFUL", {
        candidateFilters = { includeSpellIDs = { [spellID] = true } },
        initializeFrame = configureButton,
    });

    return container;
end

local function createTrackerBar(button, colorKey, texture)
    texture = texture or "Interface/TargetingFrame/UI-StatusBar"
    button:SetSize(core.width - 2, 4);
    button:SetPoint("CENTER", frame, "CENTER");

    local bar = CreateFrame("StatusBar", nil, button);
    bar:SetStatusBarTexture(texture);
    bar:SetAllPoints(button);

    local color = core.resources.resourceColours[colorKey];
    bar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);

    return bar;
end

local trackerBuilders = {
    [Enum.PowerType.Essence] = function(tracker)
        -- with talents evoker max essence count can be 6 so we need 6 frames
        for i = 1, 6 do
            frame['container' .. i] = CreateFrame("Frame", nil, frame);

            frame['bg' .. i] = frame['container' .. i]:CreateTexture();
            local bg = frame['bg' .. i];
            bg:SetPoint("CENTER");
            bg:SetTexture(134532)
            bg:SetColorTexture(0, 0, 0);
            bg:SetSize(100, 6);
            bg:SetDrawLayer("OVERLAY", -1);

            frame['bar' .. i] = CreateFrame("StatusBar", nil, frame['container' .. i]);
            local bar = frame['bar' .. i];
            bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
            bar:SetPoint("CENTER");
            bar:SetSize(100, 4);

            bg:Hide();
            bar:Hide();

            table.insert(tracker.visuals, frame['container' .. i]);
        end
    end,

    ["TEACHINGS"] = function(tracker)
        local segmentWidth = (core.width - 2) / TEACHINGS_MAX_STACKS;

        for i = 1, TEACHINGS_MAX_STACKS do
            local bars = frame:CreateTexture(nil, "OVERLAY");
            bars:SetColorTexture(0, 0, 0);
            bars:SetSize(segmentWidth - 1, 6);
            bars:SetPoint("LEFT", frame, "LEFT", (i - 1) * (segmentWidth + 1), 0);
            table.insert(tracker.visuals, bars);
        end

        tracker.container = createAuraTracker(TEACHINGS_OF_THE_MONASTERY, function(button)
            local bar = createTrackerBar(button, "TEACHINGS",
                "Interface/Addons/Bars/assets/transparent four segment bar.png");

            button:SetApplicationBar(bar, {
                maxApplications = TEACHINGS_MAX_STACKS,
                interpolation = Enum.StatusBarInterpolation.ExponentialEaseOut,
            });
        end);
    end,

    ["ENRAGE"] = function(tracker)
        local bg = frame:CreateTexture();
        bg:SetPoint("CENTER");
        bg:SetTexture(134532)
        bg:SetColorTexture(0, 0, 0);
        bg:SetSize(core.width, 6);
        bg:SetDrawLayer("OVERLAY", -1);
        table.insert(tracker.visuals, bg);

        local color = core.resources.resourceColours["ENRAGE"];
        local track = frame:CreateTexture(nil, "OVERLAY");
        track:SetColorTexture(color.r / 255, color.g / 255, color.b / 255, 0.2);
        track:SetSize(core.width - 2, 4);
        track:SetPoint("CENTER");
        table.insert(tracker.visuals, track);

        tracker.container = createAuraTracker(ENRAGE, function(button)
            local bar = createTrackerBar(button, "ENRAGE");

            button:SetDurationBar(bar, {
                interpolation = Enum.StatusBarInterpolation.ExponentialEaseOut,
                direction = Enum.StatusBarTimerDirection.RemainingTime,
            });
        end);
    end,
};

-- tldr if you switch spec and a tracker isnt relevant anymore hide it
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

function core:CreateSecondaryBar(parent)
    frame = CreateFrame("Frame", "PrimaryResourceContainer", parent)
    frame:SetSize(core.width, 6);

    local playerClass = select(2, UnitClass("player"))

    frame.trackers = {};

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterUnitEvent("UNIT_AURA", "player")
    frame:RegisterUnitEvent("UNIT_POWER_POINT_CHARGE", "player")
    frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    frame:RegisterEvent("PET_BATTLE_OPENING_START")
    frame:RegisterEvent("PET_BATTLE_CLOSE")

    if playerClass == "DRUID" then
        frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    end

    local hidden = true;

    function frame:SetHidden(hidden)
    end

    frame:SetScript("OnEvent", function(_, event, ...)
        local unit = ...;
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
