local _, core = ...

local frame;

local TEACHINGS_OF_THE_MONASTERY = 202090;
local TEACHINGS_MAX_STACKS = 4;
local ENRAGE = 184362;
local VENGEANCE_SOUL_FRAGMENTS = 203981;
local DEVOURER_SOUL_FRAGMENTS = 1225789;
local VENGEANCE_SOUL_FRAGMENTS_MAX_STACKS = 6;
local SOUL_GLUTTON = 1247534;
local SURRENDER_TO_THE_VOID = 1261423;
local DEVOURER_SOUL_FRAGMENTS_BASE_MAX = 50;
local DEVOURER_SOUL_GLUTTON_REDUCTION = 15;
local DEVOURER_SURRENDER_TO_THE_VOID_BONUS = 50;
local MAELSTROM_WEAPON = 344179;
local MAELSTROM_WEAPON_MAX_STACKS = 10;
local STAGGER_YELLOW_TRANSITION = 0.30;
local STAGGER_RED_TRANSITION = 0.60;
local MAX_COUNT_SEGMENTS = 8;

local COUNT_RESOURCES = {
    [Enum.PowerType.Runes] = true,
    [Enum.PowerType.ComboPoints] = true,
    [Enum.PowerType.HolyPower] = true,
    [Enum.PowerType.Chi] = true,
    [Enum.PowerType.SoulShards] = true,
}

local CLASS_EVENTS = {
    ["DEATHKNIGHT"] = { { "RUNE_POWER_UPDATE" }, { "UNIT_MAXPOWER", "player" } },
    ["DEMONHUNTER"] = { { "UNIT_AURA", "player" } },
    ["DRUID"]       = { { "UPDATE_SHAPESHIFT_FORM" }, { "UNIT_POWER_POINT_CHARGE", "player" }, { "UNIT_MAXPOWER", "player" } },
    ["EVOKER"]      = { { "UNIT_POWER_FREQUENT", "player" }, { "UNIT_MAXPOWER", "player" } },
    ["MONK"]        = { { "UNIT_AURA", "player" }, { "UNIT_POWER_POINT_CHARGE", "player" }, { "UNIT_MAXPOWER", "player" }, { "UNIT_HEALTH", "player" } },
    ["PALADIN"]     = { { "UNIT_POWER_UPDATE", "player" }, { "UNIT_POWER_POINT_CHARGE", "player" }, { "UNIT_MAXPOWER", "player" } },
    ["ROGUE"]       = { { "UNIT_POWER_POINT_CHARGE", "player" }, { "UNIT_MAXPOWER", "player" } },
    ["SHAMAN"]      = { { "UNIT_AURA", "player" } },
    ["WARLOCK"]     = { { "UNIT_POWER_POINT_CHARGE", "player" }, { "UNIT_MAXPOWER", "player" } },
    ["WARRIOR"]     = { { "PLAYER_REGEN_ENABLED" }, { "PLAYER_REGEN_DISABLED" }, { "UNIT_AURA", "player" } },
}

local function getResource()
    local playerClass = select(2, UnitClass("player"))
    local resourceTable = core.resources.secondary;

    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)

    local resource = resourceTable[playerClass];

    -- druid is form-based
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

local function updateEssenceBar(resource)
    for i = 1, 6 do
        -- hide just incase
        frame['bar' .. i]:Hide();
        frame['bg' .. i]:Hide();
    end

    do
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

-- discrete count resources with seperate little bars
-- all the combo points and those who have stolen valor
local function updateCountBar(resource)
    for i = 1, MAX_COUNT_SEGMENTS do
        frame['bar' .. i]:Hide();
        frame['bg' .. i]:Hide();
    end

    local current = UnitPower("player", resource) or 0;
    local max = UnitPowerMax("player", resource);

    print(current)
    print(max)

    if not max or max <= 0 then return end;

    local gap = 4;
    local barWidth = core.width / max - gap;
    local offset = gap + (gap / max);

    local nextStart, nextDuration;
    if resource == Enum.PowerType.Runes then
        for i = 1, 6 do
            local start, duration, ready = GetRuneCooldown(i)
            if not ready and start and duration and duration > 0 then
                if not nextStart or (start + duration) < (nextStart + nextDuration) then
                    nextStart, nextDuration = start, duration
                end
            end
        end
    end

    local duration;
    if nextStart and nextDuration then
        duration = C_DurationUtil.CreateDuration();
        duration:SetTimeSpan(nextStart, nextStart + nextDuration);
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
        bar:SetMinMaxValues(0, 1);

        if i <= current then
            bar:SetValue(1, Enum.StatusBarInterpolation.ExponentialEaseOut);
        elseif duration and i == current + 1 then
            bar:SetTimerDuration(duration, Enum.StatusBarInterpolation.ExponentialEaseOut);
        else
            bar:SetValue(0, Enum.StatusBarInterpolation.ExponentialEaseOut);
        end
    end
end

local function updateStaggerBar()
    local tracker = frame.trackers["STAGGER"];
    if not tracker or not tracker.bar then return end;

    local stagger = UnitStagger("player") or 0;
    local maxHealth = UnitHealthMax("player");
    if not maxHealth or maxHealth <= 0 then return end;

    local percent = stagger / maxHealth;
    local colors = core.resources.resourceColours["STAGGER"];
    local color;
    if percent >= STAGGER_RED_TRANSITION then
        color = colors.high;
    elseif percent >= STAGGER_YELLOW_TRANSITION then
        color = colors.medium;
    else
        color = colors.light;
    end

    tracker.bar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);
    tracker.bar:SetMinMaxValues(0, maxHealth, Enum.StatusBarInterpolation.ExponentialEaseOut);
    tracker.bar:SetValue(stagger, Enum.StatusBarInterpolation.ExponentialEaseOut);
end

-- Devourer's max fragments depends on talents/pvp talents currently active, unlike Vengeance's fixed 6
local function getDevourerSoulFragmentsMax()
    local max = DEVOURER_SOUL_FRAGMENTS_BASE_MAX;
    if C_SpellBook.IsSpellKnown(SOUL_GLUTTON) then
        max = max - DEVOURER_SOUL_GLUTTON_REDUCTION;
    end
    if C_SpellBook.IsSpellKnown(SURRENDER_TO_THE_VOID) then
        max = max + DEVOURER_SURRENDER_TO_THE_VOID_BONUS;
    end
    return max;
end

local function updateSoulFragmentsBar()
    local tracker = frame.trackers["SOUL_FRAGMENTS"];
    if not tracker or not tracker.bar then return end;

    local current = 0;
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(DEVOURER_SOUL_FRAGMENTS);
    if aura then
        current = aura.applications or 0;
    end

    tracker.bar:SetMinMaxValues(0, getDevourerSoulFragmentsMax());
    tracker.bar:SetValue(current, Enum.StatusBarInterpolation.ExponentialEaseOut);
end

local function updateBar()
    local resource = getResource()
    if not resource then return end;

    if resource == Enum.PowerType.Essence then
        updateEssenceBar(resource);
    elseif COUNT_RESOURCES[resource] then
        updateCountBar(resource);
    elseif resource == "STAGGER" then
        updateStaggerBar();
    elseif resource == "SOUL_FRAGMENTS" then
        updateSoulFragmentsBar();
    end
end

local function updateColour()
    local resource = getResource()
    if not resource then return end;

    if resource == Enum.PowerType.Essence then
        local color = core.resources.resourceColours[resource];
        for i = 1, 6 do
            frame['bar' .. i]:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255)
        end
    elseif COUNT_RESOURCES[resource] then
        -- UnitPowerMax can still report the previous spec's cap for a moment after
        -- PLAYER_SPECIALIZATION_CHANGED fires, so colour every possible segment instead
        local color = core.resources.resourceColours[resource];
        for i = 1, MAX_COUNT_SEGMENTS do
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
    bar:SetMinMaxValues(0, 1);
    bar:SetValue(0);

    local color = core.resources.resourceColours[colorKey];
    bar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);

    return bar;
end

local function buildCountSegments(tracker)
    for i = 1, MAX_COUNT_SEGMENTS do
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
end

local trackerBuilders = {
    [Enum.PowerType.Essence] = buildCountSegments,
    [Enum.PowerType.Runes] = buildCountSegments,
    [Enum.PowerType.ComboPoints] = buildCountSegments,
    [Enum.PowerType.HolyPower] = buildCountSegments,
    [Enum.PowerType.Chi] = buildCountSegments,
    [Enum.PowerType.SoulShards] = buildCountSegments,

    ["STAGGER"] = function(tracker)
        local bg = frame:CreateTexture();
        bg:SetPoint("CENTER");
        bg:SetTexture(134532)
        bg:SetColorTexture(0, 0, 0);
        bg:SetSize(core.width, 6);
        bg:SetDrawLayer("OVERLAY", -1);
        table.insert(tracker.visuals, bg);

        tracker.bar = CreateFrame("StatusBar", nil, frame);
        tracker.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
        tracker.bar:SetPoint("CENTER");
        tracker.bar:SetSize(core.width - 2, 4);
        table.insert(tracker.visuals, tracker.bar);
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

        tracker.container = createAuraTracker(ENRAGE, function(button)
            local bar = createTrackerBar(button, "ENRAGE");

            button:SetDurationBar(bar, {
                interpolation = Enum.StatusBarInterpolation.ExponentialEaseOut,
                direction = Enum.StatusBarTimerDirection.RemainingTime,
            });
        end);
    end,

    ["SOUL_FRAGMENTS_VENGEANCE"] = function(tracker)
        -- mirrors the 410px source texture (six 65px segments, five 4px gaps) scaled to the bar's actual width
        local scale = (core.width - 2) / 410;
        local segmentWidth = 65 * scale;
        local gapWidth = 4 * scale;
        for i = 1, VENGEANCE_SOUL_FRAGMENTS_MAX_STACKS do
            local bars = frame:CreateTexture(nil, "OVERLAY");
            bars:SetColorTexture(0, 0, 0);
            bars:SetSize(segmentWidth, 6);
            bars:SetPoint("LEFT", frame, "LEFT", (i - 1) * (segmentWidth + gapWidth), 0);
            table.insert(tracker.visuals, bars);
        end

        tracker.container = createAuraTracker(VENGEANCE_SOUL_FRAGMENTS, function(button)
            local bar = createTrackerBar(button, "SOUL_FRAGMENTS_VENGEANCE",
                "Interface/Addons/Bars/assets/transparent six segment bar.png");

            button:SetApplicationBar(bar, {
                maxApplications = VENGEANCE_SOUL_FRAGMENTS_MAX_STACKS,
                interpolation = Enum.StatusBarInterpolation.ExponentialEaseOut,
            });
        end);
    end,

    ["SOUL_FRAGMENTS"] = function(tracker)
        local bg = frame:CreateTexture();
        bg:SetPoint("CENTER");
        bg:SetTexture(134532)
        bg:SetColorTexture(0, 0, 0);
        bg:SetSize(core.width, 6);
        bg:SetDrawLayer("OVERLAY", -1);
        table.insert(tracker.visuals, bg);

        local button = CreateFrame("Frame", nil, frame);
        tracker.bar = createTrackerBar(button, "SOUL_FRAGMENTS");
        table.insert(tracker.visuals, button);
    end,

    ["MAELSTROM_WEAPON"] = function(tracker)
        local segmentWidth = (core.width - 2) / MAELSTROM_WEAPON_MAX_STACKS;
        for i = 1, MAELSTROM_WEAPON_MAX_STACKS do
            local bars = frame:CreateTexture(nil, "OVERLAY");
            bars:SetColorTexture(0, 0, 0);
            bars:SetSize(segmentWidth - 1, 6);
            bars:SetPoint("LEFT", frame, "LEFT", (i - 1) * (segmentWidth + 1), 0);
            table.insert(tracker.visuals, bars);
        end

        tracker.container = createAuraTracker(MAELSTROM_WEAPON, function(button)
            local bar = createTrackerBar(button, "MAELSTROM_WEAPON");

            button:SetApplicationBar(bar, {
                maxApplications = MAELSTROM_WEAPON_MAX_STACKS,
                interpolation = Enum.StatusBarInterpolation.ExponentialEaseOut,
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
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    frame:RegisterEvent("PET_BATTLE_OPENING_START")
    frame:RegisterEvent("PET_BATTLE_CLOSE")
    -- talent changes can raise/lower a resource's max (eg. chi charges) without a spec change
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
