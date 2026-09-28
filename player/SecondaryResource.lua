local _, core = ...;
local colours = core.colours;

local frame = nil;
local resourceData = core.resourceData.secondary;

local countResources = {
    [Enum.PowerType.Runes] = true,
    [Enum.PowerType.ComboPoints] = true,
    [Enum.PowerType.HolyPower] = true,
    [Enum.PowerType.Chi] = true,
    [Enum.PowerType.SoulShards] = true,
};

local classEvents = {
    ["DEATHKNIGHT"] = { { "RUNE_POWER_UPDATE" }, { "UNIT_POWER_UPDATE", "player" }, { "UNIT_MAXPOWER", "player" } },
    ["DEMONHUNTER"] = { { "UNIT_AURA", "player" } },
    ["DRUID"]       = { { "UPDATE_SHAPESHIFT_FORM" }, { "UNIT_POWER_UPDATE", "player" }, { "UNIT_POWER_POINT_CHARGE", "player" }, { "UNIT_MAXPOWER", "player" } },
    ["EVOKER"]      = { { "UNIT_POWER_FREQUENT", "player" }, { "UNIT_MAXPOWER", "player" } },
    ["MONK"]        = { { "UNIT_AURA", "player" }, { "UNIT_POWER_UPDATE", "player" }, { "UNIT_POWER_POINT_CHARGE", "player" }, { "UNIT_MAXPOWER", "player" }, { "UNIT_HEALTH", "player" } },
    ["PALADIN"]     = { { "UNIT_POWER_UPDATE", "player" }, { "UNIT_POWER_POINT_CHARGE", "player" }, { "UNIT_MAXPOWER", "player" } },
    ["ROGUE"]       = { { "UNIT_POWER_UPDATE", "player" }, { "UNIT_POWER_POINT_CHARGE", "player" }, { "UNIT_MAXPOWER", "player" } },
    ["SHAMAN"]      = { { "UNIT_AURA", "player" } },
    ["WARLOCK"]     = { { "UNIT_POWER_UPDATE", "player" }, { "UNIT_POWER_POINT_CHARGE", "player" }, { "UNIT_MAXPOWER", "player" } },
    ["WARRIOR"]     = { { "PLAYER_REGEN_ENABLED" }, { "PLAYER_REGEN_DISABLED" }, { "UNIT_AURA", "player" } },
};

local function getResource()
    local playerClass = select(2, UnitClass("player"));
    local resourceTable = core.resources.secondary;

    local spec = C_SpecializationInfo.GetSpecialization();
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec);

    local resource = resourceTable[playerClass];

    if playerClass == "DRUID" then
        local formID = core:GetShapeshiftFormKey();
        if core.isForever and (formID == 0 or formID == "MOONKIN")
            and C_SpellBook.IsSpellKnown(resourceData.ECLIPSE.spellID) then
            return "ECLIPSE";
        end;
        resource = resource and resource[formID or 0];
    end;

    if type(resource) == "table" then
        return resource[specID];
    else
        return resource;
    end;
end;

local nextEssenceTick = nil;
local lastEssence = nil;
local startTime = nil;

local function updateEssenceBar(resource)
    if not frame then return; end;

    for i = 1, 6 do
        frame['bar' .. i]:Hide();
        frame['bg' .. i]:Hide();
    end;

    do
        local current = UnitPower("player", resource);
        local max = UnitPowerMax("player", resource);
        local regenRate = GetPowerRegenForPowerType(resource);
        if not current or not core:IsSafePositiveNumber(max) then return; end;

        local gap = 4;
        local barWidth = core.width / max - gap;
        local offset = gap + (gap / max);

        if issecretvalue(regenRate) then
            regenRate = 0.2;
        end;

        if not issecretvalue(current) then
            lastEssence = lastEssence or current;
            if not issecretvalue(lastEssence) then
                local tickDuration = 5 / (5 / (1 / regenRate));
                local now = GetTime();

                if current > lastEssence then
                    if current < max then
                        startTime = now;
                        nextEssenceTick = now + tickDuration;
                    else
                        startTime = nil;
                        nextEssenceTick = nil;
                    end;
                end;

                if current < max and not nextEssenceTick then
                    startTime = now;
                    nextEssenceTick = now + tickDuration;
                end;

                if current >= max then
                    startTime = nil;
                    nextEssenceTick = nil;
                end;
            end;
            lastEssence = current;
        else
            lastEssence = nil;
            startTime = nil;
            nextEssenceTick = nil;
        end;

        local duration;
        if not issecretvalue(current) and nextEssenceTick and startTime then
            duration = C_DurationUtil.CreateDuration();
            duration:SetTimeSpan(startTime, nextEssenceTick);
        end;

        for i = 1, max do
            frame['container' .. i]:ClearAllPoints();
            core:SetPixelSize(frame['container' .. i], barWidth, core.barBgHeight);
            core:SetPixelPoint(frame['container' .. i], "LEFT", frame, "LEFT", (i - 1) * (barWidth + offset), 0);

            frame["bg" .. i]:Show();
            core:SetPixelSize(frame["bg" .. i], barWidth, core.barBgHeight);

            local bar = frame["bar" .. i];
            bar:Show();
            core:SetPixelSize(bar, barWidth - 2 * core.pixel, core.barHeight);

            if issecretvalue(current) then
                bar:SetMinMaxValues(i - 1, i);
                bar:SetValue(current, Enum.StatusBarInterpolation.ExponentialEaseOut);
            else
                bar:SetMinMaxValues(0, 1);
                if i <= current then
                    bar:SetValue(1, Enum.StatusBarInterpolation.ExponentialEaseOut);
                elseif i == current + 1 then
                    bar:SetTimerDuration(duration, Enum.StatusBarInterpolation.ExponentialEaseOut);
                else
                    bar:SetValue(0, Enum.StatusBarInterpolation.ExponentialEaseOut);
                end;
            end;
        end;
    end;
end;

local function updateCountBar(resource)
    if not frame then return; end;

    for i = 1, resourceData.maxCountSegments do
        frame['bar' .. i]:Hide();
        frame['bg' .. i]:Hide();
    end;

    -- combo points belong to the target on classic/forever
    local current = resource == Enum.PowerType.ComboPoints
        and (GetComboPoints("player", "target") or 0)
        or (UnitPower("player", resource) or 0);
    local max = UnitPowerMax("player", resource);
    if not max or max <= 0 then return; end;

    local isRuneResource = resource == Enum.PowerType.Runes;
    local pendingRuneDurations;
    if isRuneResource then
        -- We count runes ourselves, so this value is safe to do math with.
        current = 0;
        pendingRuneDurations = {};
        for i = 1, max do
            local start, dur, ready = GetRuneCooldown(i);
            if ready then
                current = current + 1;
            elseif start and dur and dur > 0 then
                table.insert(pendingRuneDurations, { start = start, duration = dur });
            end;
        end;
        table.sort(pendingRuneDurations, function(a, b)
            return (a.start + a.duration) < (b.start + b.duration);
        end);
    end;

    local gap = 4;
    local barWidth = core.width / max - gap;
    local offset = gap + (gap / max);

    for i = 1, max do
        frame['container' .. i]:ClearAllPoints();
        core:SetPixelSize(frame['container' .. i], barWidth, core.barBgHeight);
        core:SetPixelPoint(frame['container' .. i], "LEFT", frame, "LEFT", (i - 1) * (barWidth + offset), 0);

        frame["bg" .. i]:Show();
        core:SetPixelSize(frame["bg" .. i], barWidth, core.barBgHeight);

        local bar = frame["bar" .. i];
        bar:Show();
        core:SetPixelSize(bar, barWidth - 2 * core.pixel, core.barHeight);

        if isRuneResource and not issecretvalue(current) and pendingRuneDurations[i - current] then
            local pending = pendingRuneDurations[i - current];
            bar:SetMinMaxValues(0, 1);
            local duration = C_DurationUtil.CreateDuration();
            duration:SetTimeSpan(pending.start, pending.start + pending.duration);
            bar:SetTimerDuration(duration, Enum.StatusBarInterpolation.ExponentialEaseOut);
        else
            bar:SetMinMaxValues(i - 1, i);
            bar:SetValue(current, Enum.StatusBarInterpolation.ExponentialEaseOut);
        end;
    end;
end;

local function updateStaggerBar()
    if not frame then return; end;

    local tracker = frame.trackers["STAGGER"];
    if not tracker or not tracker.bar then return; end;

    local stagger = UnitStagger("player") or 0;
    local maxHealth = UnitHealthMax("player");
    if not maxHealth then return; end;

    tracker.bar:SetMinMaxValues(0, maxHealth, Enum.StatusBarInterpolation.ExponentialEaseOut);
    tracker.bar:SetValue(stagger, Enum.StatusBarInterpolation.ExponentialEaseOut);
    if issecretvalue(stagger) or issecretvalue(maxHealth) then return; end;
    if maxHealth <= 0 then return; end;

    local percent = stagger / maxHealth;
    local colors = core.resources.resourceColours["STAGGER"];
    local color;
    if percent >= resourceData.STAGGER.redTransition then
        color = colors.high;
    elseif percent >= resourceData.STAGGER.yellowTransition then
        color = colors.medium;
    else
        color = colors.light;
    end;

    tracker.bar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);
end;

-- Devourer's max fragments depends on talents/pvp talents currently active, unlike Vengeance's fixed 6
local function getDevourerSoulFragmentsMax()
    local soulFragmentsData = resourceData.SOUL_FRAGMENTS;
    local max = soulFragmentsData.baseMax;
    if C_SpellBook.IsSpellKnown(soulFragmentsData.soulGluttonSpellID) then
        max = max - soulFragmentsData.soulGluttonReduction;
    end;
    if C_SpellBook.IsSpellKnown(soulFragmentsData.surrenderToTheVoidSpellID) then
        max = max + soulFragmentsData.surrenderToTheVoidBonus;
    end;
    return max;
end;

local function updateSoulFragmentsBar()
    if not frame then return; end;

    local tracker = frame.trackers["SOUL_FRAGMENTS"];
    if not tracker or not tracker.bar then return; end;

    local current = 0;
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(resourceData.SOUL_FRAGMENTS.spellID);
    if aura then
        current = aura.applications or 0;
    end;

    tracker.bar:SetMinMaxValues(0, getDevourerSoulFragmentsMax());
    tracker.bar:SetValue(current, Enum.StatusBarInterpolation.ExponentialEaseOut);
end;

local function updateBar()
    local resource = getResource();
    if not resource then return; end;

    if resource == Enum.PowerType.Essence then
        updateEssenceBar(resource);
    elseif countResources[resource] then
        updateCountBar(resource);
    elseif resource == "STAGGER" then
        updateStaggerBar();
    elseif resource == "SOUL_FRAGMENTS" then
        updateSoulFragmentsBar();
    end;
end;

local function updateColour()
    if not frame then return; end;

    local resource = getResource();
    if not resource then return; end;

    if resource == Enum.PowerType.Essence then
        local color = core.resources.resourceColours[resource];
        for i = 1, 6 do
            frame['bar' .. i]:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);
        end;
    elseif countResources[resource] then
        local color = core.resources.resourceColours[resource];
        for i = 1, resourceData.maxCountSegments do
            frame['bar' .. i]:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);
        end;
    end;
end;

local function createAuraTracker(spellID, configureButton)
    if not frame then return; end;

    local container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate");
    container:SetPoint("CENTER");
    core:SetPixelSize(container, core.width, core.barBgHeight);
    container:SetUnit("player");

    container:AddAuraSlot("tracked", "HELPFUL", {
        candidateFilters = { includeSpellIDs = { [spellID] = true } },
        initializeFrame = configureButton,
    });

    return container;
end;

local function createTrackerBar(button, colorKey, texture)
    if not frame then return; end;

    texture = texture or "Interface/TargetingFrame/UI-StatusBar";
    core:SetPixelSize(button, core.width - 2 * core.pixel, core.barHeight);
    button:SetPoint("CENTER", frame, "CENTER");

    local bar = CreateFrame("StatusBar", nil, button);
    bar:SetStatusBarTexture(texture);
    bar:SetAllPoints(button);
    bar:SetMinMaxValues(0, 1);
    bar:SetValue(0);

    local color = core.resources.resourceColours[colorKey];
    bar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);

    return bar;
end;

local function buildCountSegments(tracker)
    if not frame then return; end;

    for i = 1, resourceData.maxCountSegments do
        frame['container' .. i] = CreateFrame("Frame", nil, frame);

        frame['bg' .. i] = frame['container' .. i]:CreateTexture();
        local bg = frame['bg' .. i];
        bg:SetPoint("CENTER");
        bg:SetTexture(134532);
        bg:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);
        core:SetPixelSize(bg, 100, core.barBgHeight);
        bg:SetDrawLayer("OVERLAY", -1);

        frame['bar' .. i] = CreateFrame("StatusBar", nil, frame['container' .. i]);
        local bar = frame['bar' .. i];
        bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
        bar:SetPoint("CENTER");
        core:SetPixelSize(bar, 100, core.barHeight);

        bg:Hide();
        bar:Hide();

        table.insert(tracker.visuals, frame['container' .. i]);
    end;
end;

local trackerBuilders = {
    [Enum.PowerType.Essence] = buildCountSegments,
    [Enum.PowerType.Runes] = buildCountSegments,
    [Enum.PowerType.ComboPoints] = buildCountSegments,
    [Enum.PowerType.HolyPower] = buildCountSegments,
    [Enum.PowerType.Chi] = buildCountSegments,
    [Enum.PowerType.SoulShards] = buildCountSegments,

    ["STAGGER"] = function(tracker)
        if not frame then return; end;

        local barFrame = core:CreateSimpleStatusBar(nil, frame, core.width, core.barBgHeight);
        core:SetPixelPoint(barFrame.bg, "CENTER", frame, "CENTER", 0, 0);
        tracker.bar = barFrame.bar;
        table.insert(tracker.visuals, barFrame.bg);
        table.insert(tracker.visuals, barFrame.bar);
    end,

    ["TEACHINGS"] = function(tracker)
        if not frame then return; end;

        local teachingsData = resourceData.TEACHINGS;
        local segmentWidth = (core.width - 2 * core.pixel) / teachingsData.maxStacks;

        for i = 1, teachingsData.maxStacks do
            local bars = frame:CreateTexture(nil, "OVERLAY");
            bars:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);
            core:SetPixelSize(bars, segmentWidth - core.pixel, core.barBgHeight);
            core:SetPixelPoint(bars, "LEFT", frame, "LEFT", (i - 1) * (segmentWidth + core.pixel), 0);
            table.insert(tracker.visuals, bars);
        end;

        tracker.container = createAuraTracker(teachingsData.spellID, function(button)
            local bar = createTrackerBar(button, "TEACHINGS",
                "Interface/Addons/Bars/assets/transparent four segment bar.png");

            button:SetApplicationBar(bar, {
                maxApplications = teachingsData.maxStacks,
                interpolation = Enum.StatusBarInterpolation.ExponentialEaseOut,
            });
        end);
    end,

    ["ECLIPSE"] = function(tracker)
        if not frame then return; end;

        local eclipseData = resourceData.ECLIPSE;
        local segmentWidth = (core.width - 2 * core.pixel) / eclipseData.maxStacks;

        for i = 1, eclipseData.maxStacks do
            local bars = frame:CreateTexture(nil, "OVERLAY");
            bars:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);
            core:SetPixelSize(bars, segmentWidth - core.pixel, core.barBgHeight);
            core:SetPixelPoint(bars, "LEFT", frame, "LEFT", (i - 1) * (segmentWidth + core.pixel), 0);
            table.insert(tracker.visuals, bars);
        end;

        tracker.container = createAuraTracker(eclipseData.spellID, function(button)
            local bar = createTrackerBar(button, "ECLIPSE",
                "Interface/Addons/Bars/assets/transparent four segment bar.png");

            button:SetApplicationBar(bar, {
                maxApplications = eclipseData.maxStacks,
                interpolation = Enum.StatusBarInterpolation.ExponentialEaseOut,
            });
        end);
    end,

    ["ENRAGE"] = function(tracker)
        if not frame then return; end;

        local bg = frame:CreateTexture();
        bg:SetPoint("CENTER");
        bg:SetTexture(134532);
        bg:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);
        core:SetPixelSize(bg, core.width, core.barBgHeight);
        bg:SetDrawLayer("OVERLAY", -1);
        table.insert(tracker.visuals, bg);

        tracker.container = createAuraTracker(resourceData.ENRAGE.spellID, function(button)
            local bar = createTrackerBar(button, "ENRAGE");

            button:SetDurationBar(bar, {
                interpolation = Enum.StatusBarInterpolation.ExponentialEaseOut,
                direction = Enum.StatusBarTimerDirection.RemainingTime,
            });
        end);
    end,

    ["SOUL_FRAGMENTS_VENGEANCE"] = function(tracker)
        if not frame then return; end;

        -- Keep the six segments and five gaps in proportion as the bar resizes.
        local scale = (core.width - 2 * core.pixel) / 410;
        local segmentWidth = 65 * scale;
        local gapWidth = 4 * scale;
        local soulFragmentsData = resourceData.SOUL_FRAGMENTS_VENGEANCE;
        for i = 1, soulFragmentsData.maxStacks do
            local bars = frame:CreateTexture(nil, "OVERLAY");
            bars:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);
            core:SetPixelSize(bars, segmentWidth, core.barBgHeight);
            core:SetPixelPoint(bars, "LEFT", frame, "LEFT", (i - 1) * (segmentWidth + gapWidth), 0);
            table.insert(tracker.visuals, bars);
        end;

        tracker.container = createAuraTracker(soulFragmentsData.spellID, function(button)
            local bar = createTrackerBar(button, "SOUL_FRAGMENTS_VENGEANCE",
                "Interface/Addons/Bars/assets/transparent six segment bar.png");

            button:SetApplicationBar(bar, {
                maxApplications = soulFragmentsData.maxStacks,
                interpolation = Enum.StatusBarInterpolation.ExponentialEaseOut,
            });
        end);
    end,

    ["SOUL_FRAGMENTS"] = function(tracker)
        if not frame then return; end;

        local bg = frame:CreateTexture();
        bg:SetPoint("CENTER");
        bg:SetTexture(134532);
        bg:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);
        core:SetPixelSize(bg, core.width, core.barBgHeight);
        bg:SetDrawLayer("OVERLAY", -1);
        table.insert(tracker.visuals, bg);

        local button = CreateFrame("Frame", nil, frame);
        tracker.bar = createTrackerBar(button, "SOUL_FRAGMENTS");
        table.insert(tracker.visuals, button);
    end,

    ["MAELSTROM_WEAPON"] = function(tracker)
        if not frame then return; end;

        local maelstromWeaponData = resourceData.MAELSTROM_WEAPON;
        local segmentWidth = (core.width - 2 * core.pixel) / maelstromWeaponData.maxStacks;
        for i = 1, maelstromWeaponData.maxStacks do
            local bars = frame:CreateTexture(nil, "OVERLAY");
            bars:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);
            core:SetPixelSize(bars, segmentWidth - core.pixel, core.barBgHeight);
            core:SetPixelPoint(bars, "LEFT", frame, "LEFT", (i - 1) * (segmentWidth + core.pixel), 0);
            table.insert(tracker.visuals, bars);
        end;

        tracker.container = createAuraTracker(maelstromWeaponData.spellID, function(button)
            local bar = createTrackerBar(button, "MAELSTROM_WEAPON");

            button:SetApplicationBar(bar, {
                maxApplications = maelstromWeaponData.maxStacks,
                interpolation = Enum.StatusBarInterpolation.ExponentialEaseOut,
            });
        end);
    end,
};

local function refreshTrackers()
    if not frame then return; end;

    for _, tracker in pairs(frame.trackers) do
        if tracker.container then
            tracker.container:Hide();
        end;
        for _, region in ipairs(tracker.visuals) do
            region:Hide();
        end;
    end;

    local resource = getResource();
    local build = trackerBuilders[resource];
    if not build then return; end;

    local tracker = frame.trackers[resource];
    if not tracker then
        tracker = { visuals = {} };
        frame.trackers[resource] = tracker;
        build(tracker);
    end;

    if tracker.container then
        tracker.container:Show();
    end;
    for _, region in ipairs(tracker.visuals) do
        region:Show();
    end;
end;

function core:CreateSecondaryBar(parent)
    frame = CreateFrame("Frame", "PrimaryResourceContainer", parent);
    core:SetPixelSize(frame, core.width, core.barBgHeight);

    local playerClass = select(2, UnitClass("player"));

    frame.trackers = {};

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player");
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player");
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player");
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED");
    frame:RegisterEvent("PET_BATTLE_OPENING_START");
    frame:RegisterEvent("PET_BATTLE_CLOSE");
    -- talent changes can raise/lower a resource's max (eg. chi charges) without a spec change
    frame:RegisterEvent("PLAYER_TALENT_UPDATE");
    frame:RegisterEvent("TRAIT_CONFIG_UPDATED");
    -- combo points are target-specific, so switching target can change the displayed value
    frame:RegisterEvent("PLAYER_TARGET_CHANGED");

    for _, event in ipairs(classEvents[playerClass] or {}) do
        core:SafeRegisterEvent(frame, event[1], event[2]);
    end;

    local hidden = true;

    function frame:SetHidden(hidden)
    end;

    frame:SetScript("OnEvent", function(_, event, ...)
        local unit = ...;
        if event == "PLAYER_ENTERING_WORLD"
            or event == "UPDATE_SHAPESHIFT_FORM"
            or event == "PLAYER_TALENT_UPDATE"
            or event == "TRAIT_CONFIG_UPDATED"
            or (event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit == "player") then
            refreshTrackers();

            local resource = getResource();
            if resource then
                hidden = false;
                frame:SetHidden(false);
            else
                hidden = true;
                frame:SetHidden(true);
                return;
            end;

            updateColour();
        end;
        if hidden then return; end;

        updateBar();
    end);

    return frame;
end;
